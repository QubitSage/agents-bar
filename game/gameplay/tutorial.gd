extends RefCounted
## A guide derived from real progress: never invents a completion or spends silently.
static func describe(model) -> Dictionary:
	var run: Dictionary=model.state["active"]
	if model.read_only: return {"step":0,"title":"Vamos cuidar do progresso","text":"O arquivo salvo precisa de revisão. Abra Ajuda para conferir o diagnóstico e a opção de recuperar o backup.","action":"support","button":"Abrir ajuda"}
	if not run.is_empty():
		if run.get("phase")=="result": return {"step":2,"title":"Confira o resultado","text":"A recompensa só entra no inventário quando você recolhe. Derrota e retirada não retiram seus itens.","action":"collect","button":"Recolher resultado"}
		return {"step":1,"title":"Sua equipe está em missão","text":"Veja os golpes e a preparação dos inimigos na faixa de combate. Você pode pausar ou recolher a janela. O jogo não acumula batalhas enquanto está fechado.","action":"map","button":"Ver missão"}
	if not model.state["completed"].has("scrap-1"): return {"step":0,"title":"Sua primeira expedição","text":"Io e Brasa já estão prontos. Comece em modo Livre, sem conectar nenhum aplicativo. O botão abaixo inicia Primeiro Sinal e usa o progresso normal.","action":"start","button":"Começar em modo Livre"}
	if "lens" in model.state["inventory"] and model.state["crew"]["io"]["relic"]!="lens":
		var available:=true
		for hero in model.state["crew"]:
			if hero!="io" and model.state["crew"][hero]["relic"]=="lens": available=false
		if available: return {"step":3,"title":"Equipe sua primeira relíquia","text":"A Lente de precisão foi recebida na primeira vitória. Equipe em Io para aplicar seu bônus. Armas e armaduras ficam na outra aba do Inventário.","action":"equip","button":"Equipar a Lente em Io"}
	return {"step":4,"title":"Prepare a próxima viagem","text":"Na Forja você fabrica e aprimora equipamentos. Melhore o Núcleo na Estação para liberar o terceiro herói. Quando quiser, vincule seus agentes; seus tokens nunca viram poder comprado.","action":"finish","button":"Concluir introdução"}

static func act(model,action: String) -> bool:
	if model.read_only: return false
	match action:
		"start":
			if not model.state["active"].is_empty(): return false
			model.state["expedition_mode"]="practice"
			return model.start_mission("scrap-1")
		"collect": return model.collect()
		"equip": return model.equip("io","lens")
		"finish": model.set_option("onboarded",true);return true
	return false
