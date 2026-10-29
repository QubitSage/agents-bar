# Agents Bar — roadmap e sprints

Estado atual: **alpha 0.6.0 implementada e empacotada para avaliação privada**. HUD único, dez missões com timeline animada, Forja, tracking opcional e Pro definidos. Evidências: [VERIFY-0.6.0](docs/VERIFY-0.6.0.md); regras: [GAMEPLAY-0.6](docs/GAMEPLAY-0.6.md). Aceite visual, conexões reais e publicação continuam pendentes.

## Registro histórico do planejamento

Versão 2 · 26 de outubro de 2026 · Plano e acompanhamento da alpha 0.3.0.

Atualização: **Agents Bar 0.3.0 alpha** tem campanha, combate, progressão, arte e pacote portátil implementados. O trabalho avançou nas seis frentes; critérios manuais, integração oficial e piloto continuam pendentes. O estado detalhado e as evidências estão em `docs/SPRINT-STATUS.md`. Estação Zero permanece como nome do mundo. O trabalho do assistente fica restrito aos arquivos e testes, sem controle de interface, execução gráfica do jogo ou leitura de sessões reais.

## Objetivo da primeira versão

Entregar um companion game para Windows em que uma estação habitada por robôs realiza expedições e pode acompanhar o trabalho de agentes. A campanha concede materiais e evolução; entregas aceitas concedem lembranças decorativas e história local. O jogo funciona desconectado e não recompensa consumo de tokens.

O teste central do produto: a estação continua agradável e útil depois da novidade visual inicial?

## Premissas de planejamento

- Seis sprints de duas semanas: 12 semanas de execução planejada.
- Reservar mais 2–4 semanas para problemas de integração, compatibilidade, acabamento e retorno dos pilotos. Janela de referência: 14–16 semanas até uma beta distribuível.
- Estimativa considerando uma pessoa responsável por desenvolvimento em dedicação substancial, assistência do Codex e revisões regulares de produto/arte. Não é uma previsão baseada em velocidade já medida. Reestimar após a Sprint 1; dedicação parcial altera o calendário.
- Cada sprint termina com uma build demonstrável e uma decisão sobre o próximo recorte.
- Planejar no máximo 80% da capacidade de cada sprint; os 20% restantes absorvem correções e integração. A reserva adicional de calendário cobre riscos maiores.
- Godot é a opção inicial para o runtime; Aseprite é o editor de assets. A Sprint 1 valida a escolha do runtime e a necessidade de uma camada nativa para Windows.
- Nome, identidade e mecânicas permanecem ajustáveis até a Sprint 4. Nenhuma exclusividade de marca foi pesquisada.

## Estado atual

| Frente | Estado | Evidência / limite |
| --- | --- | --- |
| Conceito do mundo | Primeira direção criada | Estação retrofuturista, cerâmica, cobre, vegetação |
| Assets | Kit inicial e campanha criados | Três personagens, módulos/HUD, três cenários, nove sheets de inimigos e ícone próprio |
| Fontes editáveis | Disponíveis | Aseprite com camadas, tags e slices; PNGs e JSONs exportados |
| Preview | Disponível | Prancha e GIF; HTML com sintaxe e referências verificadas, sem validação visual completa no navegador |
| Aplicativo Windows | Alpha implementada | Barra, janela de jogo e pacote portátil; validação visual pendente |
| Integração com agentes | Experimental e opcional | Até três arquivos explícitos testados com fixtures; App Server ainda sem transporte |
| Gameplay e persistência | Campanha implementada | Nove missões, combate, evolução e saves; testes automatizados aprovados, playtest pendente |

Kit inicial: `../estacao-zero-assets-v01/`. O kit é uma base de protótipo, não arte final aprovada.

## Escopo da beta

1. Windows 11 x64; versões e configurações de teste registradas.
2. Uma estação, três personagens e cinco módulos iniciais aproveitando o kit existente.
3. Um conector real com agente, inicialmente investigando Codex. Claude Code fica para uma versão posterior.
4. Até três sessões simultâneas distinguíveis por projeto e personagem.
5. Estados explícitos: desconectado, ocioso, trabalhando, aguardando usuário, falha, cancelado e concluído para revisão. Estados detalhados de leitura/edição/testes somente quando houver evidência no conector.
6. Dois ciclos independentes: expedição → combate → materiais → evolução; entrega de trabalho → revisão → lembrança decorativa. Tokens não concedem recursos de combate.
7. Progresso, configurações e vínculos salvos localmente.
8. Modo discreto, pausa, escala, seleção de monitor e controle de som.
9. Instalador ou pacote de distribuição documentado, com atualização e desinstalação verificadas.

