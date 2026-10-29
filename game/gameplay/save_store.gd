extends RefCounted

const SCHEMA := 4

static func decode(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok":false,"error":"missing"}
	var file:=FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length()>4000000:
		return {"ok":false,"error":"unreadable"}
	var parser:=JSON.new()
	if parser.parse(file.get_as_text())!=OK:
		return {"ok":false,"error":"invalid"}
	var envelope=parser.data
	if not envelope is Dictionary:
		return {"ok":false,"error":"invalid"}
	if not (envelope.get("schema") is int or envelope.get("schema") is float):
		return {"ok":false,"error":"invalid"}
	if int(envelope.get("schema",0))>SCHEMA:
		return {"ok":false,"error":"future"}
	if int(envelope.get("schema",0))==1 and envelope.get("state") is Dictionary:
		return {"ok":true,"state":envelope["state"],"migrated":true}
	var payload=str(envelope.get("payload",""))
	if not int(envelope.get("schema",0)) in [2,3,SCHEMA] or payload.sha256_text()!=str(envelope.get("checksum","")):
		return {"ok":false,"error":"checksum"}
	if parser.parse(payload)!=OK:
		return {"ok":false,"error":"invalid"}
	var state=parser.data
	if not state is Dictionary:
		return {"ok":false,"error":"invalid"}
	return {"ok":true,"state":state,"migrated":int(envelope.get("schema",0))<SCHEMA}

static func load_state(path: String) -> Dictionary:
	var primary:=decode(path)
	if primary.get("ok",false):
		primary["source"]="primary"
		return primary
	# Do not overwrite data produced by a newer application version.
	if primary.get("error")=="future":
		return {"ok":false,"read_only":true,"error":"future"}
	var backup:=decode(path+".bak")
	if backup.get("ok",false):
		backup["source"]="backup"
		return backup
	return {"ok":false,"read_only":primary.get("error")!="missing" or backup.get("error")!="missing","error":primary.get("error","invalid")}

static func save_state(path: String,state: Dictionary) -> bool:
	var existing:=decode(path)
	if existing.get("error")=="future":
		return false
	var absolute:=ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK:
		return false
	var payload:=JSON.stringify(state)
	var envelope: Dictionary={"schema":SCHEMA,"payload":payload,"checksum":payload.sha256_text()}
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	file.close()
	if not decode(temporary).get("ok",false):
		return false
	# Preserve a known-good backup; never rotate a corrupt primary over it.
	if existing.get("ok",false):
		if DirAccess.copy_absolute(absolute,absolute+".bak")!=OK:
			return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),absolute)==OK
