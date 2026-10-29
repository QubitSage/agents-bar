extends RefCounted
static func tracking_root() -> String:
	var configured:=OS.get_environment("AGENTS_BAR_DATA")
	return configured.path_join("tracking") if configured.is_absolute_path() else ProjectSettings.globalize_path("res://../runtime/tracking").simplify_path()
