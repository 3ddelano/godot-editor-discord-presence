# Godot Editor Discord Presence Plugin
# Author: (3ddelano) Delano Lourenco
# For license: See LICENSE.md

tool
extends EditorPlugin
const DEBUG = false

const DiscordRPC = preload("Discord RPC/DiscordRPC.gd")

const _2D = "2D"
const _3D = "3D"
const SCRIPT = "Script"
const ASSETLIB = "AssetLib"

const GDSCRIPT = "GDScript"
const VISUALSCRIPT = "VisualScript"
const NATIVESCRIPT = "NativeScript"
const CSHARPSCRIPT = "C# Script"

const FIRST_BUTTON_PATH = "/discord_presence/first_button"
const SECOND_BUTTON_PATH = "/discord_presence/second_button"

var _current_script_name: String
var _current_scene_name: String
var _current_editor_name: String
var _previous_script_name: String
var _previous_scene_name: String
var _previous_editor_name: String
var _previous_details: String

var application_id: int = 928212232213520454
var rpc: DiscordRPC = null
var presence: DiscordRPCRichPresence

const ASSETNAMES = {
	_2D: "2d",
	_3D: "3d",
	SCRIPT: "script",
	ASSETLIB: "assetlib",
	"LOGO_LARGE": "logo_vertical_color",
	"LOGO_SMALL": "icon_color",
}

func debug_print(string: String):
	if DEBUG:
		print(string)


func _enter_tree() -> void:
	connect("main_screen_changed", self, "_on_main_scene_changed")
	connect("scene_changed", self, "_on_scene_changed")
	get_editor_interface().get_script_editor().connect("editor_script_changed", self, "_on_editor_script_changed")

	_init_presence()
	if not rpc:
		_init_discord_rpc()

	_add_custom_settings()


func _exit_tree() -> void:
	disconnect("main_screen_changed", self, "_on_main_scene_changed")
	disconnect("scene_changed", self, "_on_scene_changed")
	get_editor_interface().get_script_editor().disconnect("editor_script_changed", self, "_on_editor_script_changed")

	if rpc and is_instance_valid(rpc):
		_destroy_discord_rpc()

	if presence:
		presence = null


func disable_plugin() -> void:
	if rpc and is_instance_valid(rpc):
		_destroy_discord_rpc()

	if presence:
		presence = null


func _init_discord_rpc() -> void:
	debug_print("Initializing DiscordRPC")
	rpc = DiscordRPC.new()
	add_child(rpc)
	rpc.connect("rpc_ready", self, "_on_rpc_ready")
	rpc.establish_connection(application_id)


func _destroy_discord_rpc() -> void:
	if rpc and is_instance_valid(rpc):
		rpc.shutdown()
		rpc.queue_free()


func _on_rpc_ready(user: Dictionary):
	debug_print("Connected to DiscordRPC")
	_init_presence(true)


func _init_presence(forced := false) -> void:
	if presence != null:
		if not forced:
			return

	presence = DiscordRPCRichPresence.new()

	# Initial Presence Details
	presence.details = "In Godot Editor"
	presence.state = "Project: %s" % ProjectSettings.get_setting("application/config/name")
	presence.start_timestamp = OS.get_unix_time()
	presence.large_image_key = ASSETNAMES.LOGO_LARGE
	presence.large_image_text = "Working on a Godot project"

	if ProjectSettings.has_setting(FIRST_BUTTON_PATH + "/label") and ProjectSettings.has_setting(FIRST_BUTTON_PATH + "/url"):
		var label = ProjectSettings.get_setting(FIRST_BUTTON_PATH + "/label")
		var url = ProjectSettings.get_setting(FIRST_BUTTON_PATH + "/url")
		if label != "" and url != "":
			presence.first_button = DiscordRPCRichPresenceButton.new(label, url)

	if ProjectSettings.has_setting(SECOND_BUTTON_PATH + "/label") and ProjectSettings.has_setting(SECOND_BUTTON_PATH + "/url"):
		var label = ProjectSettings.get_setting(SECOND_BUTTON_PATH + "/label")
		var url = ProjectSettings.get_setting(SECOND_BUTTON_PATH + "/url")
		if label != "" and url != "":
			presence.second_button = DiscordRPCRichPresenceButton.new(label, url)

	if is_instance_valid(rpc):
		rpc.get_module("RichPresence").update_presence(presence)


func _on_editor_script_changed(script: Script) -> void:
	if script:
		_current_editor_name = SCRIPT
		_current_script_name = script.get_path().get_file()
		debug_print("Editor script changed: " + _current_script_name)
		_update()


