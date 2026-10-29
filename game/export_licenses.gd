extends SceneTree

func _initialize() -> void:
	var directory: String=ProjectSettings.globalize_path("res://../licenses")
	DirAccess.make_dir_recursive_absolute(directory)
	var license_file:=FileAccess.open(directory.path_join("Godot-LICENSE.txt"),FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	license_file.close()
	var details:=FileAccess.open(directory.path_join("Godot-THIRD-PARTY.txt"),FileAccess.WRITE)
	details.store_line("Copyright information embedded in Godot "+str(Engine.get_version_info()["string"]))
	details.store_line(JSON.stringify(Engine.get_copyright_info(),"  "))
	var licenses: Dictionary=Engine.get_license_info()
	for name in licenses:
		details.store_line("\nLicense: "+str(name)+"\n")
		details.store_line(licenses[name])
	details.close()
	var authors:=FileAccess.open(directory.path_join("Godot-AUTHORS.json"),FileAccess.WRITE)
	authors.store_string(JSON.stringify(Engine.get_author_info(),"  "))
	authors.close()
	print("Exported license notices embedded in the bundled Godot runtime.")
	quit()
