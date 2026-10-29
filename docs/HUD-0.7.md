# HUD 0.7 — janela livre e menus internos

## Comportamento implementado
- Cabeçalho com área de arraste; na barra recolhida, arraste pelo retrato/texto. Botões continuam clicáveis.
- Redimensionamento nativo do Windows nas quatro bordas e quatro cantos.
- Menu > Janela: três tamanhos prontos e campos de largura/altura em pixels.
- Padrão aberto: 920 × 640. Mínimo de layout: 800 × 600; barra: 360 × 92, mínimo 320 × 84.
- Tela com área útil menor que o mínimo: janela ajustada à tela e conteúdo escalado uniformemente, sem rolagem. A legibilidade nesse caso requer teste manual.
- Posição e tamanho independentes para barra e HUD. Persistência em user://window.json, separada da campanha. Demonstrações não alteram essa preferência.
- Abrir outra seção, atualizar um agente ou avançar o combate não reposiciona a janela.
- Posições negativas de outros monitores são preservadas; restauração recupera janelas de monitores desconectados para uma área visível.

## Organização
Cabeçalho arrastável → oito abas → dois painéis internos → combate em toda a largura → ações e estado.

Heróis: seleção, retrato, treino, equipamento e formação.
Inventário: grade de seis relíquias e detalhes/equipar/reciclar.
Forja: herói/arma de um lado, receitas do outro.
Mapa: três regiões, três ou quatro missões por região; seleção antes de iniciar.
Estação: quatro construções, detalhe, melhoria, encaixe e seletor de lembranças.
Agentes: três heróis; sessões paginadas de três em três para vínculo; uso/histórico em páginas de quatro.
Diário: revisão, histórico e registro do combate, todos paginados; leitura e ações dentro do painel.
Menu: tamanho, som, movimento reduzido, mensagem atual e acesso ao Pro.

Nenhum ScrollContainer, OptionButton, PopupMenu ou janela filha é usado pelo novo HUD. Campos não abrem menu de contexto. Históricos completos permanecem acessíveis por páginas; textos de listas têm leitura detalhada quando selecionados. Rascunhos do diário e da licença sobrevivem a atualizações. A geometria usa limites explícitos; a redução de conteúdo é por seleção/paginação, e não por uma lista longa escondida.

Sprites existentes preservados. Botões usam a moldura pixel art do kit. O cenário da faixa de combate preenche a largura com repetição e recorte, sem esticar os personagens. Vida, escudo, encontro e ações têm texto separado da escala dos sprites.

## Referências consultadas
- TBH: Task Bar Hero: https://store.steampowered.com/app/3678970/TBH__Task_Bar_Hero/
- Capturas da organização em painéis, inventário e mapa: https://games.gg/tbh-task-bar-hero/guides/tbh-task-bar-hero-alchemy-guid/
- Arraste/redimensionamento nativos: https://docs.godotengine.org/en/stable/classes/class_displayserver.html

Referência de organização, sem importar assets do TBH.

## Aceite manual pendente
1. Fechar a versão anterior e abrir pelo atalho habitual.
2. Arrastar a barra para o centro, expandir, mover e redimensionar pelas oito bordas/cantos.
3. Alternar as oito abas em 800 × 600, 920 × 640 e um tamanho livre. Conferir recortes, foco e legibilidade.
4. Abrir/recolher, sair/reabrir: conferir as duas geometrias independentes.
5. Conferir Windows com escalas 100%, 125%, 150% e monitores diferentes.
6. No Demonstrar AZHOR.cmd, observar ataque, ultimate, defesa, morte, HP e recolhimento com menus abertos.
7. Em dados fictícios, conferir a última página do histórico e a revisão de uma entrega.
8. Confirmar que começar desconectado continua sem consultar conversas nem disparar coletores.

Nenhuma interface foi aberta ou instanciada para teste. Testes automatizados cobrem compilação, geometria, paginação, persistência em memória, campanha e sprites; não substituem esse aceite visual e nativo do Windows.
