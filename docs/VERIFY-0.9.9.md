# Verificação local — 0.9.9 / 27/10/2026

| Grupo | Resultado |
|---|---|
| Python | 65 testes, zero falhas |
| Backend | 12 testes, zero falhas |
| Godot apresentação | 17 verificações |
| Godot campanha/economia/save | 378 |
| Godot primeira missão/timeline | 731 |
| Godot HUD/modelo, compilação | 26 |
| Godot AZHOR/tracking | 77 |
| Godot geometria/paginação | 2.043 |
| Godot equipamentos/migração | 64 |
| Godot onboarding/backup/interrupção | 32 |
| Godot longa duração | 526 |
| Godot pipeline Python → simulação | 42 |

Total Godot: 3.936 verificações, zero falhas. As 42 do pipeline são executadas dentro de um dos 65 testes Python. A arte mantém a produção validada da 0.8, sem alterações nesta rodada.

## Casos novos

Introdução com ações reais e recompensa única; modo somente leitura; preferência Sempre acima; detecção de delta inválido/interrupção; migração de recibos antigos; replay de recompensa após poda; backup sem sobrescrever a única cópia boa; recusa de downgrade de save futuro; encerramento autenticado do coletor com liberação da porta; preservação do SQLite; proxy desabilitado para loopback; entradas MCP inválidas; oito horas de eventos; desinstalação preservando dados/arquivos desconhecidos; recusa de pacote alterado; bloqueio de publicação sem configuração/evidência; limites de corpo HTTP.

Campanha longa: 115.200 passos de 0,25 segundo, equivalentes a oito horas simuladas; 460 missões concluídas; recibos e diário limitados; maior JSON observado 12.710 bytes. Coletor: três sessões fictícias, 8.640 eventos em oito horas simuladas, contadores exatos e retomada desconectada. Isto não mede FPS, uso gráfico ou memória da aplicação aberta por oito horas.

## Reproduzir

`scripts/verify.ps1 -NodeExecutable CAMINHO_DO_NODE` usa Python/Godot do projeto. O teste HTTP abre apenas loopback e é encerrado. Scripts Godot usam o modelo sem instanciar o aplicativo. Fontes do instalador compilam com o compilador .NET Framework do Windows. `AgentsBar-Setup-0.9.9.exe --verify-payload` confere o ZIP embutido sem criar formulário; `--extract-only PASTA_NOVA` verifica e extrai sem instalar nem abrir interfaces.

Evidência em `evidence/release-0.9.9/`. O pacote extraído é conferido pelo manifesto; o verificador Godot do pacote carrega assets e conclui primeira missão/AZHOR em memória. Hashes do ZIP/EXE ficam no relatório da entrega.

Não executado: GUI nativa, DPI, monitores, foco, SmartScreen, antivírus, instalação gráfica, sessões de agentes reais, rede de produção, D1 real ou transações Stripe. Esses itens continuam pendentes no checklist de aceite, sem aprovação automática.
