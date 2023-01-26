class_name RichPresenceModule extends "../IPCModule.gd"

const IPCPayload: Script = preload("../../IPCPayload.gd")
const UpdateRichPresencePayload: Script = preload("./UpdateRichPresencePayload.gd")

func _init() -> void:
	super("RichPresence")

func get_functions() -> PackedStringArray:
	return PackedStringArray(["update_presence"])

func update_presence(presence: RichPresence) -> void:
	var request: IPCPayload = UpdateRichPresencePayload.new(presence)
	self._ipc.send(request)