func _on_main_scene_changed(screen_name: String) -> void:
	_current_editor_name = screen_name
	debug_print("Main scene changed: " + _current_editor_name)

	var script = get_editor_interface().get_script_editor().get_current_script()
	if script != null:
		_current_script_name = script.get_path().get_file()

	if _current_scene_name == null:
		var open_scenes = get_editor_interface().get_open_scenes()
		if open_scenes.size() == 1:
			_current_scene_name = open_scenes[0].get_file()

	_update()


func _on_scene_changed(screen_root: Node) -> void:
	if is_instance_valid(screen_root):
		_current_scene_name = screen_root.filename.get_file()
		debug_print("Scene changed: " + _current_scene_name)
		_update()


func _update() -> void:
	var just_started = false
	var should_update = false

	if _current_editor_name in [_2D, _3D]:
		# Get the name of the currently opened scene
		var scene = get_editor_interface().get_edited_scene_root()
		if scene:
			_current_scene_name = scene.filename.get_file()

	_init_presence()
	presence.small_image_key = ASSETNAMES.LOGO_SMALL
	presence.small_image_text = "Godot Engine"
	presence.large_image_key = ASSETNAMES[_current_editor_name]

	match _current_editor_name:
		_2D:
			presence.details = "Editing %s" % _current_scene_name
			presence.large_image_text = "Editing scene in 2D"
			if _current_scene_name != _previous_scene_name:
				just_started = true

		_3D:
			presence.details = "Editing %s" % _current_scene_name
			if _current_scene_name != _previous_scene_name:
				just_started = true
			presence.large_image_text = "Editing scene in 3D"

		SCRIPT:
			var script_type = SCRIPT
			presence.details = "Editing %s" % _current_script_name
			if _current_script_name != _previous_script_name:
				# Script was changed
				just_started = true

				var extension = _current_script_name.get_extension().to_lower()
				# Find the type of the script based on the extension
				match extension:
					"gd":
						script_type = GDSCRIPT
						presence.large_image_key = "gdscript"
					"vs":
						script_type = VISUALSCRIPT
						presence.large_image_key = "visualscript"
					"gdns":
						script_type = NATIVESCRIPT
						presence.large_image_key = "nativescript"
					"cs":
						script_type = CSHARPSCRIPT
						presence.large_image_key = "csharpscript"

			if script_type == SCRIPT:
				# Some other type of script file
				presence.large_image_key = "script"

			presence.large_image_text = "Editing a " + script_type + " file"

		ASSETLIB:
			presence.details = "Browsing Asset Libary"
			presence.large_image_text = "Browsing the Asset Library"
			just_started = true



	if just_started:
		presence.start_timestamp = OS.get_unix_time()
		should_update = true

	if presence.details != _previous_details:
		should_update = true

	if should_update and is_instance_valid(rpc):
		rpc.get_module("RichPresence").update_presence(presence)

	_previous_editor_name = _current_editor_name
	_previous_scene_name = _current_scene_name
	_previous_script_name = _current_script_name
	_previous_details = presence.details


func _add_custom_settings():
	_add_custom_project_setting(FIRST_BUTTON_PATH + "/label", "Godot Engine", TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "The label for the First Button of Discord Status")
	_add_custom_project_setting(FIRST_BUTTON_PATH + "/url", "https://godotengine.org", TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "The URL for the First Button of Discord Status")

	_add_custom_project_setting(SECOND_BUTTON_PATH + "/label", "", TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "The label for the Second Button of Discord Status")
	_add_custom_project_setting(SECOND_BUTTON_PATH + "/url", "", TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "The URL for the Second Button of Discord Status")

	var error: int = ProjectSettings.save()
	if error: push_error("Encountered error %d when trying to add custom button settings to ProjectSettings." % error)


func _add_custom_project_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	if ProjectSettings.has_setting(name): return

	var setting_info: Dictionary = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}

	ProjectSettings.set_setting(name, default_value)
	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(name, default_value)


func _remove_custom_settings():
	_remove_custom_project_setting(FIRST_BUTTON_PATH + "/label")
	_remove_custom_project_setting(FIRST_BUTTON_PATH + "/url")
	_remove_custom_project_setting(SECOND_BUTTON_PATH + "/label")
	_remove_custom_project_setting(SECOND_BUTTON_PATH + "/url")
	var error: int = ProjectSettings.save()
	if error: push_error("Encountered error %d when trying to remove custom button settings from ProjectSettings." % error)


func _remove_custom_project_setting(name: String) -> void:
	if !ProjectSettings.has_setting(name): return
	ProjectSettings.set_setting(name, null)
