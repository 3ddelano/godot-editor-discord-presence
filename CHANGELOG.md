Changelog
============

This is a high-level changelog for each released versions of the plugin.
For a more detailed list of past changes, see the commit history.

1.2.5
------
- Fixed a bug that caused error message to print when you switch to a main screen editor other than 2D, 3D, Script or AssetLib
- Changed the large_image_text for 2D and 3D editors to be the same as the large_image_text for the main screen editor
- (Godot Unix Socket) Replaced x86 `libunixsocket.dylib` with universal dylib to support M1

1.2.4
------
- Added toggle to change between updating timestamp at the start vs whenever screen changes. (`discord_presence/settings/change_time_per_screen`)

1.2.3
------
- Fixed a bug that only showed the script as presence instead of showing the current editor

1.2.2
------
- Removed slash in path for custom ProjectSetting
- Reverted to old DiscordRPC to fix freezing when Godot editor is closed

1.2.1
------
- Removed old DiscordRPC v.1.0.0

1.2.0
------
- Updateed DiscordRPC to v1.1.0 and godot-unix-socket to v1.1.0, this fixes a bug where Godot crashes if Discord is closed when connected via DiscordRPC

1.1.0
------
- Added auto-reconnect to Discord client
- Added Linux / OSx support

1.0.0
------
- Initial version