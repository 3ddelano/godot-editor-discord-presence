
class_name DiscordRPCUpdateRichPresencePayload extends DiscordRPCIPCPayload

func _init(presence: DiscordRPCRichPresence) -> void:

	op_code = DiscordRPCIPCUtil.OpCodes.FRAME
	command = DiscordRPCIPCUtil.Commands.SET_ACTIVITY
	arguments = {
		"pid": OS.get_process_id(),
		# warning-ignore:incompatible_ternary
		"activity": presence.to_dict() if presence else null
	}
