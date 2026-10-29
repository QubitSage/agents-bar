# Agents Bar — Fantasy Kit v02
Data: 2026-10-26. Status: artes estáticas geradas, aguardando acabamento e aceitação visual.

Abra index.html no navegador para ver as 38 imagens por categoria, alternar o fundo e comparar os personagens em uma prévia menor. Não é necessário servidor nem conexão.

## Conteúdo
- 4 versões do protagonista: clássico, sombrio, kawaii e aventureiro persa.
- 2 companheiros: Brasa (guardião) e Luma (botânica).
- 3 NPCs: cartógrafo, artesã e colecionadora.
- 6 inimigos comuns e 3 chefes, distribuídos por três biomas.
- 9 fundos de missão: Forja em Ruínas, Jardins de Vidro e Torres da Tempestade.
- 1 fundo da Estação Zero e 4 construções separadas.
- 6 folhas: relíquias/recursos (9), objetos (12), HUD (12), controles (12), efeitos (12) e terreno (18).
As folhas contêm 75 elementos visuais, ainda não separados em arquivos individuais. As quatro versões do herói são propostas de aparência/skin, não quatro classes novas.

## Direção
Referências: os dois cavaleiros enviados pelo usuário. Armaduras de prata azulada, tecido azul, detalhes dourados, proporções compactas e luz predominante superior esquerda. Os personagens têm silhuetas distintas por papel. A linguagem medieval substitui visualmente o elenco anterior nesta proposta, com vínculos de IDs preservados apenas no inventário.

Biomas:
- Forja: pedra escura, cobre, metal e luz âmbar.
- Jardim: pedra clara, folhas, raízes e cristais verdes.
- Tempestade: torres prateadas, azul profundo e energia ciano.
A paleta sugerida ainda não é uma paleta indexada validada.

## Produção e limites
Geração com a ferramenta imagegen integrada. Prompts completos em prompts.json; a geração do Arconte recebeu uma revisão de enquadramento. Nenhum arquivo desta entrega foi redesenhado manualmente no Aseprite. PNGs são bases estáticas, não spritesheets de animação.

A inspeção das imagens confirmou as categorias e os elementos previstos, mas revelou halos de recorte coloridos, variação no tamanho dos pixels e detalhes que precisam ser simplificados na escala do jogo. A geração não garante a grade lógica ou a quantidade de cores pedida nos prompts.

Próximos trabalhos:
1. Definir a altura nativa dos personagens e aprovar a leitura na barra compacta.
2. Limpar halos, sombras residuais e pixels soltos; unificar grade e paleta no Aseprite.
3. Padronizar orientação, escala relativa, linha dos pés e pivôs.
4. Separar cada elemento dos atlas com margens consistentes; não usar divisão automática por células sem revisar.
5. Separar barras e preenchimentos de HUD; estabelecer margens de nine-patch.
6. Converter as peças de terreno em módulos que encaixem; os fundos são imagens achatadas, sem camadas de paralaxe.
7. Animar idle, deslocamento, ataque, dano, habilidade e derrota; efeitos são quadros únicos.
8. Importar no Godot e validar legibilidade, composição e consumo de memória.

O aplicativo existente não foi alterado para usar estas imagens. Não houve abertura do jogo ou de aplicativos gráficos, nem leitura de sessões reais. A revisão manual do usuário e a integração continuam pendentes; esta entrega não encerra todas as sprints.

## Arquivos
- index.html: galeria offline.
- manifest.json: inventário com caminhos relativos, dimensões, transparência, caixas alfa e hashes.
- prompts.json: prompts e metadados de geração.
- production-plan.json: plano atualizado com status.
- Pastas de PNG: apenas arquivos finais selecionados no ZIP.
As imagens de referência e a versão descartada do Arconte ficam fora do ZIP de entrega.

