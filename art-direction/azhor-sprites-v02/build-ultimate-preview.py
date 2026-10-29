from pathlib import Path
root=Path(__file__).resolve().parent
html=(root/'index.html').read_text(encoding='utf-8')
html=html.replace('Mordida','Eclipse absoluto').replace('mordida','ultimate').replace('attack_basic','ultimate')
html=html.replace('208','256').replace('91.5%','92.8%')
html=html.replace('Preparação, avanço, impacto e recuperação.','Carga, levitação, descarga do eclipse e queda.')
html=html.replace('ATAQUE BÁSICO','ATAQUE ULTIMATE')
html=html.replace('O peso vem antes do golpe.','O eclipse desperta.')
html=html.replace('O corpo abaixa para preparar o ataque. O pescoço e a boca abrem, avançam e fecham na ultimate. As patas absorvem o impacto antes da recuperação.','AZHOR se comprime, ergue o corpo e levita sob o eclipse. A descarga de energia culmina em uma queda com explosão ao redor das patas, seguida de exaustão e recuperação.')
html=html.replace('8 quadros · 1,38 s','8 quadros · 2,35 s')
html=html.replace('[260,150,130,80,110,120,150,380]','[360,220,170,400,200,220,280,500]')
html=html.replace("['Postura','Preparação','Abertura','Avanço','Eclipse absoluto / impacto','Absorção','Recuperação','Retorno']", "['Postura','Compressão','Ascensão','Levitação / eclipse','Descarga','Queda / explosão','Exaustão','Retorno']")
html=html.replace('<div class="links">','<div class="links"><a href="index.html">← Ver mordida</a>')
(root/'ultimate.html').write_text(html,encoding='utf-8')
index=(root/'index.html').read_text(encoding='utf-8')
if 'href="ultimate.html"' not in index:
    index=index.replace('<div class="links">','<div class="links"><a href="ultimate.html">★ Ver ultimate · Eclipse absoluto</a>')
    (root/'index.html').write_text(index,encoding='utf-8')
note='\n\n### AZHOR — prévia do ultimate (26/10/2026)\n\nDisponível em art-direction/azhor-sprites-v02/ultimate.html, com GIF, folha 4×2 e Aseprite. Oito poses-chave completas, 288×256 px, 2,35 s; 8 frames distintos confirmados no GIF e no cabeçalho nativo. O efeito do eclipse cortado na quinta pose foi recomposto no Aseprite com o eclipse da quarta pose. Escala uniforme e deslocamento vertical para a levitação. Poses geradas; montagem e paleta no Aseprite. Refinamento de continuidade e validação visual pelo usuário continuam pendentes; demais animações e limpeza do pacote antigo não estão concluídas.\n'
for f in ['docs/SPRINT-02.md','ROADMAP.md']:
    with (root.parent.parent/f).open('a',encoding='utf-8') as out: out.write(note)
print('ultimate.html ready; bite gallery linked')
