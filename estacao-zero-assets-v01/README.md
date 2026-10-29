# Estação Zero — assets v0.1

Primeiro kit autoral de pixel art para um jogo de companhia no desktop. Este pacote contém assets editáveis; não é um aplicativo Windows integrado aos agentes.

## Abrir e revisar

- `preview.html`: galeria local, personagens animados e demonstração dos componentes do HUD. Abra no navegador. Nenhum servidor ou acesso à internet é necessário.
- `source/world.aseprite`: cena em seis camadas editáveis.
- `source/io-explorer.aseprite`, `brasa-mechanic.aseprite` e `luma-botanist.aseprite`: personagens com animações nomeadas e camadas body, equipment e effects.
- `source/hud.aseprite`: componentes com slices; os componentes redimensionáveis incluem centros de nine-slice.
- `source/props.aseprite`: objetos com slices nomeados e pivôs.
- `source/estacao-zero.gpl`: paleta compartilhada, 16 cores opacas mais transparência.

## Conteúdo

| Família | Conteúdo |
| --- | --- |
| Mundo | Cena de 640 × 192 px; céu, ilhas distantes, plataforma, construções, objetos e tripulação em camadas |
| Personagens | IO, explorador; Brasa, mecânico; Luma, botânico |
| Animações | Por personagem: idle 4 quadros, walk 6, work 4, wait 4, celebrate 6; 24 quadros por personagem, 72 no total |
| Módulos | Oficina, estufa, observatório, doca e segmento de plataforma |
| Objetos | 12 objetos em células de 32 × 32 px, com PNGs individuais |
| HUD | Painel, quatro estados de botão, trilho e preenchimento de progresso, tooltip, retrato e notificação |
| Ícones | 12 ícones de 16 × 16 px, também exportados individualmente |

## Especificação de integração

- Personagens: célula fixa de 48 × 48 px, pivô (24,44), voltados para a direita. Espelhar horizontalmente para o deslocamento à esquerda; isso também espelha os equipamentos.
- As sheets têm seis colunas por cinco linhas. Células excedentes de cada linha ficam transparentes. Consumir as coordenadas e durações dos JSONs correspondentes, sem assumir que todas as linhas têm seis quadros.
- Filtragem nearest-neighbor. Preferir escala inteira 2× ou 3×. A aplicação ainda precisa tratar DPI e monitores diferentes.
- PNGs com fundo transparente nos personagens, objetos, módulos e HUD. A cena completa tem fundo opaco.
- HUD sem palavras incorporadas à imagem. Renderizar rótulos, estados e valores como texto acessível na aplicação.
- `hud.json`: coordenadas e margens em pixels para nine-slice. Preenchimento de progresso pode ser recortado na horizontal. Tooltip tem ponta e não deve ser esticado indiscriminadamente.
- Os clipes deste kit são cíclicos. O aplicativo pode reproduzir celebrate uma vez ao receber o evento de conclusão.
- Os edifícios são módulos raster separados; o arquivo não contém um tileset nativo de tilemap. O segmento de plataforma pode ser repetido horizontalmente.

## Autoria e limites desta versão

O estudo em `concepts/world-direction.png` foi criado com a ferramenta integrada de geração de imagens. O prompt completo está em `concepts/world-direction.prompt.txt`. Ele orienta atmosfera, materiais e silhuetas; não é um atlas pronto para recorte.

Os assets em `source/` e `exports/` foram desenhados em grade inteira por um script Lua original executado no Aseprite 1.3.18.6. Não foram obtidos reduzindo a imagem gerada. O script reproduzível está em `scripts/build-assets.lua`; use uma nova pasta/versão antes de reexecutá-lo, pois ele substitui suas próprias saídas.

Este é um primeiro kit funcional para avaliação visual. As animações são curtas e estilizadas; ainda cabe refinamento manual de peso, arcos e transições. Não há sons, fonte própria, conexões com agentes, cálculo de progressão nem integração com a barra do Windows neste pacote.

## Verificação

O pacote é verificado reabrindo os arquivos no Aseprite, conferindo dimensões, camadas, tags, total de quadros, transparência, cores e correspondência das sheets exportadas. O resultado fica em `scripts/validation.txt`.
