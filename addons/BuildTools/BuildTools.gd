'BuildTools'
extends EditorExportPlugin

enum VersionIncrementType {
	Major,
	Minor,
	Patch,
	Build
}

const MAX_INDEX :int = 3
const VERSION_FILE_PATH :String = "res://version.txt"
const EXPORT_PRESETS_FILE_PATH :String = "res://export_presets.cfg"
const VERSION_PREFIX :String = "v"
const BUILD_NUMBER_PREFIX :String = "b"

var fullBuildPath :String
var versionString :String
var buildStart :int


func _init():
	print("Initialized BuildTools")
	print_version_string()


func _export_begin(features, is_debug, path, flags):
	print("Build Tools: Building...")
	fullBuildPath = path
	buildStart = OS.get_unix_time()
	print (" Path = " + path)
	print(" Debug = " + str(is_debug))
	print(" Features = " + str(features))
	print(" Flags = " + str(flags))
	
	# get version string
	versionString = get_version_string()
	
	#_update_export_config()
	pass


func get_version_string() -> String:
	var result :String = "?"
	var file = File.new()
	if not file.file_exists(VERSION_FILE_PATH):
		push_error("No version file found at %s" % VERSION_FILE_PATH)
	else:
		file.open(VERSION_FILE_PATH, File.READ)
		result = file.get_as_text()
	file.close()
	return result


func _export_end():
	versionString = _get_incremented_build_number(versionString)
	_save_current_version_to_file()
	
	var elapsed = float(OS.get_unix_time() - buildStart)
	var hours = elapsed / 3600
	var minutes = elapsed / 60
	var seconds = int(ceil(elapsed)) % 60
	var str_elapsed = "%02d : %02d : %02d" % [hours, minutes, seconds]
	print("Build complete.\nDuration = %ss" % str_elapsed)
	print("Successfully incremented build number.\n" + versionString)
	
	# reveal directory in Explorer/Finder
	var split = fullBuildPath.split("/")
	split.remove(split.size() - 1) # remove last entry, the file name
	var openDir = split.join("/")
	print("Opening directory, " + openDir)
	OS.shell_open("file://" + openDir)
	_update_export_config()


func _save_current_version_to_file():
	var file = File.new()
	file.open(VERSION_FILE_PATH, File.WRITE)
	file.store_string(versionString)
	file.close()


func _update_export_config():
	print("Updating " + EXPORT_PRESETS_FILE_PATH + "...")
	var exportConfig :ConfigFile = ConfigFile.new()
	if exportConfig.load(EXPORT_PRESETS_FILE_PATH) != OK:
		push_error("Failed to load " + EXPORT_PRESETS_FILE_PATH)
		return
	
	# TODO: add support for more platforms (iOS, Android, etc.)
	print("Updating for macOS...")
	exportConfig.set_value("preset.0.options", "application/version", versionString)
	exportConfig.set_value("preset.0.options", "application/short_version", _get_short_version())
	print(" Version now " + exportConfig.get_value("preset.0.options", "application/version"))
	
	print("Updating for Windows...")
	exportConfig.set_value("preset.1.options", "application/file_version", versionString)
	exportConfig.set_value("preset.1.options", "application/product_version", versionString)
	print(" Version now " + exportConfig.get_value("preset.1.options", "application/product_version"))

	# Linux has no build/version number?
#	print("Updating for Linux...")
#	exportConfig.set_value("preset.2.options", "application/file_version", versionString)
#	exportConfig.set_value("preset.2.options", "application/product_version", versionString)
#	print(" Version now " + exportConfig.get_value("preset.2.options", "application/product_version"))

	# save updated config
	if exportConfig.save(EXPORT_PRESETS_FILE_PATH) != OK:
		push_error("Failed to save " + EXPORT_PRESETS_FILE_PATH)
	else:
		print(EXPORT_PRESETS_FILE_PATH + " saved successfully")
	print("NOTE: project usually needs to be restarted in order for the export preset displays to be updated.")


func _get_short_version() -> String:
	var result :String = versionString.trim_prefix( VERSION_PREFIX )
	result = result.substr(0, result.find( BUILD_NUMBER_PREFIX ))
	return result


func increment_current_build_number():
	versionString = _get_incremented_build_number(versionString)
	_save_current_version_to_file() # always save?
	print(versionString)


func _get_incremented_build_number(_versionInput :String) -> String:
	var type :int = VersionIncrementType.Build # HACK: for now
	
	# 0 = major, 1 = minor, 2 = patch, 3 = build number
	var maxIndex :int
	var index :int

	# e.g. v1.0.1, no build number
	var currentVersion :String = _versionInput.trim_prefix( VERSION_PREFIX )
	currentVersion = currentVersion.replace( BUILD_NUMBER_PREFIX, "." )
	#string currentVersion = PlayerSettings.bundleVersion;
	var parts :Array = currentVersion.split(".");
	# if no build number, add a zero on the end for it
	if parts.size() <= MAX_INDEX:
		parts.append("0")
	else:
		# trim excess numbers/values
		while parts.size() > MAX_INDEX + 1:
			parts.remove( parts.size() - 1 )

	# start max index off as last possible number index
	maxIndex = min(MAX_INDEX, parts.size() - 1);
	match type:
		# e.g. v1
		VersionIncrementType.Major:
			index = 0;
			while (index >= maxIndex):
				parts.insert(maxIndex, "0")
				maxIndex += 1
		# v1.1
		VersionIncrementType.Minor:
			index = 1;
			while (index >= maxIndex):
				parts.insert(maxIndex, "0")
				maxIndex += 1
		# v1.1.1
		VersionIncrementType.Patch:
			index = 2;
			while (index >= maxIndex):
				parts.insert(maxIndex, "0")
				maxIndex += 1
		# v1.1.1b1
		_:
			if maxIndex <= 0:
				parts.insert(maxIndex, "0")
				maxIndex += 1
			index = maxIndex

	# update max index to at least encompass the desired index
	maxIndex = max(index, maxIndex)
	#parts = temp.ToArray()

	for i in range(parts.size()):
		if i == index:
			var desiredNumber :int = int(parts[i])
			desiredNumber += 1
			parts[i] = str(desiredNumber)
		else:
			# reset numbers after desired index
			if index < i:
				parts[i] = "0"

	# last number should be the build number
	var buildNumberString :String = parts[parts.size() - 1];
	# e.g. v1.0.1b5, new version adds build number on
	var newVersion :String = ""
	for i in range(parts.size()):
		if i == 0:
			newVersion += parts[i]
		elif i < maxIndex:
			newVersion += "." + parts[i]
		else: # last number should be the build number
			newVersion += BUILD_NUMBER_PREFIX + parts[i]
	#newVersion += buildNumberString;

	return VERSION_PREFIX + newVersion # prepend v


func print_version_string():
	versionString = get_version_string()
	print( versionString ) 
	
	