Ficam fora da beta: segundo provedor, mobile, macOS, multiplayer, ranking público, conta obrigatória, sincronização em nuvem, marketplace, assinatura, conteúdo procedural por IA e editor de mods. O consumo de tokens pode ser exibido quando disponível; não determina recompensas. Animações não fazem chamadas extras de IA.

## Sprint 1 — provar Windows e integração

**Objetivo:** resolver as duas maiores incertezas antes de ampliar arte e conteúdo.

**Trabalho:**

- Criar a estrutura do aplicativo e importar um personagem e uma plataforma do kit.
- Provar janela transparente, posicionamento junto à barra, interação com o mouse e comportamento de foco.
- Testar escala de tela, dois monitores, barra com ocultação automática, troca de monitor e comportamento em tela cheia. Registrar modos suportados e limitações.
- Medir CPU, RAM e GPU em repouso e animação numa máquina de referência; definir orçamento de desempenho a partir dos resultados.
- Fazer uma investigação curta da fonte de eventos: sessões iniciadas pelo companion versus sessões já abertas em outro cliente. Não presumir que ambos são possíveis.
- Registrar um fluxo real de início, atividade e fim de tarefa; verificar como aparecem falha, cancelamento e necessidade de atenção.
- Definir um contrato mínimo de evento com provedor, sessão, projeto, ID, tipo e tempo, sem depender de prompts ou código-fonte para a animação.

**Entregáveis:** executável de prova, captura do fluxo real, matriz inicial de compatibilidade e registro das decisões técnicas.

**Concluída quando:** o personagem permanece visível sem atrapalhar a digitação, os cliques alcançam corretamente os alvos previstos e há uma fonte real de eventos documentada. Um simulador ajuda a desenvolver, mas não substitui essa prova.

**Decisão de passagem:** se o runtime não atender ao overlay, trocar ou complementar a camada nativa; se sessões externas não forem observáveis, delimitar o MVP às sessões iniciadas pela integração e revisar essa mudança de experiência antes de expandir.

## Sprint 2 — agentes tornam-se tripulação

**Objetivo:** entregar a primeira experiência útil com atividade real.

**Trabalho:**

- Implementar o primeiro adaptador e a máquina de estados dos personagens.
- Vincular projeto/sessão a personagem; representar até três sessões.
- Mostrar nome, estado e necessidade de atenção no HUD.
- Oferecer caminho claro de retorno à sessão quando suportado; documentar a alternativa quando não houver deep link.
- Separar desconexão, falha, cancelamento e sucesso; tratar eventos duplicados, retomadas e mensagens fora de ordem.
- Criar replays locais de eventos para desenvolver e reproduzir erros sem consumir IA.
- Salvar preferências básicas e vínculos; manter aprovadores e permissões no fluxo do agente. Nenhuma aprovação automática para manter a animação ativa.

**Entregável:** alpha técnica com um conector real.

**Concluída quando:** uma tarefa real atravessa início, atividade, eventual espera e conclusão; uma falha não vira sucesso; desconectar não deixa um personagem eternamente trabalhando; sessões não se misturam.

## Sprint 3 — ciclo de jogo e progresso

**Objetivo:** dar ao usuário uma razão para cuidar da estação.

**Trabalho:**

- Implementar uma expedição curta, um recurso principal e uma árvore pequena de desbloqueios.
- Permitir posicionar módulos em pontos de encaixe e decorar a estação.
- Vincular uma construção a uma lembrança de marco aceito, com nome e histórico local, sem bônus de combate.
- Distinguir tarefa concluída pelo agente de entrega aceita pelo usuário; permitir aceitar, adiar ou rejeitar.
- Impedir recompensa duplicada ao reconectar ou repetir o mesmo evento. Combinar tarefas pequenas num mesmo marco deve ser possível.
- Criar atividade ambiental durante pausas sem chamadas de IA, recompensas por ausência ou penalidade por descansar.
- Persistir progresso e introduzir versão do formato de save, escrita atômica e backup básico.

**Entregável:** alpha jogável com um ciclo completo.

