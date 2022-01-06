class_name DiscordRPCWindowsPipe extends DiscordRPCNamedPipe

var _file: File

func _init() -> void:
	_file = File.new()

func open(path: String) -> int:
	return _file.open(path, File.READ_WRITE)

func read() -> Array:
	var op_code: int = _file.get_32()
	var length: int = _file.get_32()
	var buffer = _file.get_buffer(length)
	return [op_code, buffer]

func write(bytes: PoolByteArray) -> void:
	_file.store_buffer(bytes)

func is_open() -> bool:
	return _file.is_open()

func has_reading() -> bool:
	return not _file.get_len() == 0

func close() -> void:
	_file.close()

func _to_string() -> String:
	return "[WindowsIPCPipe:%d]" % get_instance_id()
