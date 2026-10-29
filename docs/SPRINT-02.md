# Sprint 2 — Agents Bar

Estado: implementação local ampliada; aceite real e interface de conexões pendentes.

## Implementado

- Barra compacta/expandida, três personagens e prioridades de atenção.
- Inicialização desconectada e demonstração identificada.
- Núcleo de até três sessões, deduplicação, eventos fora de ordem e estados terminais protegidos.
- Normalizador puro App Server e replay com dados fictícios.
- Leitor de uma sessão e leitor de até três arquivos explicitamente escolhidos por configuração.
- Isolamento por slot: uma fonte ausente não desconecta as demais.
- Leitura limitada a 1 MiB por consulta e diagnóstico sem conteúdo de mensagens.
- Encerramento do leitor pelo inicializador ao sair do jogo.
- Conclusões novas podem oferecer marcos no Diário; aceitação e descarte são deduplicados e não concedem poder de combate.

## Verificação

26 testes Python passaram. Cobrem ciclo de vida, três sessões, isolamento, replay, privacidade do snapshot, limites de leitura, duplicação e configurações inválidas. Os arquivos são fictícios. Nenhuma sessão real foi lida ou monitorada durante esta revisão.

## Pendências

- Seleção gráfica de sessões e retorno à conversa de origem.
- Transporte App Server e evidência real de espera por aprovação.
- Verificação do leitor múltiplo com fontes reais escolhidas pelo usuário.
- Foco, cliques, escalas e monitores no desktop.

Não declarar Sprint 1 ou 2 concluída enquanto os critérios de aceite reais estiverem pendentes. As restrições de trabalho continuam em `AGENTS.md`: arquivos e testes, sem controle de interface nem leitura de sessões reais.

## Arte — revisão de 2026-10-26

Criado `art-direction/fantasy-kit-v02/index.html`: galeria offline com 38 PNGs estáticos na direção medieval compacta das duas referências do usuário. Inclui quatro versões do protagonista, dois companheiros, três NPCs, seis inimigos, três chefes, nove fundos de missão, estação, quatro construções e seis folhas de elementos (75 componentes ainda não recortados).

Prompts, inventário técnico e pacote ZIP registrados junto à arte. Geração por imagegen; sem edição manual no Aseprite ou alteração de assets em runtime. Pendentes: limpeza dos halos de recorte, unificação da grade/paleta, recorte dos atlas, pivôs, animação, integração e aceite visual. Nenhum aplicativo gráfico foi aberto ou sessão real consultada.
## Arte Aseprite v03 — 2026-10-26

Entregues 119 arquivos nativos em `art-direction/fantasy-kit-v03/aseprite`: o kit anterior tratado, 75 componentes separados, seis coleções e seis novos chefes (cinco normais e AZHOR, world boss). Bases visuais por imagegen; processamento real no Aseprite 1.3.18.6 em batch: paleta indexada comum, alfa binário, grade nativa, limpeza de bordas, recortes revisados, camadas de corpo/luz e pivôs.

Inclui 24 personagens com movimentos procedurais básicos de idle/hit e 12 efeitos com burst; 443 quadros no conjunto. Arquivos reabertos pelo Aseprite em batch; comparação do primeiro quadro com os PNGs, estrutura nativa e contagens verificadas. Galeria offline e ZIP acompanham o kit. Sem abertura de interface gráfica ou integração no runtime. Ataques/caminhada articulados, HUD dinâmico, tiles encaixáveis e aceite no jogo continuam pendentes.

## AZHOR — animações v01 (2026-10-26)

Criado `art-direction/azhor-animation-v01`: 19 sequências e 470 quadros somente do world boss. Mestre Aseprite, 19 fontes individuais, spritesheets, JSONs, cinco GIFs e visualizador offline com scrub. Inclui idle, sentar/levantar, repouso sentado, mastigar, observar, dormir, espreguiçar cauda, easter egg do patinho, mordida básica, quatro especiais, ultimate, defesa, pulo, reação a dano e morte com pose final persistente.

Animações de recortes articulados executadas no Aseprite por Lua: 13 partes, 18 camadas, palette indexada e FX de pixels. Não houve nova geração de imagem, abertura de interface ou alteração do runtime. Quadros, arquivos nativos, margens e comparação de 57 renders do Aseprite com as folhas foram verificados. Aceite visual no jogo, colisões, áudio e eventos de combate continuam pendentes. Dados de eventos são propostas de integração.



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

## Primeiro Sinal — alpha 0.4.0 — 26/10/2026

A biblioteca v04 está integrada ao primeiro confronto completo no Godot: Cavaleiro e Brasa contra Vigia de Latão, Caranguejo de Cobre e Rebocador na Forja. Foram importadas 154 entradas; PNGs carregados diretamente e quadros amostrados com suas durações e pivôs. HUD apresenta vida, escudo, progresso e preparação da ação. A estação e construções usam a mesma biblioteca.

O combate da primeira missão usa uma timeline determinística: deslocamento para alcance, antecipação, dano no impacto, recuperação, defesa e morte com tempo de conclusão. O relógio e o marcador de dano aplicado fazem parte do save. Pausa congela a missão; recolher mantém avanço; vitória entrega núcleo, sucata, XP e primeira relíquia uma única vez e retorna à aba Estação. Sem recompensas por tempo fechado.

Testes headless e fixtures: 26 Python, 17 apresentação, 374 campanha e 681 primeira missão/assets aprovados. Verificados salvamento antes/depois do impacto, retomada equivalente, recompensa persistida sem segunda coleta, morte do chefe, derrota, pausa, compatibilidade com saves sem timeline e compilação da UI sem instanciá-la. Campanha em nove tentativas, 500 replays, 15.500 passos sintéticos.

As outras oito missões continuam com o combate anterior, embora usem a nova apresentação. AZHOR e o elenco completo do kit não fazem parte deste recorte jogável. Aceite visual, foco, DPI, monitores e demais itens manuais continuam pendentes; nenhuma janela gráfica ou sessão real foi acessada. Pacote portátil 0.4.0, instruções e roteiro manual atualizados. Os sprints permanecem abertos nos critérios não validados.


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

## 28/10/2026 — Claude Code (candidata, NÃO homologada)

Feito (fixtures/headless): mesclador seguro de settings com backup/remoção, evento de permissão (Notification), contexto separado de tokens, fluxo guiado na aba Agentes. Pendente de teste real do usuário: layout/clique/DPI da aba Agentes; hooks reais (SessionStart→Stop), vínculo a herói, missão avançando, uma conclusão por turno; versão do Claude Code; latência dos hooks; StopFailure/PermissionDenied só após confirmar a versão.