**Concluída quando:** uma missão vencida permite melhorar uma construção persistente; uma entrega aceita pode ser lembrada nela; rejeitar/cancelar não concede recompensa; reiniciar preserva o mundo e repetir eventos não duplica recursos. O ciclo deve ser aceito em playtest.

## Sprint 4 — arte, HUD e primeira experiência

**Objetivo:** transformar a alpha num produto visualmente coerente e agradável.

**Trabalho:**

- Revisar os três personagens no Aseprite: silhuetas, peso, arcos, direção e transições entre ações.
- Refinar os cinco módulos e objetos existentes antes de aumentar a quantidade de conteúdo.
- Acrescentar sinais visuais de falha, desconexão e atenção; não depender apenas de cor.
- Finalizar os componentes do HUD, estados de interação, texto legível, navegação por teclado e foco visível.
- Criar onboarding curto, com modo de demonstração claramente identificado, seleção de monitor e conexão da primeira sessão.
- Implementar movimento reduzido, modo discreto, mute e sons curtos opcionais, com origem e licença registradas.
- Garantir que o jogo não roube foco e que notificações possam ser silenciadas.

**Entregável:** demonstração polida de uma experiência completa, da instalação ao primeiro desbloqueio.

**Concluída quando:** uma pessoa nova consegue conectar uma sessão e compreender o estado da tripulação sem explicação ao vivo; sprites e HUD são legíveis nas escalas suportadas; os estados de atenção são distinguíveis sem som.

## Sprint 5 — resistência ao uso diário

**Objetivo:** estabilizar o aplicativo para permanecer aberto durante o trabalho.

**Trabalho:**

- Testar suspensão e retomada do Windows, fechamento abrupto, reinício do agente, troca de rede e desconexão de monitor.
- Validar recovery do save, backup e migração entre duas versões de esquema.
- Executar sessões prolongadas, procurando crescimento contínuo de memória e acúmulo de eventos.
- Otimizar FPS, processamento e efeitos conforme os orçamentos definidos na Sprint 1; reduzir trabalho em modo pausado ou oculto.
- Testar a matriz de escalas, monitores e configurações de GPU disponível; ampliar quando o piloto trouxer hardware novo.
- Implementar diagnóstico local sem prompts, código ou credenciais; exportar somente por ação explícita do usuário.
- Revisar acessibilidade e testar a configuração limpa, sem depender das ferramentas de desenvolvimento.

**Entregável:** build candidata ao piloto, com funcionalidades congeladas.

**Concluída quando:** passa uma jornada de trabalho de oito horas na máquina de referência sem crash, perda de progresso ou crescimento contínuo de memória; orçamento de desempenho atendido; cenários de interrupção têm recuperação previsível.

## Sprint 6 — distribuição e beta fechada

**Objetivo:** colocar uma versão utilizável nas mãos de um pequeno grupo e observar uso real.

**Trabalho:**

- Preparar pacote, ícone do aplicativo, versão, notas de lançamento, créditos e instruções de instalação.
- Definir instalação, atualização manual inicial e desinstalação, preservando o save salvo quando o usuário escolher removê-lo.
- Avaliar assinatura de código e seus custos/credenciais com o responsável; não prometer distribuição assinada antes dessa dependência estar resolvida.
- Testar instalação limpa, atualização de versão anterior e desinstalação em outra máquina.
- Organizar piloto sugerido de 5–10 pessoas, após aprovação do usuário para convites e distribuição. Não enviar convites automaticamente.
- Coletar feedback voluntário sobre compreensão, distração, utilidade e vontade de manter o app aberto.
- Corrigir bloqueadores e produzir backlog de v1.1. Decidir expansão com base no uso observado.

**Entregável:** beta fechada distribuível e relatório do piloto.

**Concluída quando:** o pacote funciona em máquinas de teste, instalação/atualização preservam progresso, não há bugs conhecidos críticos de perda de dados ou bloqueio do trabalho e o feedback do piloto está registrado. Sem participantes disponíveis, a build pode estar pronta, mas o piloto continua pendente.

## Marcos e dependências

