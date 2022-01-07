tool
extends NativeScript

const LIBRARY: GDNativeLibrary = preload("unix-socket.gdnlib")
const SUPPORTED_PLATFORMS := PoolStringArray([
	"OSX",
	"Server",
	"X11"
])

func _init() -> void:
	if OS.get_name() in SUPPORTED_PLATFORMS:
		library = LIBRARY

