# Itens Fortaleza — fontes 0.8

24 sprites editáveis `.aseprite`, 48 × 48, com paleta comum de 53 cores opacas e transparência. Uma camada de arte por item; estes são ícones estáticos, sem animações. Exports transparentes 48/96 ficam em `game/assets/items/`. O tamanho 96 é ampliação exata 2×.

Produção real no Aseprite instalado via Steam, em modo batch. Partiu dos quatro conceitos aprovados em `art-direction/items-fortaleza-v01/`: recorte por alpha, redução com cobertura, quantização para paleta, alpha binário e limpeza de pixels isolados. Não é desenho manual do zero. Build em `scripts/build-items.lua`; teste em `scripts/verify-items.lua`. Ambos recebem o parâmetro `root`; build também recebe `source` com a pasta dos quatro conceitos.

O teste reabre todos os editáveis, renderiza a primeira cel e compara cada pixel com PNG; também confere margem 4 px, alpha 0/255 e escala 2×. O catálogo de gameplay é `game/content/items.json`; nomes originais e método em export-report.json.