| Marco | Momento planejado | Evidência |
| --- | --- | --- |
| M0 — kit visual inicial | Já disponível | Fontes Aseprite, exports e validação |
| M1 — viabilidade | Final da Sprint 1 | Overlay + fluxo de eventos real |
| M2 — alpha técnica | Final da Sprint 2 | Sessões reais representadas por personagens |
| M3 — alpha jogável | Final da Sprint 3 | Missão → evolução; entrega aceita → lembrança persistente |
| M4 — experiência polida | Final da Sprint 4 | Onboarding, arte e HUD consistentes |
| M5 — estabilidade | Final da Sprint 5 | Teste prolongado e recuperação de interrupções |
| M6 — beta fechada | Final da Sprint 6 | Pacote testado e feedback de piloto |

A arte pode evoluir durante as Sprints 1–3, mas não deve bloquear a prova técnica. O acabamento final depende da escala e composição validadas no runtime. Distribuição depende de persistência e compatibilidade; expansão de provedores depende da estabilidade do primeiro adaptador.

## Riscos que podem alterar o plano

| Risco | Ação planejada |
| --- | --- |
| Eventos incompletos ou sem acesso a sessões externas | Resolver na Sprint 1; reduzir o fluxo suportado e explicitar limitações |
| Transparência, foco ou cliques inconsistentes no Windows | Prova inicial, matriz de hardware e camada nativa se necessária |
| Mundo distrai ou atrapalha o trabalho | Modo discreto, pausa e teste de uso prolongado |
| Progressão incentiva gastar tokens ou fragmentar tarefas | Recompensas por marcos aceitos, deduplicação e ausência de ranking de consumo |
| Arte exige mais trabalho manual que o previsto | Refinar o elenco existente e cortar quantidade de conteúdo antes de reduzir legibilidade |
| Acúmulo de telas e funcionalidades | Preservar um ciclo completo; adiar multiplayer, nuvem, segundo provedor e monetização |
| Assinatura ou participantes indisponíveis | Separar prontidão técnica de lançamento/piloto; manter dependências explícitas |

## Critério comum de conclusão

Cada sprint entrega uma build reproduzível, uma demonstração curta, critérios de aceite conferidos e bugs conhecidos registrados. Testes automatizados devem se concentrar em eventos, estados, deduplicação, progressão e persistência. Arte e comportamento do desktop exigem verificação visual e uso real. Ajustes triviais de aparência não precisam de testes que apenas repitam a implementação.

## Arte estática v02 — 2026-10-26

O kit `art-direction/fantasy-kit-v02` contém 38 imagens geradas e uma galeria offline para revisão: elenco, três biomas com nove missões, estação, construções, itens, HUD e efeitos. Os PNGs são bases estáticas; limpeza de bordas, consistência de pixel/paleta, recorte, animação e integração continuam na etapa de produção. O ZIP está em `art-direction/Agents-Bar-Fantasy-Kit-v02.zip`. Esta entrega não altera o status das validações manuais nem conclui a sprint de arte/UX.

## Próxima ação

Validar manualmente Primeiro Sinal na alpha 0.4.0: apoio e escala dos sprites, leitura do HUD, ritmo/contato dos ataques, recolhimento e retorno à estação. A primeira missão já tem a biblioteca v04 integrada e combate sincronizado. Após este aceite, levar a mesma cadência às outras missões e integrar chefes adicionais, incluindo AZHOR. Os registros abaixo preservam o histórico das entregas.


### AZHOR — prévia de mordida v02 (26/10/2026)

Entregue prévia da mordida em art-direction/azhor-sprites-v02/index.html, GIF, folha PNG 4×2 e arquivo Aseprite. São 8 poses completas geradas, montadas como cels no Aseprite, 288×208 px e 1,38 s. Verificados 8 frames distintos no GIF e arquivo nativo com 8 frames. A continuidade dos detalhes e os intermediários ainda precisam de refinamento; aprovação visual pelo usuário pendente. As demais sequências do escopo reduzido (ataques, defesa e morte) e a remoção definitiva do pacote anterior ainda estão pendentes. Esta prévia não encerra a sprint.


### AZHOR — prévia do ultimate (26/10/2026)

Disponível em art-direction/azhor-sprites-v02/ultimate.html, com GIF, folha 4×2 e Aseprite. Oito poses-chave completas, 288×256 px, 2,35 s; 8 frames distintos confirmados no GIF e no cabeçalho nativo. O efeito do eclipse cortado na quinta pose foi recomposto no Aseprite com o eclipse da quarta pose. Escala uniforme e deslocamento vertical para a levitação. Poses geradas; montagem e paleta no Aseprite. Refinamento de continuidade e validação visual pelo usuário continuam pendentes; demais animações e limpeza do pacote antigo não estão concluídas.


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

