extends Node

signal rpc_ready(user)
signal activity_join(secret)
signal raw_data(data)
signal rpc_closed()

enum {
	DISCONNECTED,
	CONNECTIING,
	CONNECTED,
	DISCONNECTING
}

const VERSION: int = 1
const DISCORD_API_ENDPOINT: String = "https://discord.com/api/%s"

var _ipc: DiscordRPCIPC setget __set
var _modules: Dictionary setget __set

var status: int = DISCONNECTED setget __set
var client_id: int setget __set
var scopes: PoolStringArray setget __set, get_scopes

# warning-ignore:shadowed_variable
func _init() -> void:
	_ipc = DiscordRPCIPC.new()
	_ipc.connect("data_recieved", self, "_on_data")
	install_module(DiscordRPCRichPresenceModule.new())
	set_process(false)

func establish_connection(_client_id: int) -> void:
	client_id = _client_id
	if (is_connected_to_client()):
		push_error("This DiscordIPC instance is already in an active connection")
		return

	if (not is_supported()):
		push_error("IPC error: Unsuported platform")
		return

	status = CONNECTIING
	for i in range(10):
		var path = DiscordRPCIPC.get_pipe_path(i)
		if (_ipc.open(path) == OK):
			_ipc.setup()
			_handshake()
			set_process(true)
			return
	push_error("Discord client not found")
	shutdown()

func is_connected_to_client() -> bool:
	return _ipc.is_open() and status != DISCONNECTED

func authorize(_scopes: PoolStringArray, secret: String) -> void:
	var request: DiscordRPCIPCPayload = DiscordRPCIPCUtil.AuthorizePayload.new(client_id, _scopes)
	var response: DiscordRPCIPCPayload = yield(_ipc.send(request), "completed")
	if (not response.is_error()):
		var code: String = response.data["code"]
		var auth_token: String = yield(get_auth_token(code, secret), "completed")
		if (not auth_token.empty()):
			emit_signal("authorized", auth_token)

# warning-ignore:unused_argument
func authenticate(access_token: String) -> void:
	var request: DiscordRPCIPCPayload = DiscordRPCIPCUtil.AuthenticatePayload.new(access_token)
	var response: DiscordRPCIPCPayload = yield(_ipc.send(request), "completed")
	if (not response.is_error()):
		scopes = response.data["scopes"]
		emit_signal("authenticated", response.data["expires"])

func get_auth_token(authorize_code: String, secret: String, redirect_url: String = "http://127.0.0.1") -> String:
	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.use_threads = OS.can_use_threads()
	var url: String = DISCORD_API_ENDPOINT % "oauth2/token"
	var headers: PoolStringArray = ["Content-Type: application/x-www-form-urlencoded"]
	var data: Dictionary = {
		"client_id": client_id,
		"client_secret": secret,
		"grant_type": 'authorization_code',
		"code": authorize_code,
		"redirect_uri": redirect_url
	}

	add_child(http_request)
	http_request.request(
		url,
		headers,
		true,
		HTTPClient.METHOD_POST,
		DiscordRPCURLUtil.dict_to_url_encoded(data)
	)
	var response: Array = yield(http_request, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var body: PoolByteArray = response[3]

	return parse_json(body.get_string_from_utf8()).get("access_token", "")

func subscribe(event: String, arguments: Dictionary = {}) -> void:
	_ipc.send(DiscordRPCIPCUtil.SubscribePayload.new(event, arguments))

func unsubscribe(event: String, arguments: Dictionary = {}) -> void:
	_ipc.send(DiscordRPCIPCUtil.UnsubscribePayload.new(event, arguments))

func shutdown() -> void:
	status = DISCONNECTING
	_ipc.close()
	status = DISCONNECTED
	set_process(false)
	emit_signal("rpc_closed")

func install_module(module: DiscordRPCIPCModule) -> void:
	if (not _modules.has(module.name)):
		module.initilize(_ipc)
		_modules[module.name] = module

func get_module(name: String) -> DiscordRPCIPCModule:
	return _modules.get(name)

func uninstall_module(name: String) -> void:
	# warning-ignore:return_value_discarded
	_modules.erase(name)

func ipc_call(function: String, arguments: Array = []):
	for module in _modules.values():
		if (function in module.get_functions()):
			return module.callv(function, arguments)
	printerr("Calling non-existant function \"%s\" via ipc_call" % function)
	return null

func get_scopes() -> PoolStringArray:
	return Array(scopes).duplicate() as PoolStringArray


func _handshake() -> void:
	if (status == CONNECTED):
		push_error("Already handshaked !")
		return
	var request: DiscordRPCIPCPayload = DiscordRPCIPCUtil.HandshakePayload.new(VERSION, client_id)
	var response: DiscordRPCIPCPayload = yield(_ipc.send(request), "completed")
	if (not response.is_error()):
		status = CONNECTED
		emit_signal("rpc_ready", response.data["user"])

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			shutdown()

func _process(_delta: float) -> void:
	if _ipc:
		_ipc.poll()

func _on_data(payload: DiscordRPCIPCPayload) -> void:
	if (payload.is_error()):
		push_error("IPC: Recieved error code: %d: %s" % [payload.get_error_code(), payload.get_error_messsage()])

	if (payload.op_code == DiscordRPCIPCUtil.OpCodes.CLOSE):
		shutdown()
		return

	emit_signal("raw_data", payload)

	var signal_name = payload.event.to_lower()
	if (payload.command == "DISPATCH" and has_signal(signal_name)):
		callv("emit_signal", [signal_name] + payload.data.values())

func _to_string() -> String:
	return "[DiscordRPC:%d]" % get_instance_id()

func __set(_value) -> void:
	pass

static func is_supported() -> bool:
	return not DiscordRPCIPC.get_pip() == null
