# Verificação 0.7.0 — HUD e janela livre

Data: 26/10/2026. Revisão instalada em C:\Users\bruno\Desktop\All\Projetos\Tokens Bar. Fontes anteriores em runtime/source-before-0.7.0. Nenhuma interface aberta ou instanciada; nenhuma sessão real consultada.

## Testes executados

Godot 4.7.2, headless, scripts de teste sem instanciar Control/Window do aplicativo:

| Suite | Verificações | Falhas |
| --- | ---: | ---: |
| Presentation | 17 | 0 |
| Gameplay | 378 | 0 |
| First mission | 731 | 0 |
| HUD/game | 26 | 0 |
| AZHOR/tracking | 77 | 0 |
| HUD layout | 1.403 | 0 |
| Total | 2.632 | 0 |

Os testes de layout exercitam as regiões principais em 20 combinações de dimensão, ausência de interseções, paginação sem perda/duplicação até 100 registros, última página parcial, oito bordas/cantos, recuperação de páginas inválidas, geometrias negativas, monitor removido, área útil pequena, entrada persistida inválida, ida/volta entre barra e HUD e reinicialização do perfil em memória. Compilação repetida após os últimos ajustes de campos de texto.

A persistência de geometria foi exercitada por serialização/desserialização em memória. O caminho user://window.json e o arraste/resize nativo não foram executados neste teste; dependem do aceite manual descrito abaixo.

Pacote: scripts compilados, 170 entradas visuais carregadas, primeira missão e AZHOR concluídos em memória; ultimate observado. Os 304 arquivos do manifesto tiveram SHA-256 conferido. Fontes instaladas do HUD/app/geometry/canvas coincidem com o pacote.

ZIP: release/AgentsBar-0.7.0-win64.zip
Tamanho: 103953617 bytes
SHA-256: 2364fe532114463dc45b7bc3ca765e060cbd114c1828dd735386c9bbbb428602

Suites Python e servidor não foram repetidas nesta revisão: bridge, protocolos, backend e cobrança não mudaram. Resultados anteriores permanecem em VERIFY-0.6.0.md.

## Aceite pendente

A compilação e os cálculos de retângulos não comprovam aparência, layout final de todos os Controls, foco, renderização, fluidez ou interação nativa no Windows. Validar manualmente conforme docs/HUD-0.7.md, em especial 800 × 600, escalas 100/125/150%, arraste, resize, campos numéricos, recolher/reabrir e persistência em disco.

Os logs desta rodada ficam em runtime/verify-0.7.0. Nenhum teste iniciou o coletor, conectou um provedor ou executou a cena principal. Contas, deploy, Stripe e cobrança seguem adiados pelo usuário.

