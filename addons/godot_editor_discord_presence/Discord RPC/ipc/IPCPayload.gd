class_name DiscordRPCIPCPayload

var op_code: int = 3
var nonce: String
var command: String
var event: String
var data: Dictionary
var arguments: Dictionary

func _init() -> void:
	generate_nonce()

func generate_nonce() -> void:
	nonce = DiscordRPCUUID.v4()

func is_error() -> bool:
	return event == "ERROR"

func get_error_code() -> int:
	var code: int
	if (is_error()):
		code = data["code"]
	return code

func get_error_messsage() -> String:
	var message: String
	if (is_error()):
		message = data["message"]
	return message

func to_dict() -> Dictionary:
	return {
		"nonce": nonce,
		"cmd": command,
		"evt": event if not event.empty() else null,
		"data": data,
		"args": arguments
	}

func to_bytes() -> PoolByteArray:
	var buffer: PoolByteArray = to_json(to_dict()).to_utf8()
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.put_32(op_code)
	stream.put_32(buffer.size())
	stream.put_data(buffer)
	return stream.data_array

func _to_string() -> String:
	return to_json(to_dict())
