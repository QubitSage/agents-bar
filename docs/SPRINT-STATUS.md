# Estado dos seis sprints — 26/10/2026

Entrega atual: Agents Bar 0.4.0 alpha, primeira missão com biblioteca visual v04 e combate sincronizado, campanha existente preservada e pacote portátil privado. Avançou-se nas seis frentes, sem declarar os critérios manuais cumpridos.

| Sprint | Implementado e verificável em código | Ainda pendente |
| --- | --- | --- |
| 1 — Windows | Barra transparente, compacto, expansão, recolhimento, escala/monitor, estados, controle de foco solicitado no código | Foco e cliques reais; DPI/GPU; desempenho medido; viabilidade aceita |
| 2 — agentes | Até três sessões explícitas, isolamento, deduplicação, fixture/replay, limite de leitura, encerramento pelo launcher | Seletor gráfico; retorno à origem; transporte App Server; aprovação real; teste ao vivo |
| 3 — jogo | Três mapas, nove missões, três personagens, nove inimigos, combate, progressão, relíquias, quatro construções/encaixes, marcos aceitos/combinados, save | Playtest do ciclo completo e balanceamento com pessoas |
| 4 — experiência | Arte Aseprite original, cenários/inimigos/ícone, cinco abas, onboarding, sons opcionais, movimento reduzido, sinais por texto/vida | Revisão visual em Windows, teclado/foco e compreensão por usuário novo |
| 5 — robustez | Backup/migração/checksum/versão futura, estados inválidos, retomada de missão, sem avanço offline, limite de logs, instância única, diagnóstico local | Oito horas reais, suspensão/retomada, remoção de monitor, CPU/memória, interrupção do processo em ambiente de teste |
| 6 — distribuição | Pacote portátil, runtime incluído, manifest com hashes, ZIP verificado, créditos/licenças e roteiro de instalação/atualização/remoção | Máquina limpa, export otimizado, assinatura, piloto e feedback |

## Resultados automatizados

- 26 testes Python aprovados para eventos, normalização e leitores com arquivos fictícios.
- 17 verificações de apresentação aprovadas, incluindo compilação do entrypoint sem instanciá-lo.
- 374 verificações de gameplay/saves/arte/diagnóstico aprovadas, incluindo 500 replays e 15.500 passos de combate sintéticos.
- 681 verificações da primeira missão/assets aprovadas: quadros/pivôs, alcance e impacto, pausa, morte antes da transição, salvamento no meio da ação e recompensas após reabrir.
- Campanha completa em nove tentativas no cenário de teste, com evolução paga por recursos conquistados; sem injetar moeda infinita.
- Saves: escrita/substituição, backup após corrupção, migração de esquema 1, bloqueio de esquema futuro e retomada determinística de batalha.
- Verificação do pacote inclui compilação dos scripts, assets anteriores, 154 entradas v04 e primeira missão em memória, sem criar janela.

Os números de replays acelerados não equivalem a oito horas de uso, teste de memória nativa ou validação visual. A interface foi escrita e compilada; não foi executada graficamente nesta revisão.

## Decisões de produto

A campanha é independente do uso de IA. Missões concedem materiais e progressão de combate. Entregas de trabalho aceitas concedem lembranças, luzes decorativas e registros vinculados à estação. Não é necessário gastar tokens ou gerar tarefas artificiais para avançar.

O nome provisório permanece Agents Bar. Estação Zero nomeia o mundo. Não houve publicação, convite de terceiros ou sessão real acessada. O atalho já existente aponta para o inicializador do projeto, que usa os arquivos atualizados.

## Próxima etapa de aceite

Executar o roteiro em `MANUAL-TESTS.md` quando o usuário desejar testar. Corrigir problemas observados antes de chamar esta alpha de beta ou distribuir publicamente. Os itens de integração ainda ausentes permanecem no backlog, não são apresentados como entregues.
