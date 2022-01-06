class_name DiscordRPCRichPresence

var state: String
var details: String
var start_timestamp: int
var end_timestamp: int
var large_image_key: String
var large_image_text: String
var small_image_key: String
var small_image_text: String
var party_id: String
var party_size: int setget set_party_size
var party_max: int setget set_party_max
var match_secret: String
var join_secret: String
var spectate_secret: String
var first_button: DiscordRPCRichPresenceButton
var second_button: DiscordRPCRichPresenceButton
var instance: bool = true

func set_party_size(size: int) -> void:
	party_size = clamp(size, 0, party_max)

func set_party_max(value: int) -> void:
	# Ensure that the party size is always in the correct range
	party_max = max(0, value)

func to_dict() -> Dictionary:
	var data: Dictionary = {"instance": instance}

	if (not state.empty()):
		data["state"] = state
	if (not details.empty()):
		data["details"] = details

	var timestamps: Dictionary = {}
	if (start_timestamp > 0):
		timestamps["start"] = start_timestamp
	if (end_timestamp > 0):
		timestamps["end"] = end_timestamp
	if (not timestamps.empty()):
		data["timestamps"] = timestamps

	var assets: Dictionary = {}
	if (not large_image_key.empty()):
		assets["large_image"] = large_image_key
	if (not large_image_text.empty()):
		assets["large_text"] = large_image_text
	if (not small_image_key.empty()):
		assets["small_image"] = small_image_key
	if (not small_image_text.empty()):
		assets["small_text"] = small_image_text
	if (not assets.empty()):
		data["assets"] = assets

	var secrets: Dictionary = {}
	if (not join_secret.empty()):
		secrets["join"] = join_secret
	if (not spectate_secret.empty()):
		secrets["spectate"] = spectate_secret
	if (not match_secret.empty()):
		secrets["instanced_match"] = match_secret
	if (not secrets.empty()):
		data["secrets"] = secrets

	var party: Dictionary = {}
	if (not party_id.empty()):
		party["id"] = party_id
	if (party_max > 0):
		party["size"] = [party_size, party_max]
	if not party.empty():
		data["party"] = party

	var buttons: Array = []
	if (first_button):
		buttons.append(first_button.to_dict())
	if (second_button):
		buttons.append(second_button.to_dict())
	if (not buttons.empty()):
		data["buttons"] = buttons

	return data