Pacote de arte: `art-direction/Agents-Bar-Visual-v04.zip`.

## Primeira missão jogável v04 — alpha 0.4.0 — 26/10/2026

Implementado Primeiro Sinal na Forja: Cavaleiro e formação existente, Vigia de Latão, Caranguejo de Cobre e Rebocador. Timeline determinística com preparação, aproximação, impacto, recuperação, defesa, dano e morte completa antes da transição. A apresentação usa pivôs/durações v04 e o mesmo alcance do cálculo de dano. HUD reflete vida, escudo e encontros; vitória permite recolher materiais, XP e relíquia e abrir a Estação.

Modo compacto mantém a simulação enquanto aberto; a pausa explícita congela ações. Save registra o golpe e se o impacto já ocorreu, com retomada sem dano/recompensa duplicados. Arte v04 também aparece na estação, construções, barra e demais missões; as outras oito missões mantêm a cadência de combate anterior. Importador reproduzível copia 154 entradas sem alterar pixels.

Verificação: 26 testes Python com fixtures, 17 verificações de apresentação, 374 de campanha e 681 específicas da primeira missão/assets, todas aprovadas. Campanha completa em nove tentativas e 500 replays determinísticos, 15.500 passos sintéticos. Nenhum aplicativo instanciado ou interface controlada. Entrega portátil em `release/AgentsBar-0.4.0-win64.zip`; detalhes em `docs/RELEASE-0.4.0.md`.

Pendente: aceite visual e de uso no Windows pelo usuário, balanceamento em playtest, extensão da timeline às outras missões, integração do restante do elenco e chefes da galeria. Esta entrega não encerra os critérios manuais dos sprints.


## Mudança de pasta — 26/10/2026

Projeto movido para `C:\Users\bruno\Desktop\All\Projetos\Tokens Bar`. Kit inicial reunido no subdiretório `estacao-zero-assets-v01`. Integridade dos 3.525 arquivos conferida por SHA256 antes dos ajustes de caminhos; 56 arquivos de caminhos atualizados e atalho Agents Bar da Área de Trabalho redirecionado. Testes headless aprovados no novo local, sem abrir a interface. Relatório em `runtime/migration-tokens-bar.json`.

## Direção de interface — HUD unificado — 26/10/2026

Definição do usuário: Forja, seleção de personagens e demais sistemas devem ficar dentro do próprio HUD, usando TBH: Task Bar Hero como referência de organização. A janela separada de campanha da alpha 0.4.0 é provisória e será substituída. Não considerar seu layout aprovado.

Referências consultadas: https://store.steampowered.com/app/3678970/TBH_Task_Bar_Hero/ e https://steamcommunity.com/sharedfiles/filedetails/?id=3734611647 . Referência para organização compacta e acesso a formação/equipamentos; preservar identidade visual própria.

Proposta de navegação apresentada na conversa: uma única superfície de jogo, faixa persistente de combate, menu de Heróis / Inventário / Forja / Mapa / Estação / Menu e um painel interno expansível acima da faixa. Seleção abre ficha e formação; Forja mostra item, comparação, custo e ação; mapa mostra rotas e missão. Diário e preferências ficam no Menu. Recolher fecha os painéis e reduz o HUD; abrir menus não pausa o combate; pausa explícita separada. Esc fecha primeiro o painel aberto. Nenhuma ação de gestão deve abrir uma segunda janela nativa.

Neste estudo, Forja significa fabricação/aprimoramento; Forja nas Nuvens continua o nome do mapa. Receitas, equipamentos, custos e dimensões finais são propostas a definir. O estudo de navegação usa valores ilustrativos e ícones de posição, não é uma nova build do jogo nem aprovação de arte final. Nenhum sistema de crafting foi implementado nesta etapa. Próximo trabalho: fechar composição visual do HUD e depois migrar a UI Godot existente para painéis internos, preservando a lógica e os saves. Validação visual pelo usuário permanece pendente.
## Referências aprovadas de produto — 26/10/2026

O usuário confirmou: HUD/GUI na direção de TBH: Task Bar Hero; funcionamento do jogo baseado em https://taskbaragents.com/. Manter estas duas referências separadas: organização de menus e linguagem de RPG compacto vêm de Task Bar Hero; vínculo entre agentes, trabalho e jogo deve ser estudado a partir de Taskbar Agents. Plataforma Windows e identidade/arte próprias permanecem.

