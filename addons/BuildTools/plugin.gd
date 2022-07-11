tool
extends EditorPlugin

var exportPlugin :EditorExportPlugin
var window :PanelContainer

const WINDOW_SCENE = preload("Test.tscn")

const SERVER_FEATURE = "Server"
const MENU_ITEM = "Build Tools"

const PRINT_VERSION_MENU_ITEM = "Print Version"
const UPDATE_EXPORT_PRESETS_MENU_ITEM = "Update Export Presets"
const INCREMENT_BUILD_NUMBER_MENU_ITEM = "Increment Build Number"


func _enter_tree():
	if OS.has_feature(SERVER_FEATURE):
		return
	exportPlugin = preload("BuildTools.gd").new()
	# When this plugin node enters tree, add the custom type
	add_export_plugin(exportPlugin)
	_setup_menu_entries()


func _exit_tree():
	if OS.has_feature(SERVER_FEATURE):
		return
	# When the plugin node exits the tree, remove the custom type
	remove_export_plugin(exportPlugin)
	exportPlugin = null


func _setup_menu_entries():
	add_tool_menu_item(PRINT_VERSION_MENU_ITEM, self, "_print_version")
	add_tool_menu_item(UPDATE_EXPORT_PRESETS_MENU_ITEM, self, "_update_export_config")
	add_tool_menu_item(INCREMENT_BUILD_NUMBER_MENU_ITEM, self, "_increment_build_number")
	#add_tool_submenu_item(PRINT_VERSION_MENU_ITEM, )
	
	
func _remove_menu_entries():
	remove_tool_menu_item(PRINT_VERSION_MENU_ITEM)
	
	
func _print_version(_ud):
	exportPlugin.print_version_string()
	#make_bottom_panel_item_visible(null)
	
	
func _update_export_config(_ud):
	exportPlugin._update_export_config()
	
	
func _increment_build_number(_ud):
	exportPlugin.increment_current_build_number()
	
	
# --- NOTE: WIP, not used ---
# For making a custom display in the bottom panel
func _open_bottom_panel_window(_ud):
	if window:
		make_bottom_panel_item_visible(window)
		return

	window = WINDOW_SCENE.instance()
	#window.init(config, get_editor_interface().get_resource_filesystem())
	window.connect("close_requested", self, "_on_window_closed")
	add_control_to_bottom_panel(window, "Version Display")
	make_bottom_panel_item_visible(window)
	

func _on_window_closed():
	if window:
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null
		
