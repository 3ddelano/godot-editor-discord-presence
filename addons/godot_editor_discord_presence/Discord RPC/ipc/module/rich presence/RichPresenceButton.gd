class_name DiscordRPCRichPresenceButton

var label: String
var url: String

func _init(_label: String, _url: String) -> void:
	label = _label
	url = _url

func to_dict() -> Dictionary:
	return {
		"label": label,
		"url": url
	}
