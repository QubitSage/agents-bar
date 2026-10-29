from pathlib import Path
import json,zipfile,hashlib,re
root=Path(__file__).resolve().parent
project=root.parent.parent
summary=json.loads((root/'manifest.json').read_text(encoding='utf-8'))['summary']
check=json.loads((root/'qa/delivery-check.json').read_text(encoding='utf-8'))
assert not summary['issues'] and not check['errors']
assert summary['characters']==24 and summary['animationClips']==226
note='''

## Pacote visual v04 — 26/10/2026

Produção e exportação do escopo visual reunidas em `art-direction/visual-release-v04/index.html`. A galeria offline inclui reprodução, pausa, velocidade, seleção de quadros e uma prévia de HUD com dados fictícios, barras e modo compacto.

- 24 personagens: quatro heróis, dois companheiros, seis inimigos, oito chefes, AZHOR e três NPCs.
- 226 sequências: 188 de personagens, 14 de ambientes/construções, 12 efeitos de combate, oito efeitos ambientais e quatro objetos animados.
- 23 componentes de HUD com cinco estados ou níveis, e 39 elementos estáticos.
- 345 documentos Aseprite, incluindo 288 itens de catálogo e 57 documentos de montagem; 226 GIFs, PNGs e JSONs.
- 1.090 quadros catalogados, contando animações, estados de HUD e elementos estáticos.

Técnica: poses completas geradas; recorte adaptado aos espaços reais entre poses, escala por referência de postura, apoio, paleta de 64 cores e montagem dos cels no Aseprite. O projétil da Luma foi recomposto para evitar atravessar células. O HUD foi desenhado com geometria de pixels no Aseprite; cenários têm camada de efeitos separada. Mordida e ultimate aprovados foram preservados. O antigo pacote de recortes articulados do AZHOR foi removido e seu endereço redireciona para v04.

Validação: presença de todas as sequências planejadas, dimensões, transparência binária, variação de quadros e cabeçalhos nativos; 226 GIFs com quadros/durações conferidos; 51 quadros renderizados novamente pelo Aseprite idênticos aos PNGs. Folhas de contato inspecionadas. Galeria com sintaxe JavaScript verificada, sem abrir aplicativos gráficos.

Limites: ações menores usam quatro poses-chave e ataques principais do AZHOR usam oito. Detalhes gerados podem variar entre quadros. Aceitação na escala final, ajustes finos de continuidade, ritmo, hitboxes, integração no Godot e testes manuais continuam para a etapa do game; a sprint geral não está encerrada. Nenhuma sessão real ou interface do computador foi acessada.

Pacote: `art-direction/Agents-Bar-Visual-v04.zip`. Próxima etapa: integrar esta biblioteca ao jogo, começando pelo herói, um mapa e um confronto completo.
'''
for relative in ['ROADMAP.md','docs/SPRINT-02.md']:
    path=project/relative;content=path.read_text(encoding='utf-8')
    if relative=='ROADMAP.md':
        content=re.sub(r'## Próxima ação\n.*?(?=\n### AZHOR)', '## Próxima ação\n\nIntegrar a biblioteca visual v04 ao game: herói, mapa e confronto completo. O pacote de arte está em `art-direction/visual-release-v04/index.html`; a aceitação no runtime, as mecânicas e as demais validações de produto continuam pendentes. Os registros abaixo documentam as etapas anteriores, substituídas pela entrega v04.\n\n',content,flags=re.S)
    if '## Pacote visual v04 — 26/10/2026' not in content:content+=note
    path.write_text(content,encoding='utf-8')
for name in ['index.html','ultimate.html']:
    path=root.parent/'azhor-sprites-v02'/name;content=path.read_text(encoding='utf-8')
    if '../visual-release-v04/index.html' not in content:
        content=content.replace('<header>','<header><p><a href="../visual-release-v04/index.html">★ Abrir biblioteca completa: personagens, cenários e HUD</a></p>',1)
        path.write_text(content,encoding='utf-8')
# Verify every local HTML/CSS dependency and catalog file before making the ZIP.
missing=[]
for name in ['index.html','LEIA-ME.html']:
    text=(root/name).read_text(encoding='utf-8')
    for link in re.findall(r'(?:href|src)="([^"]+)"',text):
        if link.startswith(('http:', 'https:', '#')) or link.endswith('.zip'):continue
        if not (root/link.split('#')[0]).exists():missing.append(link)
assert not missing,missing
archive=root.parent/'Agents-Bar-Visual-v04.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6)as z:
    for path in sorted(root.rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts:z.write(path,Path(root.name)/path.relative_to(root))
with zipfile.ZipFile(archive)as z:
    bad=z.testzip();assert bad is None,bad
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix('.sha256').write_text(digest+'  '+archive.name+'\n')
print(json.dumps(dict(zip=str(archive),bytes=archive.stat().st_size,sha256=digest,summary=summary),ensure_ascii=False))