A GUI será modular, com faixa persistente de combate e painéis internos que podem aparecer lado a lado, especialmente inventário e Forja. Esta definição substitui a proposta anterior de apenas um painel por vez. Seleção de personagem deve prever vínculo com agente/sessão; estado do agente e situação do combate devem ser legíveis separadamente. O acesso a agentes merece presença direta na navegação, não ficar escondido apenas em configurações.

A alpha atual tem campanha autônoma e integração opcional; isso é base técnica provisória, não validação do ciclo final orientado a agentes. Regras de atividade → progresso, tokens → métricas/recompensas, ociosidade e conclusão de tarefas ainda precisam de definição. Não assumir uma conversão de tokens em dano, moeda ou XP nem implementar leitura de sessões sem escolha explícita do usuário.

Limite desta pesquisa: o site Taskbar Agents não pôde ser consultado nesta revisão (ferramenta web indisponível para a URL e falha de resolução de host na tentativa HTTP). A referência foi registrada conforme instrução do usuário; funcionalidades específicas do site não foram verificadas nem atribuídas como fatos.
## Taskbar Agents — referência consultada na aba autorizada — 26/10/2026

O usuário abriu https://taskbaragents.com/ no navegador integrado e autorizou sua consulta. Foi possível ler a página e observar a prévia, superando a indisponibilidade registrada anteriormente. Esta autorização é específica para o site; não autoriza controlar outros aplicativos ou consultar sessões reais.

Observado na página: cada sessão de Claude Code/Codex representa um personagem; subagentes são reforços. O site associa leitura de arquivos a combate em movimento, edição ao ataque, testes à continuidade da onda, aprovação à intervenção do usuário e conclusão a missão pronta para revisão. Descreve boss, XP, baú e equipamentos; personagem/projeto/estado, terminal/histórico e mensagens para a sessão; quatro classes (Mago, Gladiador, Arqueiro, Clérigo). O produto anunciado é macOS 14+, próximo ao Dock, com progresso local. Também anuncia marketplace, ranking e ganhos/saques em dinheiro real. A página inclui lista de espera e demonstrações fictícias: anúncios não comprovam disponibilidade nem funcionamento de uma integração real. Nenhum agente real conectado e nenhum cadastro, instalação ou transação realizado.

Implicação para Agents Bar: faixa de combate conectada à atividade dos agentes, GUI modular de RPG acessível no mesmo HUD e implementação Windows. Refazer a hierarquia da GUI para que personagem/sessão/projeto e estados de atenção sejam centrais. A missão autônoma atual segue útil como bancada para animação e combate; não representa o ciclo final orientado a trabalho. O site não forneceu uma fórmula verificável de tokens para dano/XP: manter essa decisão em aberto. Marketplace, ranking e dinheiro real são referências observadas, não funcionalidades aprovadas para implementação no nosso projeto.

## Alpha 0.5.0 — HUD único, gameplay e tracking — 26/10/2026

Esta atualização substitui as descrições anteriores de GUI em janela separada e economia ainda indefinida. HUD único implementado com painéis internos, faixa de combate, Forja, formação, inventário, mapa, estação, agentes e Pro. As nove missões passaram para a timeline de impacto/defesa/morte. Regras iniciais em docs/GAMEPLAY-0.5.md: atividade abastece segundos limitados de simulação, tokens conhecidos dão pulso limitado, aprovação/desconexão aguarda; modo Livre independente.

O usuário escolheu Pro com mais agentes simultâneos e histórico. Limites iniciais implementados: Free 3/24h, Pro 12/90d por US$ 2/mês. Coletor local SQLite, hooks de Codex/Claude/Cursor/Antigravity, relay Codex opcional, adaptador Grok API e MCP explícito. Python portátil incluído. Configurações são geradas para revisão; nenhuma sessão real conectada.

Backend Workers/D1/Stripe preparado com checkout, webhooks verificados, portal e licença assinada. URLs públicas e contas não configuradas; nenhuma cobrança feita. Testes de lógica e mocks aprovados; resultado consolidado em docs/VERIFY-0.5.0.md. Critérios de aceite visual, integrações nas versões instaladas, teste Stripe real em modo teste, recuperação de licença e publicação continuam pendentes. As sprints não estão declaradas encerradas.


