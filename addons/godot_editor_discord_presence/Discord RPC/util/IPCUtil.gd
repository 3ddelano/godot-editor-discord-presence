class_name DiscordRPCIPCUtil

enum OpCodes {
	HANDSHAKE,
	FRAME,
	CLOSE,
	PING,
	PONG
}

const Commands: Dictionary = {
	DISPATCH = "DISPATCH",
	AUTHORIZE = "AUTHORIZE",
	AUTHENTICATE = "AUTHENTICATE",
	GET_GUILD = "GET_GUILD",
	GET_GUILDS = "GET_GUILDS",
	GET_CHANNEL = "GET_CHANNEL",
	GET_CHANNELS = "GET_CHANNELS",
	SUBSCRIBE = "SUBSCRIBE",
	UNSUBSCRIBE = "UNSUBSCRIBE",
	SET_USER_VOICE_SETTINGS  = "SET_USER_VOICE_SETTINGS",
	SELECT_VOICE_CHANNEL = "SELECT_VOICE_CHANNEL",
	GET_SELECTED_VOICE_CHANNEL = "GET_SELECTED_VOICE_CHANNEL",
	SELECT_TEXT_CHANNEL = "SELECT_TEXT_CHANNEL",
	GET_VOICE_SETTINGS = "GET_VOICE_SETTINGS",
	SET_VOICE_SETTINGS = "SET_VOICE_SETTINGS",
	CAPTURE_SHORTCUT = "CAPTURE_SHORTCUT",
	SET_CERTIFIED_DEVICES = "SET_CERTIFIED_DEVICES",
	SET_ACTIVITY = "SET_ACTIVITY",
	SEND_ACTIVITY_JOIN_INVITE = "SEND_ACTIVITY_JOIN_INVITE",
	CLOSE_ACTIVITY_REQUEST = "CLOSE_ACTIVITY_REQUEST"
}

class HandshakePayload extends DiscordRPCIPCPayload:
	var version: int
	var client_id: int

	# warning-ignore:shadowed_variable
	# warning-ignore:shadowed_variable
	func _init(_version: int, _client_id: int) -> void:
		op_code = OpCodes.HANDSHAKE
		version = _version
		client_id = _client_id

	func to_dict() -> Dictionary:
		return {
			"v": version,
			"client_id": str(client_id),
		}

class AuthorizePayload extends DiscordRPCIPCPayload:
	func _init(client_id: int, scopes: PoolStringArray) -> void:
		op_code = OpCodes.FRAME
		command = Commands.AUTHORIZE
		arguments = {
			"client_id": str(client_id),
			"scopes": scopes
		}

class AuthenticatePayload extends DiscordRPCIPCPayload:
	func _init(access_token: String) -> void:
		op_code = OpCodes.FRAME
		command = Commands.AUTHENTICATE
		arguments = {"access_token": access_token}

class SubscribePayload extends DiscordRPCIPCPayload:
	func _init(subscribe_event: String, arg: Dictionary) -> void:
		op_code = OpCodes.FRAME
		command = Commands.SUBSCRIBE
		arguments = arg
		event = subscribe_event.to_upper()

class UnsubscribePayload extends DiscordRPCIPCPayload:
	func _init(usubscribe_event: String, arg: Dictionary) -> void:
		op_code = OpCodes.FRAME
		command = Commands.UNSUBSCRIBE
		arguments = arg
		event = usubscribe_event.to_upper()
