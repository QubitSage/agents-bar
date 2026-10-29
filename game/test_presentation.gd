extends SceneTree
const View=preload("res://presentation.gd")
var failures:=0

func check(condition: bool, label: String) -> void:
	if not condition:
		push_error(label)
		failures+=1

func _init() -> void:
	var entrypoint=load("res://main.gd")
	check(entrypoint!=null and entrypoint.can_instantiate(),"Main script compiles")
	check(View.canvas_size(true)==Vector2i(160,48),"Compact dimensions")
	check(View.canvas_size(false)==Vector2i(320,132),"Expanded dimensions")
	var usable:=Rect2i(0,0,1920,1040)
	check(View.dock_rect(usable,2,true)==Rect2i(1588,940,320,96),"Bottom right corner")
	check(View.dock_rect(usable,2,false)==Rect2i(640,772,640,264),"Expanded center")
	var left:=Rect2i(-1920,0,1920,1040)
	check(View.dock_rect(left,3,true).position.x<0,"Negative monitor origin")
	var data: Dictionary={"heartbeatAt":100,"sessions":[{"sessionId":"a","state":"working"},{"sessionId":"b","state":"waiting"},{"sessionId":"c","state":"completed"}]}
	var sessions: Array=View.normalize(data,102)
	check(sessions.size()==3,"Three sessions")
	check(View.summary(sessions)["text"]=="Precisa de você","Attention priority")
	sessions[1]["state"]="working"
	check(View.summary(sessions)["text"]=="2 trabalhando","Active count")
	check(View.normalize(data,106)[0]["state"]=="disconnected","Expired heartbeat")
	check(View.normalize({"sessions":"bad"},100).is_empty(),"Malformed session list")
	check(View.normalize({"heartbeatAt":{},"state":"working"},100)[0]["state"]=="disconnected","Invalid heartbeat type")
	check(View.normalize({"heartbeatAt":100,"lifecycleAt":999999,"state":"completed"},100)[0]["lifecycleAt"]==0,"Future completion rejected")
	check(View.animation({"state":"failed"},100,false)=="idle","No celebration on failure")
	check(View.animation({"state":"completed","lifecycleAt":99},100,false)=="celebrate","Recent completion")
	check(View.animation({"state":"completed","lifecycleAt":20},100,false)=="idle","Old completion")
	check(View.summary([{"sessionId":"real","state":"idle"},View.empty_session(1)])["state"]=="idle","Empty slots do not hide an idle session")
	check(View.connection(false,[{"sessionId":"a","state":"working"}])=="Desconectado","Disconnected never claims work")
	check(View.connection(true,[])=="Coletor ativo · aguardando eventos","Active without events")
	check(View.connection(true,[View.empty_session(0)])=="Coletor ativo · aguardando eventos","Empty slot is not a session")
	check(View.connection(true,[{"sessionId":"a","state":"working"},{"sessionId":"b","state":"waiting"}])=="Aguardando sua permissão","Permission wins")
	check(View.connection(true,[{"sessionId":"a","state":"working"}])=="Funcionando","Working")
	check(View.connection(true,[{"sessionId":"a","state":"unknown"}])=="Sem informação suficiente","Unknown signal")
	check(View.connection(true,[{"sessionId":"a","state":"completed"}])=="Conectado · em descanso","Resting")
	print("Presentation: 24 checks; failures=",failures)
	quit(1 if failures>0 else 0)
