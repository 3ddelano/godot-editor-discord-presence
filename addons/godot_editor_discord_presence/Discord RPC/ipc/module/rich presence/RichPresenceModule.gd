class_name DiscordRPCRichPresenceModule extends DiscordRPCIPCModule


func _init().("RichPresence") -> void:
	pass

func get_functions() -> PoolStringArray:
	return PoolStringArray(["update_presence"])

func update_presence(presence: DiscordRPCRichPresence) -> void:
	var request: DiscordRPCIPCPayload = DiscordRPCUpdateRichPresencePayload.new(presence)
	_ipc.send(request)
