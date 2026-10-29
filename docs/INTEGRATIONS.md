# Integrações — candidata 0.9.9

Os adaptadores foram implementados e testados com fixtures. Nenhuma conta, configuração de agente ou conversa real foi acessada ou conectada nesta entrega.

## Ativar explicitamente

1. Abra o jogo normalmente. Em Agentes, clique em **Ativar coletor local**. Ele aceita eventos apenas em `127.0.0.1:43127`, com token local; não abre uma porta para a rede.
2. Execute `Preparar integracoes.cmd`. Ele gera arquivos em `integrations/` para a localização atual do pacote. Não altera configurações de terceiros.
3. Escolha o provedor e mescle o snippet no arquivo indicado abaixo. Preserve hooks existentes. Revise as permissões no próprio aplicativo; as versões instaladas precisam oferecer esses eventos.
4. Abra/inicie uma sessão nesse provedor e realize uma ação. No jogo, vincule a sessão recebida a um herói, antes de iniciar a missão. Sem vínculo, a atividade não move a equipe.
5. Escolha Mapa → modo Agentes. Para testar sem configurar provedores, use Livre ou o inicializador de demonstração.

Fechar o jogo encerra o coletor que ele iniciou. A próxima abertura começa desconectada; ative-o novamente. Para remover a integração, remova apenas os handlers Agents Bar das configurações que você mesclou. Após mover/extrair o pacote em outra pasta, gere os snippets novamente.

## Cobertura por fonte

| Fonte | Caminho implementado | Uso de tokens |
| --- | --- | --- |
| Codex | `codex.hooks.snippet.json` → hooks nativos; opcional `codex_relay.py` para um App Server iniciado pelo cliente integrador | Hooks: indisponível. Relay: incrementos de `thread/tokenUsage/updated` |
| Claude Code | `claude.settings.snippet.json` → hooks em settings; observador opcional do statusline | Totais de entrada/saída quando o statusline os fornece |
| Cursor | `cursor.hooks.snippet.json` → hooks da versão instalada | Indisponível nos hooks usados |
| Antigravity | `antigravity.hooks.snippet.json` → definição nomeada em `.agents/hooks.json` | Indisponível nos eventos usados |
| Grok API | Chamar `bridge/grok_usage.py:record_response` com a resposta concluída e ID explícito da sessão | Campo `usage` da resposta; deduplicação pelo ID da resposta |
| Outros clientes MCP | `mcp.snippet.json` → servidor stdio; ferramenta `report_activity` | Não mede automaticamente tokens |

MCP é um canal explícito para o agente relatar estado. Instalar um MCP não dá acesso universal ao consumo do cliente. O relay Codex observa apenas o subprocesso App Server que ele inicia; não se conecta invisivelmente à sessão do aplicativo desktop. Não use hooks e relay para contabilizar a mesma fonte de atividade sem antes validar duplicidade entre os dois canais.

Codex aceita `~/.codex/hooks.json` ou `<projeto>/.codex/hooks.json`; exige revisão/confiança nos hooks. Claude recebe o fragmento `hooks` no escopo de settings escolhido. Cursor recebe seu arquivo de hooks no escopo suportado pela instalação. Antigravity usa uma definição `agents-bar` no nível superior do arquivo, sem substituir outras definições. Consulte as documentações oficiais para o escopo e eventos da versão instalada.

O snippet de statusline Claude é uma referência de observação, não uma substituição pronta para a sua linha visual: `hook.py` deliberadamente não escreve nada em stdout. Se já usa statusline, o wrapper precisa encaminhar o mesmo JSON ao observador e manter a saída do renderer existente. Nenhum statusline foi substituído automaticamente.

Exemplo Grok no código que já chama a API: importe `record_response` de `bridge/grok_usage.py` e passe `record_response(response, session_id="meu-projeto", directory="CAMINHO/runtime/tracking")` depois da resposta. Para streaming, forneça a resposta final com `usage` e ID estável. Isso não acompanha o site/chat Grok. O jogo não recebe a chave xAI.

## Dados e limites

SQLite local: `runtime/tracking/usage.sqlite3`. Snapshot sanitizado: `session-state.json`. Os hooks recebem os campos que o cliente envia, mas o adaptador mantém apenas IDs, provedor, modelo, estado, tipo de atividade e contadores. Prompts, respostas, argumentos de ferramentas, código e caminhos de projeto não são persistidos no tracking nem enviados ao servidor de cobrança. A chave/token local não deve ser compartilhada.