## Alpha 0.6.0 — AZHOR e estabilidade — 26/10/2026

Encontro final AZHOR implementado e liberado após storm-3. Dez missões, 170 entradas visuais; sprites existentes importados sem edição. Ataque básico, quatro variantes, defesa, ultimate, duas fases, dano no quadro definido e morte completa antes de recompensa. Demonstrar AZHOR.cmd abre uma equipe temporária com resultado testável sem alterar o save normal.

Tracking: reinício exige nova evidência; somente a formação atual abastece a expedição; reconexão/vínculo limpa a linha de base; snapshot do coletor é associado ao processo iniciado pelo jogo. Renovação de licença separada do heartbeat e expiração dos limites conferida sem aguardar rede.

O usuário decidiu deixar contas Cloudflare/Stripe, publicação e cobrança para o final. Nenhuma conta acessada, deploy ou pagamento realizado. Relatório automatizado em docs/VERIFY-0.6.0.md; aceite visual e sessões reais permanecem pendentes. Não considerar todas as sprints ou distribuição comercial concluídas.

## Alpha 0.7.0 — rework do HUD e janela livre — 26/10/2026

Solicitação do usuário: arrastar, redimensionar e conter toda a UI no próprio menu, sem rolagem. Implementados: cabeçalho arrastável, oito bordas/cantos de resize nativo, três presets e largura/altura no Menu. Barra e HUD guardam geometria independente; reconstruir painéis não reposiciona a janela. Restauração cobre coordenadas negativas e monitor desconectado.

Rework com oito abas, dois painéis internos, grades de relíquias, regiões/missões selecionáveis e listas paginadas de sessões/histórico/diário. Sem ScrollContainer, OptionButton ou janelas filhas. Combate ocupa toda a largura, com métricas legíveis separadas da escala dos sprites. Rascunhos sobrevivem às atualizações. Campanha e assets preservados.

Padrão aberto 920 × 640, mínimo lógico 800 × 600; detalhes e roteiro de aceite em docs/HUD-0.7.md. Compilação e testes puros de geometria/paginação/persistência em memória passaram; validação nativa de arraste, resize, DPI, foco e visual continua pendente conforme limite de acesso do AGENTS.md. Nenhuma janela aberta e nenhuma sessão real consultada. Contas/publicação/cobrança seguem para o final. Não considerar todas as sprints encerradas.

## HUD — desenho antes da implementação — 26/10/2026
O usuário pediu para primeiro desenhar toda a HUD e apresentar versões antes de implementar. A 0.7.0 permanece como protótipo técnico, sem aprovação visual. Nenhum arquivo do jogo foi alterado nesta revisão. Novas alterações de interface no jogo dependem da aprovação explícita do desenho.

Propostas em art-direction/hud-review-v01/index.html: A Fortaleza (três áreas, RPG clássico), B Travessia (dois painéis, mais compacta), C Comando (navegação lateral, sessões persistentes). Cada proposta tem 12 telas e variações de desconexão, atenção, falha, vitória e barra recolhida. Dados fictícios. As 36 telas foram conferidas em renderização HTML headless; sem overflow nos painéis auditados, imagens ausentes ou erros de JavaScript. Isso é validação da apresentação visual, não do runtime Godot.

Próximo passo: usuário escolher base e ajustes, consolidar o desenho e só então autorizar implementação. Pro, contas e cobrança continuam para o final.

## HUD A escolhido — coleção inicial de itens
O usuário preferiu a proposta A — Fortaleza e pediu o desenho dos itens. Criada coleção de 24 propostas: seis armas, seis peças de armadura, seis relíquias existentes redesenhadas e seis materiais (três atuais, três sugestões). Apresentação em art-direction/items-fortaleza-v01/index.html, quatro PNGs RGBA e catálogo com nomes e prévia em slots de 48 px.

Arte gerada com image_gen integrado, ainda não produzida no Aseprite. Aprovação dos desenhos, redução/limpeza final, recortes individuais e fontes editáveis continuam pendentes. Nenhum asset de runtime, receita, estatística ou código do jogo foi alterado. A escolha da base A direciona os estudos; o pedido atual continua sendo desenho antes da implementação.


## Seis etapas autorizadas — alpha 0.8.0 / 27/10/2026

