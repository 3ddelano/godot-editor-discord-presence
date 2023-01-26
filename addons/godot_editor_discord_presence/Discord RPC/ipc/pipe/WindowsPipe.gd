extends "./IPCPipe.gd"

var _file: FileAccess

func open(path: String) -> int:
	self._file = FileAccess.open(path, FileAccess.READ_WRITE)
	return self._file.get_open_error()

func read() -> Array:
	if not is_open():
		return [-1, PackedByteArray()]
	
	var op_code: int = self._file.get_32()
	var length: int = self._file.get_32()
	var buffer: PackedByteArray = self._file.get_buffer(length)
	
	return [op_code, buffer]

func write(bytes: PackedByteArray) -> void:
	if is_open():
		_file.store_buffer(bytes)

func is_open() -> bool:
	return _file and _file.is_open()

func has_reading() -> bool:
	return _file.get_length() > 0 if _file else false

func close() -> void:
	_file = null

func _to_string() -> String:
	return "[WindowsPipe:%d]" % self.get_instance_id()
