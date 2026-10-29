# Agents Bar — instruções de trabalho

Nome provisório aprovado pelo usuário: **Agents Bar**. A pasta estacao-zero e o kit inicial mantêm seus nomes por compatibilidade; Estação Zero é o conceito visual do mundo.

## Limite de acesso solicitado pelo usuário

- Trabalhar nos arquivos e testes de código deste projeto.
- Não controlar tela, mouse, teclado ou interfaces de aplicativos.
- Não abrir aplicativos gráficos nem executar o protótipo visivelmente por iniciativa própria.
- Não ler sessões reais do Codex ou de outros agentes, nem iniciar leitores/monitores de sessões.
- Testes devem usar fixtures fictícias e, para Godot, execução headless sem instanciar o aplicativo ou consultar sessões reais.
- A validação visual fica para o usuário, salvo nova autorização explícita.

## Produto

- Iniciar desconectado por padrão. Conexão real exige escolha explícita; nunca descobrir conversas automaticamente ou reutilizar silenciosamente snapshots antigos.
- Manter modo compacto no canto com estado verdadeiro e botão de expansão. Não mostrar Trabalhando sem evidência ou fora de uma demonstração identificada.
- Não declarar sprints concluídas com validações manuais ou integrações ainda pendentes.
- Registrar trabalho e pendências em docs/SPRINT-02.md e ROADMAP.md.

- Interface definida pelo usuário: Forja, seleção de personagens, inventário, mapa e demais sistemas devem abrir dentro do próprio HUD do jogo, com referência de organização em TBH: Task Bar Hero. A janela separada de campanha da alpha 0.4.0 é provisória; não tratar esse layout como aprovado.

- Referências aprovadas: HUD/GUI modular como TBH: Task Bar Hero, com painéis internos lado a lado; conceito de funcionamento baseado em taskbaragents.com. A campanha autônoma atual é base provisória. Não inventar funcionalidades da referência nem tratar a economia/tokens como definida antes de especificá-la.

- Decisão atual 0.5.0: Pro = mais agentes simultâneos e histórico. Limites iniciais 3/24h no Free, 12/90d por US$ 2/mês. Regras de atividade e tokens especificadas em docs/GAMEPLAY-0.5.md; substituem a pendência de definição anterior. Manter acesso real às fontes explícito, sem descoberta automática.

- Decisão do usuário em 26/10/2026: deixar contas, publicação e cobrança Pro para o final. Priorizar jogo; não solicitar credenciais nem iniciar provisionamento nesta etapa. Gameplay atual em docs/GAMEPLAY-0.6.md.

- Decisão do usuário em 26/10/2026: primeiro desenhar toda a HUD e apresentar versões para escolha. Novas alterações da UI no jogo somente após aprovação explícita do desenho. Propostas em art-direction/hud-review-v01; a 0.7.0 não representa aprovação visual.

- Direção escolhida pelo usuário: HUD A — Fortaleza. Etapa atual: desenhar e revisar itens antes de implementar. Coleção inicial em art-direction/items-fortaleza-v01; não tratar esses conceitos gerados como sprites finais de produção.


- Decisão posterior do usuário: seguir pelas seis etapas completas. Implementação da HUD A Fortaleza e produção dos itens no Aseprite autorizadas; instruções anteriores de aguardar desenho/itens ficam superadas nesse escopo. Mantidos os limites de acesso: nenhum controle de interface, nenhuma sessão real, nenhum provisionamento/cobrança sem contas fornecidas. Estado atual documentado em docs/RELEASE-0.8.0.md.

- Pedido posterior: implementar tudo que for local até 0.9.9; o usuário fornecerá acessos depois. Entrega atual candidata privada 0.9.9, sem execução de GUI/contas/sessões reais. Aceites externos em docs/ACCEPTANCE-0.9.9.md.

- Exceção autorizada pelo usuário em 27/10/2026 para corrigir a abertura: instanciar a HUD apenas em cópia isolada, Godot headless, sem janela visível, com dados fictícios e sem conectar agentes. Teste dedicado: scripts/verify_startup.py. A validação visual na área de trabalho continua com o usuário.
