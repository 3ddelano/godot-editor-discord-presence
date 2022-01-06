class_name DiscordRPCIPCModule

var _ipc: DiscordRPCIPC

var name: String

func _init(_name: String) -> void:
	name = _name

func initilize(ipc: DiscordRPCIPC) -> void:
	_ipc = ipc

func get_functions() -> PoolStringArray:
	return PoolStringArray()

func requires_authorize() -> bool:
	return false
