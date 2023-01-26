const IPC: Script = preload("../IPC.gd")

var _ipc: IPC

var name: String

func _init(_name: String) -> void:
	self.name = _name

func initilize(ipc: IPC) -> void:
	self._ipc = ipc

func get_functions() -> PackedStringArray:
	return PackedStringArray()

func requires_authorize() -> bool:
	return false
