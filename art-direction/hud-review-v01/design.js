
const V={
 a:{name:"A · Fortaleza",title:"Fortaleza — RPG clássico",description:"Personagem sempre visível, três áreas de informação e navegação na base.",w:884,h:574,note:"Prioridade: identidade de RPG e leitura simultânea de personagem, itens e ação."},
 b:{name:"B · Travessia",title:"Travessia — compacto e equilibrado",description:"Dois painéis contextualizados. Mais espaço para o conteúdo, menos área ocupada no desktop.",w:820,h:568,note:"Minha recomendação: mantém a identidade de RPG e usa menos espaço na tela."},
 c:{name:"C · Comando",title:"Comando — agentes em primeiro plano",description:"Navegação lateral, contexto persistente e faixa de combate maior.",w:1032,h:566,note:"Prioridade: acompanhar agentes e ações em paralelo; exige mais largura."}
};
const SCREENS=[["hero","Personagem"],["inventory","Inventário"],["forge","Forja"],["map","Mapa"],["station","Estação"],["agents","Agentes"],["history","Histórico de uso"],["journal","Diário / revisão"],["settings","Menu / dimensões"],["pro","Plano Pro"],["boss","Boss / ultimate"],["compact","Barra recolhida"]];
const NAV=[["hero","Herói","team"],["inventory","Mochila","journal"],["forge","Forja","station"],["map","Mapa","map"],["station","Estação","station"],["agents","Agentes","attention"],["journal","Diário","journal"],["settings","Menu","sound"]];
const q=new URLSearchParams(location.search);let version=q.get("v")||"b",screen=q.get("screen")||"hero",state=q.get("state")||"working";
if(!V[version])version="b";if(!SCREENS.some(x=>x[0]===screen))screen="hero";
const chars={knight:"hero-classic--idle",brasa:"companion-brasa--idle",luma:"companion-luma--idle"};
function sprite(id,height=40,maxWidth=100,frame=0){
 const m=CAT[id];if(!m)return '<span class="small">◇</span>';
 const f=Math.min(frame,m.frames-1),b=m.alphaBounds[f]||m.alphaBounds[0],bw=b[2]-b[0],bh=b[3]-b[1];
 const s=Math.min(height/bh,maxWidth/bw),x=(f%m.columns)*m.width+b[0],y=Math.floor(f/m.columns)*m.height+b[1];
 return '<span class="sprite" style="width:'+Math.ceil(bw*s)+'px;height:'+Math.ceil(bh*s)+'px"><img alt="" draggable="false" src="assets/'+m.sheet+'" style="width:'+(m.width*m.columns*s)+'px;height:'+(m.height*m.rows*s)+'px;left:'+(-x*s)+'px;top:'+(-y*s)+'px"></span>';
}
const item=(n,h=32)=>sprite("atlas-relics-"+String(n).padStart(2,"0"),h,42);
const bar=(n=72,cl="")=>'<div class="bar '+cl+'"><i style="width:'+n+'%"></i></div>';
const button=(text,cl="",go="")=>'<button class="hbtn '+cl+'" '+(go?'data-go="'+go+'"':'data-demo="true"')+'>'+text+'</button>';
const bottom=(...x)=>'<div class="bottom">'+x.join("")+'</div>';
const p=text=>'<p>'+text+'</p>';
const tag=text=>'<span class="tag">'+text+'</span>';
const card=(title,content,sub="")=>'<section class="card"><div class="card-head">'+title+'<small>'+sub+'</small></div><div class="card-body">'+content+'</div></section>';
const segmented=(labels,active=0)=>'<div class="segmented">'+labels.map((x,i)=>'<button class="hbtn '+(i===active?'on':'')+'" data-demo="true">'+x+'</button>').join("")+'</div>';
const slot=(n=0,selected=false,label="")=>'<div class="slot '+(n?'':'empty ')+(selected?'selected':'')+'">'+(n?item(n):'·')+(label?'<em>'+label+'</em>':'')+'</div>';
const weapon=(level)=>'<div class="slot equipped"><svg width="34" height="34" viewBox="0 0 32 32" shape-rendering="crispEdges" aria-label="Espada"><path fill="#343c55" d="M23 2h7v7L14 25 7 18z"/><path fill="#f1f5fa" d="M24 3h4v5L13 23 9 19z"/><path fill="#91a5c8" d="M28 3v5L13 23l-2-2z"/><path fill="#e1b76d" d="m7 16 10 10-3 3L4 19z"/><path fill="#805332" d="m6 22 4 4-5 5-4-4z"/><path fill="#d8b46d" d="m2 26 4 4-2 2H0v-4z"/><path fill="#fff1b0" d="m7 16 10 10-1 1L6 17z"/></svg><em>+'+level+'</em></div>';
const stats=(pairs)=>'<div class="stats">'+pairs.map(x=>'<div class="stat"><span>'+x[0]+'</span><b>'+x[1]+'</b></div>').join("")+'</div>';
const xp=(label="Nível 12",value="420 / 600 XP")=>'<div class="xp"><small><span>'+label+'</span><span>'+value+'</span></small>'+bar(70)+'</div>';
const pager=(label="1 / 3",go="")=>'<div class="pager">'+button("‹","ghost",go)+'<span>'+label+'</span>'+button("›","ghost",go)+'</div>';
const heroStage=(height=116)=>'<div class="hero-stage">'+sprite(chars.knight,height,130)+'</div>';
const paperdoll=()=>'<div class="paperdoll"><div class="gear-stack">'+slot(2,true)+slot(1)+'</div>'+heroStage(120)+'<div class="gear-stack">'+slot(5)+slot(4)+'</div></div>';
const feature=(n,name,rarity="RELÍQUIA")=>'<div class="item-feature">'+slot(n,true)+'<div><h3>'+name+'</h3>'+tag(rarity)+'</div></div>';
const scene=(id,title)=>'<div class="scene-preview" style="background-image:url(assets/'+CAT[id].sheet+');background-size:auto 100%"><span class="overlay"></span><span class="scene-title">'+title+'</span></div>';
const material=(name,amount)=>'<div class="material"><span>'+name+'</span><b>'+amount+'</b></div>';
function context(){
 if(version==="c")return '<aside class="context command-context"><span class="small">EQUIPE / SESSÕES</span>'+[["C","Codex","Cavaleiro","Edição"],["A","Claude Code","Brasa","Testes"],["Cu","Cursor","Luma","Aprovação"]].map(x=>session(x[0],x[1],x[2],state==="disconnected"?"Sem conexão":(x[0]==="C"&&["waiting","error"].includes(state))?stateLabel():x[3],x[0]==="C")).join("")+'<div class="xp" style="margin-top:auto"><small><span>Crédito de atividade</span><span>18s / 30s</span></small>'+bar(60,"blue")+'</div><span class="small">Expedição ligada à formação</span></aside>';
 if(screen==="hero")return '<aside class="context formation-context"><span class="small">FORMAÇÃO / 3 HERÓIS</span>'+[["knight","Cavaleiro","Vanguarda"],["brasa","Brasa","Guardião"],["luma","Luma","Botânica"]].map(([id,name,role])=>'<div class="formation-entry">'+sprite(chars[id],52,55)+'<div><b>'+name+'</b><small>'+role+'</small>'+bar(80,"hp")+'</div></div>').join("")+'<div style="margin-top:auto;width:100%">'+stats([["Vagas","3 / 3"],["Agentes","3"]])+'</div><span class="small">Selecione um herói para equipar.</span></aside>';
 return '<aside class="context"><span class="small">FORMAÇÃO · 01 / 03</span>'+heroStage(112)+'<h3>Cavaleiro</h3><span class="small">Vanguarda · Guarda de aço</span>'+xp()+stats([["Vida","174"],["Ataque","31"],["Armadura","8"],["Arma","+3"]])+'<div class="party">'+sprite(chars.knight,29,40)+sprite(chars.brasa,29,40)+sprite(chars.luma,29,40)+'</div></aside>';}