O usuário autorizou seguir pelas seis etapas completas e informou o caminho do Aseprite. Essa autorização libera a implementação da direção A — Fortaleza e dos itens já apresentados.

1. Itens: 24 fontes Aseprite e PNGs 48/96 produzidos e validados por roundtrip; revisão estética final no jogo pendente.
2. HUD: direção A consolidada em três áreas de conteúdo, combate, navegação inferior e janela móvel/redimensionável. Roteiro de aceite em HUD-0.8.md.
3. Implementação: inventário de 12 equipamentos, nove receitas novas, slots/compatibilidade, bônus, migração de saves e ícones integrados. Sem instanciar a interface para testar.
4. Conteúdo: três heróis, três mapas, dez missões, três chefes regionais e AZHOR. Seis relíquias e três moedas. Outros três materiais são somente arte reservada. Primeira calibração determinística; playtest pendente.
5. Verificação: 55 testes Python, 10 backend, 3.378 verificações Godot e 24 editáveis Aseprite aprovados. Pipeline dos seis provedores usa fixtures. Validação visual/nativa e conexões reais não realizadas.
6. Distribuição/Pro: pacote 0.8.0, instalador por usuário, atualização manual, rollback e dados separados. Backend com recuperação da chave por kit. Cloudflare/D1, Stripe, assinatura de editor e publicação não executados: contas/configurações continuam indisponíveis.

Estado: alpha local pronta para avaliação; as seis frentes avançaram, mas os critérios externos/manuais ainda impedem declarar todas as sprints encerradas. Relatório detalhado em docs/VERIFY-0.8.0.md e docs/RELEASE-0.8.0.md. Nenhuma configuração de terceiros, sessão real ou cobrança foi acessada. O jogo permanece desconectado por padrão.


## Candidata privada 0.9.9 — 27/10/2026

Pedido: implementar até a 0.9.9, deixando acessos/contas para o usuário fornecer depois. Mantidos os limites de não abrir interfaces nem ler sessões reais.

Implementados: guia de primeira missão dentro da HUD; Ajuda/diagnóstico/recuperação confirmada; preferências separadas e Sempre acima; confirmação de retirada; pausa após interrupção longa; desconexão autenticada do coletor; proteção contra proxy externo; validação MCP/licenças; save esquema 4 com histórico de recibos limitado e deduplicação monotônica; redução de serialização por frame; limites de pedidos do backend; desinstalação conservadora; instalador gráfico .exe com payload verificado; checklist e gate de publicação.

Validação local: 65 testes Python, 12 backend, 3.936 verificações Godot. Oito horas simuladas: 460 missões, save máximo 12.710 bytes; coletor com 8.640 eventos fictícios. Fontes do instalador compiladas e payload verificado/extraído por CLI sem GUI. Dados de arte/campanha da 0.8 preservados.

Estado: 0.9.9 privada pronta para revisão. Critérios reais ainda pendentes: GUI/DPI/foco, performance gráfica, playtest humano, instalação nativa, provedores reais, Cloudflare/D1/Stripe, certificado e conteúdo comercial. Não declarar 1.0 publicada ou sprints comerciais encerradas. Evidência em docs/VERIFY-0.9.9.md e evidence/release-0.9.9; roteiro em docs/ACCEPTANCE-0.9.9.md.

## Correção de abertura 0.9.10 — 27/10/2026

Corrigidos argumentos do inicializador Windows e dimensões zero da HUD sob Node2D. Acrescentadas regressões do inicializador e teste da cena real em cópia isolada headless, autorizado pelo usuário. Sem dados pessoais, agentes ou janela visível. Aceite visual e critérios comerciais continuam pendentes. Detalhes em docs/RELEASE-0.9.10.md.

## Combate legível 0.9.11 — 27/10/2026

Referência oficial TBH revista após captura do usuário. Cena ampliada, atores cerca de 3–4× maiores no preset padrão, cenário sem repetição, margem para todas as poses e presets atualizados. Menus internos e espaço de conteúdo preservados. Comparação em art-direction/battle-scale-v01/index.html. Validação lógica/headless; aceite visual ainda pendente.

- [ ] Claude Code: homologar com instalação real (fluxo guiado na HUD pronto como candidato; ver docs/INTEGRATIONS.md e docs/SPRINT-02.md). Depois: Codex, Cursor, Antigravity, Grok.
