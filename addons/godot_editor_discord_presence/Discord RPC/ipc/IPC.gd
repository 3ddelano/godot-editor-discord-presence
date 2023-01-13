tool

# warning-ignore-all:return_value_discarded

signal data_recieved(payload)

const IPCPayload: Script = preload("./IPCPayload.gd")
const IPCPipe: Script = preload("./pipe/IPCPipe.gd")
const UnixPipe: Script = preload("./pipe/UnixPipe.gd")
const WindowsPipe: Script = preload("./pipe/WindowsPipe.gd")

var _pipe: IPCPipe

func open(path: String) -> int:
	_pipe = get_pipe()
	if _pipe:
		return _pipe.open(path)
	return ERR_CANT_OPEN

func send(request: IPCPayload) -> IPCPayload:
	if not is_open():
		push_error("IPC: Can not send payloads while not connected to a discord client instance")
		return yield()
	
	var op_code: int = request.op_code
	var nonce: String = request.nonce
	
	post(request)
	
	var response: IPCPayload = null
	while not response:
		var payload: IPCPayload = yield(self, "data_recieved")
		if op_code == IPCPayload.OpCodes.HANDSHAKE:
			response = payload 
		elif payload.nonce == nonce:
			response = payload
	return response

func post(request: IPCPayload) -> void:
	if not is_open():
		push_error("IPC: Can not post payloads while not connected to a discord client instance")
		return
	
	_pipe.write(request.to_bytes())

func scan() -> IPCPayload:
	if not is_open():
		push_error("IPC: Can not recieve payloads while not connected to a discord client instance")
		return null
	
	var data: Array = self._pipe.read()
	var op_code: int = data[0]
	var buffer: PoolByteArray =  data[1]
	
	var parse_result: JSONParseResult = JSON.parse(buffer.get_string_from_utf8())
	if parse_result.error != OK:
		push_error("Failed decoding packet of legnth: %d with opcode: %d" % [buffer.size(), op_code])
		return null
	var body: Dictionary = parse_result.result
	
	var response: IPCPayload = IPCPayload.new()
	response.op_code = op_code
	response.nonce = body["nonce"] if body.get("nonce") else ""
	response.command = body["cmd"] if body.get("cmd") else ""
	response.event = body["evt"] if body.get("evt") else ""
	response.data = body["data"] if body.get("data") is Dictionary else {}
	response.arguments = body["args"] if body.get("args") is Dictionary else {}

	return response

func is_open() -> bool:
	return _pipe and _pipe.is_open()

func close() -> void:
	if _pipe:
		_pipe.close()
	_pipe = null

func poll() -> void:
	if not is_open():
		return
	
	while _pipe.has_reading():
		var payload: IPCPayload = scan()
		emit_signal("data_recieved", payload)
		if payload.op_code == IPCPayload.OpCodes.CLOSE:
			_pipe.close()
			break

static func get_pipe() -> IPCPipe:
	var pipe: IPCPipe
	match OS.get_name():
		"Windows":
			pipe = WindowsPipe.new()
		"Server", "X11", "OSX":
			pipe = UnixPipe.new()
	return pipe

static func get_pipe_path(index: int) -> String:
	var path: String
	match OS.get_name():
		"Windows":
			path = "\\\\?\\pipe\\"
		"Server", "X11", "OSX":
			for env_var in ["XDG_RUNTIME_DIR","TMPDIR","TMP","TEMP"]:
				if (OS.has_environment(env_var)):
					path = OS.get_environment(env_var) + "/"
					break
			if path.empty():
				path = "/tmp/"
		_:
			return ""
			
	return path + "discord-ipc-%d" % index