function page(){
 if(screen==="agents"&&state==="disconnected")return [
  card("Conexões",'<div class="empty-state">'+sprite("ui-control-disconnected",40,44)+'<h2>Nenhuma sessão</h2>'+p("Escolha quando conectar uma fonte. O jogo não descobre conversas automaticamente.")+'</div>'+bottom(button("Ativar coletor local","primary grow")),"DESCONECTADO"),
  card("Conectar um agente",p("1. Ative o coletor local.<br><br>2. Configure um hook ou MCP no aplicativo escolhido.<br><br>3. Vincule a sessão recebida a um herói.")+'<div class="warning">Enquanto não há atividade recebida, a expedição aguarda. O modo Livre continua disponível.</div>'+bottom(button("Abrir configuração","grow")))];
 if(screen==="agents"&&["waiting","error"].includes(state))return [
  card("Agente selecionado",session("C","Codex","Agents Bar · Cavaleiro",stateLabel(),true)+tag(state==="waiting"?"AGUARDANDO VOCÊ":"FALHA INFORMADA")+'<h2>'+(state==="waiting"?"Aprovação pendente":"Sessão interrompida")+'</h2>'+p(state==="waiting"?"O agente aguarda sua autorização para continuar. Confirme a ação no aplicativo de origem.":"A fonte informou uma falha. Verifique o aplicativo antes de retomar.")+bottom(button("Ver detalhes da sessão","grow"))),
  card("O que acontece no jogo",heroStage(108)+p("A expedição aguarda nova atividade.<br>A vida e o progresso da equipe são preservados.")+'<div class="warning">'+(state==="waiting"?"Aprovar uma ação do agente acontece no aplicativo de origem.":"Falha do agente não significa derrota do personagem.")+'</div>'+bottom(button("Voltar ao mapa","grow","map")))];
 switch(screen){
 case "hero":return [
 card("Personagem",segmented(["Cavaleiro","Brasa","Luma"])+paperdoll()+xp()+bottom(button("Treinar · 24 sucata","primary grow"),button("Formação","grow")),"NÍVEL 12"),
 card("Equipamento e vínculo",feature(2,"Placa do Rebocador","EQUIPADA")+stats([["Vida","+10"],["Armadura","+2"],["Ataque","31"],["Velocidade","3"]])+p("Guarda de aço<br>Prepara uma defesa a cada três rodadas.")+'<div class="session"><div class="provider">C</div><div class="meta"><b>Codex · Agents Bar</b><small><i class="dot"></i>Sessão vinculada ao Cavaleiro</small></div></div>'+bottom(button("Inventário","grow","inventory"),button("Agentes","grow","agents")))];
 case "inventory":return [
 card("Mochila",segmented(["Relíquias","Materiais"])+ '<div class="inventory-info"><span>6 relíquias únicas</span><span>Filtro: todas</span></div><div class="item-grid">'+[1,2,3,4,5,6,0,0,0,0,0,0].map(n=>slot(n,n===2)).join("")+'</div>'+pager("1 / 1 · 6 de 12 espaços"),"CAPACIDADE 12"),
 card("Relíquia selecionada",feature(2,"Placa do Rebocador","RARO · EQUIPADA")+p("Fragmento recuperado da carcaça do Rebocador. Reforça a defesa de quem o carrega.")+stats([["Vida","+10"],["Armadura","+2"]])+segmented(["Cavaleiro","Brasa","Luma"])+bottom(button("Desequipar","grow"),button("Reciclar +4","grow")))];
 case "forge":return [
 card("Aprimorar arma",segmented(["Cavaleiro","Brasa","Luma"])+'<div class="recipe">'+weapon(3)+'<span class="plus">→</span>'+weapon(4)+'</div>'+stats([["Ataque atual","31"],["Após melhoria","33"]])+material("Sucata","80 / 32")+material("Núcleos","6 / 1")+bottom(button("Aprimorar para +4","primary grow")),"OFICINA NÍVEL 2"),
 card("Recriar relíquia",feature(5,"Bobina de tempestade","RECEITA DESBLOQUEADA")+p("+6 de ataque. Disponível após concluir a missão de origem.")+'<div class="item-grid">'+[1,2,3,4,5,6].map(n=>slot(n,n===5)).join("")+'</div><span class="small">Custo: 24 sucata + 1 núcleo</span>'+bottom(button("Recriar relíquia","grow")))];
 case "map":return [
 card("Escolha uma rota",segmented(["Forja","Jardins","Tempestade"],2)+scene("scene-storm-1","Cinturão de Tempestade")+["O primeiro trovão","Sentinelas do farol","Olho da tempestade","AZHOR · Ruptura"].map((name,i)=>'<div class="route '+(i===3?'selected':'')+'"><span class="number">0'+(i+1)+'</span><span class="route-title">'+name+'</span><span class="route-status">'+(i<3?'✓':'CHEFE')+'</span></div>').join(""),"REGIÃO 03"),
 card("Expedição selecionada",'<h2>AZHOR · Ruptura</h2>'+tag("CHEFE MUNDIAL")+p("Atravesse o limite da tempestade. AZHOR muda de fase e atinge toda a formação com a ultimate.")+stats([["Encontros","1"],["Dificuldade","Extrema"],["Sucata","64"],["Núcleos","3"]])+'<span class="small">Modo de avanço</span>'+segmented(["Atividade dos agentes","Livre"])+bottom(button("Iniciar expedição","primary grow","boss")))];
 case "station":return [
 card("Estação Zero",'<div class="buildings">'+["core","workshop","greenhouse","observatory"].map((id,i)=>'<div class="building">'+sprite("building-"+id,79,78)+'<span>'+["Núcleo","Oficina","Estufa","Farol"][i]+'</span></div>').join("")+'</div>'+segmented(["Núcleo","Oficina","Estufa","Farol"],1)+stats([["Núcleo","Nível 2"],["Oficina","Nível 2"],["Estufa","Nível 1"],["Lembranças","7"]])+p("Selecione uma construção para melhorar ou vincular uma entrega."),"4 CONSTRUÇÕES"),
 card("Oficina",'<h2>Oficina · nível 2</h2>'+p("Cada nível acrescenta +2 de ataque à equipe. A estação acompanha as entregas que você revisou.")+material("Sucata","80 / 48")+material("Núcleos","6 / 4")+'<span class="small">Posição na estação</span>'+segmented(["1","2","3","4"],1)+'<div class="field">‹ &nbsp; HUD revisado e aprovado &nbsp; ›</div>'+bottom(button("Melhorar","primary grow"),button("Vincular lembrança","grow")))];
 case "agents":return [
 card("Agentes conectados",session("C","Codex","Agents Bar · Cavaleiro","Editando arquivos",true)+session("A","Claude Code","API local · Brasa","Executando testes")+session("Cu","Cursor","Website · Luma","Aguardando aprovação")+pager("1 / 1 · 3 sessões"),"3 / 3 · GRÁTIS"),
 card("Vínculo e atividade",segmented(["Cavaleiro","Brasa","Luma"])+feature(1,"Codex → Cavaleiro","VINCULADO")+stats([["Estado","Trabalhando"],["Atividade","Edição"],["Tokens","12.840"],["Fonte","Hook local"]])+p("Somente atividade observada abastece a expedição. Tokens indisponíveis são identificados.")+bottom(button("Desvincular","grow"),button("Ver histórico","grow","history")))];
 case "history":return [
 card("Histórico de uso",segmented(["Hoje","7 dias","90 dias"])+ '<div class="chart">'+[23,39,28,56,42,77,58,68,95,66,45,83].map(h=>'<i style="height:'+h+'%"></i>').join("")+'</div>'+stats([["Tokens hoje","38.420"],["Eventos","124"],["Sessões","3"],["Fontes","2 conhecidas"]])+p("Totais fictícios para avaliar a leitura. Uma fonte sem contagem de tokens não entra na soma.")+bottom(button("Voltar aos agentes","grow","agents"))),
 card("Sessões / período",'<div class="hist-row head"><span>Fonte</span><span>Tokens</span><span>Eventos</span></div>'+[["Codex","12.840","44"],["Claude Code","25.580","62"],["Cursor","Indisponível","18"]].map(x=>'<div class="hist-row">'+x.map(v=>'<span>'+v+'</span>').join("")+'</div>').join("")+p("Grátis: histórico local de 24 horas.<br>Pro: histórico de até 90 dias.")+pager("1 / 1 · hoje")+bottom(button("Conhecer Pro","grow","pro")))];
 case "journal":return [
 card("Diário",segmented(["Revisar","Histórico","Combate"])+[["HUD revisado e aprovado","Entrega · há 8 min"],["Integração local validada","Entrega · há 21 min"],["O Rebocador derrotado","Expedição · hoje"]].map((x,i)=>'<div class="note-row '+(!i?'selected':'')+'"><span class="checkmark">'+(!i?'◇':'✓')+'</span><div><b>'+x[0]+'</b><small>'+x[1]+'</small></div></div>').join("")+'<div class="field">+ Registrar uma entrega</div>'+pager("1 / 2 · 5 registros")),
 card("Revisar entrega",tag("AGUARDANDO REVISÃO")+'<h2>HUD revisado<br>e aprovado</h2>'+p("Confirme se esta entrega deve virar uma lembrança na estação. O término de uma sessão não é aceito automaticamente.")+stats([["Origem","Manual"],["Recompensa","Lembrança"]])+bottom(button("Descartar","grow"),button("Aceitar entrega","primary grow")))];
 case "settings":return [
 card("Janela e dimensões",p("Arraste pelo cabeçalho. Redimensione pelas bordas ou informe as dimensões abaixo.")+'<div class="move-guide"><span>↖ cabeçalho arrastável</span><span>8 alças ↘</span></div>'+segmented(["Pequeno","Padrão","Amplo"],1)+'<div class="segmented"><div class="field grow">Largura &nbsp; '+V[version].w+' px</div><div class="field grow">Altura &nbsp; '+V[version].h+' px</div></div>'+toggle("Sempre visível",true)+toggle("Lembrar posição e tamanho",true)+bottom(button("Aplicar dimensões","primary grow"))),
 card("Preferências",toggle("Sons",false)+toggle("Movimento reduzido",false)+toggle("Indicadores de atividade",true)+p("Barra e HUD guardam tamanhos separados. Abrir um menu mantém a missão ativa.")+'<div class="warning">Proposta de comportamento. As dimensões finais serão validadas depois da escolha visual.</div>'+bottom(button("Plano Pro","grow","pro"),button("Recolher","grow","compact")))];
 case "pro":return [
 card("Agents Bar Pro",'<div class="price">US$ 2 <small>/ mês</small></div>'+p("Mais sessões e mais histórico para acompanhar seu trabalho.")+["Até 12 agentes simultâneos","Histórico de uso de 90 dias","Mesma formação e mesmas regras de combate"].map(x=>'<div class="feature"><span class="accent">✓</span>'+x+'</div>').join("")+'<div class="warning">Cobrança e publicação ficam para o final. Esta tela é somente uma proposta visual.</div>'+bottom(button("Quero o Pro","primary grow"))),
 card("Seu plano",tag("GRÁTIS")+stats([["Sessões","3 / 3"],["Histórico","24 horas"],["Heróis na formação","Até 3"],["Combate","Completo"]])+'<span class="small">Já tem uma licença?</span><div class="field">Cole sua chave de ativação</div>'+bottom(button("Ativar licença","grow")))];
 case "boss":return [
 card("AZHOR",'<div class="boss-preview">'+sprite("world-boss-09-azhor--ultimate",105,230,2)+'</div>'+tag("FASE 2 · ULTIMATE")+bar(38,"hp")+p("Ruptura da Tempestade<br>Impacto em toda a formação.")+bottom(button("Pausar combate","grow")),"CHEFE MUNDIAL"),
 card("Sua formação",session("01","Cavaleiro","Vida 128 / 174 · Escudo 18","Defendendo",true)+session("02","Brasa","Vida 89 / 160 · Escudo 24","Protegendo a equipe")+session("03","Luma","Vida 72 / 110","Cura preparada")+bottom(button("Retirar equipe","grow"),button("Revisar vitória","primary grow","victory")))];
 }
 return [];
}
function session(initial,name,project,activity,active=false){return '<div class="session '+(active?'active':'')+'"><div class="provider">'+initial+'</div><div class="meta"><b>'+name+'</b><small>'+project+'</small><div class="small" style="margin-top:4px"><i class="dot"></i>'+activity+'</div></div></div>'}
function toggle(name,on){return '<div class="toggle-row"><span>'+name+'</span><span class="switch '+(on?'':'off')+'"></span></div>'}
function stateLabel(){return {working:"Trabalhando",waiting:"Aguardando aprovação",disconnected:"Desconectado",error:"Falha · atenção",victory:"Missão concluída"}[state]||"Trabalhando"}
function combat(){
 const boss=screen==="boss",m=CAT[boss?"scene-storm-1":"scene-scrap-1"],mode=state==="disconnected"?"Expedição aguardando atividade":state==="waiting"?"Avanço pausado · aprovação no agente":state==="error"?"Avanço pausado · verifique a sessão":"Encontro 2 / 3 · combate automático";
 return '<section class="combat" style="background-image:url(assets/'+m.sheet+');background-size:auto 100%"><div class="battle-label"><span>'+(boss?'CINTURÃO DE TEMPESTADE · AZHOR':'FORJA NAS NUVENS · PRIMEIRO SINAL')+'</span><span>'+(['waiting','disconnected','error'].includes(state)?'AGUARDANDO ATIVIDADE':boss?'ULTIMATE · IMPACTO EM 1,2s':'ATAQUE PREPARADO · 0,4s')+'</span></div><div class="actors">'+[
 ["companion-luma--idle",9,45],["companion-brasa--idle",21,47],["hero-classic--attack",34,55],[(boss?"world-boss-09-azhor--ultimate":"enemy-brass-sentry--idle"),72,boss?78:51]
 ].map(([id,x,h])=>'<div class="actor" style="left:'+x+'%">'+sprite(id,h,boss?140:85,1)+bar(72,"hp")+'</div>').join("")+'</div><div class="battle-meter"><span>'+mode+'</span><span>Crédito de atividade · 18s</span><div class="battle-actions">'+button("Ⅱ Pausar")+button("↩ Retirar")+'</div></div></section>';
}
function victoryOverlay(){return '<div class="overlay-veil"><section class="inner-modal">'+tag("EXPEDIÇÃO CONCLUÍDA")+'<h2>Vitória sobre AZHOR</h2><p>A formação retornou à estação.<br>Revise e recolha as recompensas.</p><div class="loot">'+slot(6,true)+slot(3)+slot(1)+'</div>'+stats([["Sucata","+64"],["Núcleos","+3"],["Experiência","+180"],["Lembrança","+1"]])+'<div style="margin-top:16px">'+button("Revisar e recolher","primary","journal")+'</div></section></div>'}
function compactView(){
 const mini=(label,width,st)=>'<div><div class="mini-label">'+label+'</div><section class="mini-hud '+version+' state-'+st+'" style="width:'+width+'px"><span class="grip">⠿</span>'+sprite(chars.knight,45,52)+'<div class="mini-info"><h3>AGENTS BAR</h3><p><i class="dot"></i>'+({working:"3 agentes trabalhando",waiting:"1 aprovação pendente",disconnected:"Desconectado · nenhuma sessão"}[st])+'</p></div>'+button("Abrir","ghost","hero")+'<span class="resize">◢</span></section></div>';
 return '<div class="compact-wrap">'+mini("BARRA RECOLHIDA / TRABALHANDO",404,"working")+mini("PEDIDO DE ATENÇÃO / SEM ABRIR OUTRA JANELA",440,"waiting")+mini("INÍCIO SEGURO / SEM CONEXÃO",404,"disconnected")+'</div>';
}
function draw(){
 document.querySelector("#versions").innerHTML=Object.entries(V).map(([k,v])=>'<button data-version="'+k+'" class="'+(k===version?'active':'')+'">'+v.name+'</button>').join("");
 const sel=document.querySelector("#screens");sel.innerHTML=SCREENS.map(([k,v])=>'<option value="'+k+'">'+v+'</option>').join("");sel.value=screen;
 document.querySelector("#states").value=state;document.querySelector("#states").disabled=screen==="compact";
 document.querySelector("#concept").textContent=V[version].title;
 document.querySelector("#description").textContent=V[version].description;
 document.querySelector("#dimensions").textContent=screen==="compact"?"404 × 78 px · sugestão":V[version].w+" × "+V[version].h+" px · proposta";
 document.querySelector("#note").textContent=V[version].note;
 const mount=document.querySelector("#mount");
 if(screen==="compact"){mount.innerHTML=compactView();fit();return}
 const [left,right]=page();
 mount.innerHTML='<div class="hud '+version+' state-'+state+'"><header class="titlebar"><span class="grip">⠿</span><b class="brand">AGENTS BAR</b><span class="currency"><span class="coin">◆ 80 sucata</span><span class="gem">◆ 6 núcleos</span><span class="seed">❧ 12 sementes</span></span><button class="chrome" data-go="compact">−</button><button class="chrome" data-demo="true">×</button></header><div class="sessionbar"><span><i class="dot"></i>'+stateLabel()+'</span><span class="line"></span><b>'+(state==="disconnected"?"Nenhuma sessão vinculada":"Codex · Agents Bar")+'</b><span class="right">'+(version==="c"?"CENTRAL DE EXPEDIÇÕES":"FORMAÇÃO 3 / 3")+'</span></div><div class="main">'+context()+'<div class="workspace">'+left+right+'</div></div>'+combat()+'<nav class="nav">'+NAV.map(([key,label,icon])=>'<button data-go="'+key+'" class="'+(key===screen||(screen==="history"&&key==="agents")||(screen==="pro"&&key==="settings")?'on':'')+'">'+sprite("ui-control-"+icon,version==="c"?23:18,25)+'<span>'+label+'</span></button>').join("")+'</nav><footer class="statusline"><span>'+(state==="waiting"?"Aprovação necessária no aplicativo do agente. O jogo aguarda.":state==="error"?"A sessão informou uma falha. Abra Agentes para verificar.":state==="disconnected"?"Conecte uma fonte em Agentes quando quiser começar.":"Trabalho observado abastece a expedição · dados ilustrativos")+'</span><span class="resize">ESC · RECOLHER &nbsp; ◢</span></footer>'+(state==="victory"?victoryOverlay():"")+'</div>';
 fit();
}
function fit(){const width=screen==="compact"?440:V[version].w;const scale=Math.min(1,(document.querySelector(".stage").clientWidth-34)/width);document.querySelector("#mount").style.transform="scale("+scale+")"}
document.addEventListener("click",e=>{
 const ver=e.target.closest("[data-version]");if(ver){version=ver.dataset.version;draw();return}
 const go=e.target.closest("[data-go]");if(go){if(go.dataset.go==="victory"){state="victory"}else{screen=go.dataset.go;if(state==="victory")state="working"}draw();return}
 const demo=e.target.closest("[data-demo]");if(demo){const previous=demo.textContent;demo.classList.toggle("on");document.querySelector("#note").textContent="Prévia visual: "+previous+". Essa ação será implementada depois da aprovação."}
});
document.querySelector("#screens").onchange=e=>{screen=e.target.value;draw()};
document.querySelector("#states").onchange=e=>{state=e.target.value;draw()};
window.addEventListener("resize",fit);
window.setReview=(v,s,st="working")=>{version=v;screen=s;state=st;draw()};
draw();