O contador cumulativo começa com uma linha de base. O histórico representa incrementos observados, não consumo anterior à instalação, custo em dinheiro ou fatura oficial. Aprovação depende de evento explícito; quando a fonte não informa aprovação, o estado só passa a desconhecido após silêncio. Terminação do loop Antigravity é tratada como ociosidade, não sucesso comprovado. Subagentes geram sinal de reforço, mas não são todos descobertos automaticamente como sessões independentes.

O leitor de arquivos legado continua opcional em `start.ps1 -Connect`, documentado em CONNECTIONS.md. Ele não oferece todos os contadores do coletor novo. Não foi ativado nesta entrega.

Fontes consultadas em 26/10/2026: [Codex hooks](https://learn.chatgpt.com/docs/hooks), [Codex App Server](https://learn.chatgpt.com/docs/app-server), [Claude hooks](https://code.claude.com/docs/en/hooks), [Claude statusline](https://code.claude.com/docs/en/statusline), [Cursor hooks](https://cursor.com/docs/hooks), [Antigravity hooks](https://antigravity.google/docs/hooks), [xAI usage](https://docs.x.ai/developers/cost-tracking).


Na instalação versionada 0.8, prepare os snippets usando `Agents Bar.ps1 -Prepare`, conforme DISTRIBUTION-0.8.md. O coletor usa a pasta estável `data/tracking`; a versão portátil conserva `runtime/tracking`. Teste cruzado adicional: os snapshots fictícios dos seis adaptadores alimentam o modelo Godot, com bloqueio de dados antigos e reinício de baseline ao trocar vínculo. Não é homologação em clientes reais.


Na 0.9.9, o botão Ativar coletor vira Desconectar coletor. A desconexão encerra o processo próprio por pedido local autenticado, preserva o banco e limpa o crédito da expedição. Nenhum novo trabalho é concedido até conexão, vínculo e evidência nova. O observador loopback não herda proxy HTTP externo. Integrações reais continuam pendentes do aceite nas versões escolhidas pelo usuário.


## Claude Code — mesclagem segura (28/10/2026, não homologada)

`scripts/claude_settings.py --settings CAMINHO` mostra o que seria feito (dry run). Com `--apply` grava um backup `.agents-bar-AAAAMMDD-HHMMSS.bak` antes de mesclar; é idempotente, preserva hooks e chaves existentes, nunca substitui uma `statusLine` já configurada (`--statusline` só instala se não houver) e `--remove` retira apenas entradas do observador Agents Bar. O caminho do settings é sempre explícito; nada é descoberto.

Novos: `Notification` com `notification_type=permission_prompt` vira "aguardando permissão" (`idle_prompt` é ignorado); `PostToolUseFailure` registrado. O snapshot passa a trazer `contextPercent` (preenchimento da janela de contexto, vindo do statusline) separado de `totalTokens` e marcado `tokenScope: session-observed`. Ambos descrevem uma sessão, nunca o consumo da conta. `StopFailure` e `PermissionDenied` estão mapeados, mas não registrados até confirmar a versão instalada do Claude Code.

Verificação em 28/10/2026: o `settings.json` do usuário (somente as chaves hooks/statusLine, com autorização) não tinha hooks nem statusLine. Versão do Claude Code ainda não confirmada. Pendente: fluxo guiado na HUD, vínculo sessão→herói pela HUD, teste real.

### Fluxo guiado na HUD (Agentes) — 28/10/2026

1. **Ativar coletor** (sempre desconectado ao abrir). 2. **Instalar hooks Claude**: gera os snippets para a pasta atual e mescla em `%USERPROFILE%\.claude\settings.json` pelo `claude_settings.py` (backup primeiro; arquivo ilegível = nada gravado; botão vira **Remover hooks Claude**; indisponível na demonstração e durante missão ativa). A HUD só passa a saber se os hooks estão instalados depois de uma ação sua; não lê o settings sozinha. Sessões já abertas precisam reiniciar. 3. Faça uma ação no Claude Code e **vincule a sessão ao herói** na lista. 4. Mapa → modo Agentes.

Linha de status (painel direito): Desconectado · Coletor ativo, aguardando eventos · Funcionando · Aguardando sua permissão · Sem informação suficiente · Conectado, em descanso. Por sessão: "Contexto N%" e "N tokens nesta sessão" (ou "indisponível"), nunca consumo da conta.

Verificação: testes Python/Godot lógicos e criação isolada headless da HUD com dados fictícios. Layout e clique reais no Windows seguem para o usuário; o Claude Code real não foi exercitado.
