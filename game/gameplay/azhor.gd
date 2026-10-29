extends RefCounted
## Deterministic world-boss moves. No random or elapsed real-world progression.
const ID="azhor"
const PHASE_ONE=["attack_basic","attack_01_stomp","defense","attack_02_tail","attack_03_beam","attack_04_barrage","ultimate"]
const PHASE_TWO=["attack_03_beam","attack_04_barrage","defense","attack_02_tail","ultimate"]
const MOVES={
	"attack_basic":{"name":"Mandíbula do vazio","frame":3,"power":1.0,"area":false,"ranged":false},
	"attack_01_stomp":{"name":"Passo tectônico","frame":4,"power":.85,"area":true,"ranged":true},
	"attack_02_tail":{"name":"Cauda orbital","frame":4,"power":.8,"area":true,"ranged":true},
	"attack_03_beam":{"name":"Raio do eclipse","frame":4,"power":1.5,"area":false,"ranged":true},
	"attack_04_barrage":{"name":"Chuva de fragmentos","frame":4,"power":.7,"area":true,"ranged":true},
	"defense":{"name":"Bastião de estrelas","frame":3,"power":0.0,"area":false,"ranged":true},
	"ultimate":{"name":"ECLIPSE TOTAL","frame":5,"power":1.8,"area":true,"ranged":true}
}

static func phase(unit: Dictionary) -> int:
	return 2 if int(unit["hp"])*2<=int(unit["max_hp"]) else 1

static func next_clip(unit: Dictionary,round_number: int) -> String:
	var sequence: Array=PHASE_TWO if phase(unit)==2 else PHASE_ONE
	return sequence[maxi(0,round_number-1)%sequence.size()]

static func power(unit: Dictionary,clip_name: String,enraged: bool) -> int:
	return maxi(1,int(float(unit["attack"])*float(MOVES[clip_name]["power"])*(1.25 if enraged else 1.0)))
