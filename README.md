# Godot-Build-Tools

Simple build tools setup for the Godot Engine.

Increments a build number, found in version.txt, each build. Also, updates the version number(s) in export_presets.cfg for certain platforms (macOS, Windows).

TO USE:
- Place the BuildTools folder into your addons directory.
- Create a version.txt in your project, next to your project file, with a version in the following format:
v1.0.0b1 (Major.Minor.Patch b BuildNumber)
- In order for the version(s) in the corresponding export preset to be updated, ensure your export presets are in this order, otherwise change the paths in BuildTools.gd:
	- macOS
	- Windows
- Ensure the plugin is enabled under ProjectSettings/Plugins
- Restart/reload project after enabling. There should be a message in the output window stating that the tools have been initialized. 

ISSUES:

I've found after every script edit of this plugin, I have to reload the project in order for it to work again... And after a build, the export preset version displays are not correct even though they have been updated, until another project reload. 


