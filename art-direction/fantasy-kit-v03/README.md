# Agents Bar — pacote Aseprite v03
Data: 2026-10-26.

## Abrir
- Abra index.html para navegar pelo kit, ver repouso/impacto e baixar cada arquivo.
- Abra qualquer arquivo em aseprite/ no Aseprite. São arquivos nativos indexados, com camadas e tags.
- png/ contém o quadro estático em resolução nativa.
- sheets/ contém as sequências horizontais.
- metadata/ contém dimensões, durações, tags e pivôs. Os quadros começam em zero no JSON.
- palettes/agents-bar-64.gpl é a paleta comum.

## Inventário
119 arquivos .aseprite = 38 artes individuais (32 anteriores + 6 novos chefes), 75 elementos separados e 6 folhas de coleção.
- 4 aparências do protagonista.
- 2 companheiros, 3 NPCs e 6 inimigos.
- 8 chefes normais (3 anteriores + 5 novos) e 1 world boss.
- 9 fundos de missão, 1 estação e 4 construções.
- 9 relíquias/recursos, 12 objetos, 12 peças de HUD, 12 controles, 12 efeitos e 18 peças de terreno.
As seis folhas de coleção repetem os elementos individuais para facilitar inspeção.

## O que foi feito no Aseprite
O processamento foi executado pelo Aseprite 1.3.18.6 em modo batch, com scripts Lua, sem abrir ou controlar sua interface.
- Redução para resolução nativa com cobertura de pixels e limpeza de contaminação de borda.
- Paleta indexada compartilhada: 63 cores opacas + transparência.
- Alfa binário: todos os pixels são opacos ou transparentes.
- Corpo/materiais e luzes/detalhes separados por critério de luminosidade e cor em duas camadas editáveis. Não há separação anatômica de braços/pernas.
- Recorte individual dos 75 elementos. Os limites irregulares das folhas de objetos e terreno foram ajustados após inspeção.
- Pivôs registrados em slices e JSON.
- 24 personagens com 8 quadros de idle (125 ms) e 4 de hit (80 ms).
- 12 efeitos com 6 quadros de burst (75 ms).
- 443 quadros no total, contando também os assets estáticos e as folhas de coleção.
- PNGs, spritesheets e metadados exportados pelo fluxo de produção.

## Origem e limites
Os desenhos-base são imagens geradas por IA, não desenhos feitos à mão no Aseprite. As seis novas bases foram criadas com imagegen integrado; prompts em boss-prompts.json. As bases anteriores e seus prompts estão em masters/v02/.
A normalização, o tratamento dos pixels, as camadas e os movimentos simples foram realizados no Aseprite. Os movimentos são procedurais: compressão discreta do corpo com base fixa, pulso de luz, recuo e clarão de impacto; efeitos usam expansão e dissipação. Não equivalem a animação articulada desenhada quadro a quadro.

A produção técnica destes arquivos está entregue. Continuam pendentes:
- Caminhada, ataques, habilidades e derrota com poses articuladas próprias.
- Ajuste da direção de cada personagem para o combate e validação do ponto dos pés no jogo.
- Separar molduras e preenchimentos dinâmicos das barras de HUD e conferir nine-patch.
- Converter peças de terreno decorativas em módulos encaixáveis, se o mapa exigir tiles.
- Separar camadas de paralaxe dos cenários (os fundos atuais são achatados).
- Integração no Godot, avaliação em escala real e aceite visual do usuário.
O pacote não substituiu assets do aplicativo nem alterou suas regras. Nenhuma sessão real foi lida.

## Escalas
- Heróis, companheiros, NPCs e inimigos: canvas 128×128.
- Chefes anteriores: 192×192.
- Novos chefes: 192×192 até 288×256.
- AZHOR: 384×288.
- Fundos: 480×160.
- Construções: 160×160.
- Ícones: 32×32; relíquias: 48×48; objetos/efeitos: 64×64.
- Terreno: 96×64; HUD varia conforme função.
Importar no Godot com filtro nearest, sem filtragem suave. Evitar escala fracionária durante a avaliação visual.

## Reproduzir
Requer Aseprite com Lua; Python é usado para execução, documentação e verificação, não para editar imagens.
1. Execute produce.py com o caminho opcional do executável Aseprite.
2. Execute verify.py (Pillow requerido para leitura e verificação).
3. Execute build-gallery.py.
Os scripts usam apenas arquivos deste pacote. Consulte manifest.json para os hashes e a verificação técnica.

Referência da API utilizada: https://aseprite.org/api/

