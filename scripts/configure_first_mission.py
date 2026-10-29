from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
path=root/'game/content/game.json'
content=json.loads(path.read_text(encoding='utf-8'))
hero=content['characters'][0]
hero.update(name='Cavaleiro',role='Vanguarda',description='Avança com espada e escudo. A cada três rodadas, prepara uma defesa.',hp=150,attack=22,armor=3,skill='shield',skill_name='Guarda de aço')
for e in content['enemies']:
    if e['id']=='scrap-drone':e['name']='Vigia de Latão'
mission=content['missions'][0]
mission.update(name='Primeiro Sinal',brief='Atravesse a Forja, derrote o Vigia de Latão e o Caranguejo de Cobre e enfrente o Rebocador para recuperar um núcleo.',waves=[['scrap-drone'],['scrap-crab'],['scrap-boss']],timed=True,scene='scene-scrap-1',objective='Recuperar o núcleo da Forja',boss=True)
content['maps'][0].update(name='Forja nas Nuvens',subtitle='Recupere o núcleo protegido pelo Rebocador.')
path.write_text(json.dumps(content,ensure_ascii=False,indent=2),encoding='utf-8')
print('First mission configured: 3 encounters, starter knight, timed combat')
