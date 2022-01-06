class_name DiscordRPCIPC

signal data_recieved(payload)

var _pipe: DiscordRPCNamedPipe
var _responses_pool: Array
var _requests_pool: Array

var _io_thread: Thread
var thread_terminated: bool = false
var _mutex: Mutex

func open(path: String) -> int:
	_pipe = get_pip()
	if (_pipe):
		return _pipe.open(path)
	return ERR_CANT_OPEN

func setup() -> bool:
	_io_thread = Thread.new()
	_mutex = Mutex.new()
	var error: int = _io_thread.start(self, "_connection_loop", [_mutex, _pipe])
	if (error != OK):
		push_error("Failed to start IO Thread !")
		return false
	return true

func send(request: DiscordRPCIPCPayload) -> DiscordRPCIPCPayload:
	var op_code: int = request.op_code
	var nonce: String = request.nonce

	_requests_pool.append(request)

	var response: DiscordRPCIPCPayload = null

	while (not response):
		var payload: DiscordRPCIPCPayload = yield(self, "data_recieved")
		if (op_code == DiscordRPCIPCUtil.OpCodes.HANDSHAKE):
			response = payload
		elif (payload.nonce == nonce):
			response = payload

	return response

func post(request: DiscordRPCIPCPayload) -> void:
	if (not is_open()):
		push_error("IPC: Can not send payloads while not connected to a discord client instance")
		return

	_pipe.write(request.to_bytes())

func scan() -> DiscordRPCIPCPayload:
	if (not is_open()):
		push_error("IPC: Can not recieve payloads while not connected to a discord client instance")
		return null

	var data: Array = _pipe.read()
	var op_code: int = data[0]
	var buffer: PoolByteArray =  data[1]
	var parse_result: JSONParseResult = JSON.parse(buffer.get_string_from_utf8())
	if (parse_result.error != OK):
		push_error("Failed decoding packet of legnth: %d with opcode: %d" % [buffer.size(), op_code])
		return null

	var body: Dictionary = parse_result.result

	var response: DiscordRPCIPCPayload = DiscordRPCIPCPayload.new()
	response.op_code = op_code
	response.nonce = body["nonce"] if body.get("nonce") else ""
	response.command = body["cmd"] if body.get("cmd") else ""
	response.event = body["evt"] if body.get("evt") else ""
	response.data = body["data"] if body.has("data") else {}
	response.arguments = body["args"] if body.has("args") else {}

	return response

func is_open() -> bool:
	return _pipe.is_open() if _pipe else false

func close() -> void:
	_pipe.close()
	if (_io_thread and _io_thread.is_active()):
		_io_thread.wait_to_finish()

func poll() -> void:
	while (_responses_pool.size() > 0):
		_mutex.lock()
		emit_signal("data_recieved", _responses_pool.pop_back())
		_mutex.unlock()

func _connection_loop(data: Array) -> void:
	var mutex: Mutex = data[0]
	var pipe: DiscordRPCNamedPipe = data[1]

	while (pipe.is_open()):
		if (pipe.has_reading()):
			var payload: DiscordRPCIPCPayload = scan()
			mutex.lock()
			_responses_pool.append(payload)
			mutex.unlock()

		elif (_requests_pool.size() > 0):
			mutex.lock()
			post(_requests_pool.pop_back())
			mutex.unlock()

		OS.delay_msec(10)

static func get_pip() -> DiscordRPCNamedPipe:
	var pipe: DiscordRPCNamedPipe
	var os: String = OS.get_name()
	if (os == "Windows"):
		pipe = DiscordRPCWindowsPipe.new()

	elif (os in ["X11", "OSX"]):
		# Unimplemented yet
		pass

	return pipe

static func get_pipe_path(i: int) -> String:
	var path: String
	match OS.get_name():
		"Windows":
			path = "\\\\?\\pipe\\"
		_:
			for env_var in ["XDG_RUNTIME_DIR","TMPDIR","TMP","TEMP"]:
				if (OS.has_environment(env_var)):
					path = OS.get_environment(env_var) + "/"
					break
			if (path.empty()):
				path = "/tmp/"

	return path + "discord-ipc-%d" % i
