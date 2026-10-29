# Verificação da entrega 0.3.0 alpha

Data: 26/10/2026. Restrição respeitada: testes de arquivos/código, sem instanciar a interface do aplicativo, controlar o desktop ou ler sessões reais.

## Código

`scripts/verify.ps1` passou com 26 testes Python, 17 verificações de apresentação e 374 verificações de campanha/persistência/arte. O teste de campanha percorreu as nove missões usando recursos ganhos no jogo e executou mais 250 replays da primeira missão, totalizando 2.500 passos sintéticos de combate nesses replays.

## Arte

`scripts/build-campaign-art.lua` executado no Aseprite em modo batch. Exportados três cenários, nove sheets de inimigos e um ícone, com fontes `.aseprite`. PNGs carregados nos testes. Dois cenários e um sheet de chefe foram inspecionados diretamente como arquivos de imagem; isso não é validação do layout no aplicativo.

## Pacote final

- Arquivo: `release/AgentsBar-0.3.0-win64-final.zip`.
- Tamanho: 86.290.548 bytes, aproximadamente 82,3 MiB.
- SHA-256: `ea0ea71a23b138ee7c734d4cb26a060e55701c6ff8d488a3053d5c56608d75b3`.
- Manifest de 53 arquivos, com tamanhos e hashes conferidos; CRC do ZIP válido.
- Pacote criado por lista explícita de arquivos. Não contém runtime de desenvolvimento, evidências, schemas, testes, cache do Godot, saves ou sessões.
- Teste separado compilou os scripts do pacote, carregou 15 referências principais de arte e concluiu a primeira missão em memória. A janela principal não foi instanciada.
- Licenças e créditos do runtime extraídos das informações incorporadas no executável Godot utilizado.

## Pendências

Ver `MANUAL-TESTS.md` e `SPRINT-STATUS.md`. Nenhum resultado automatizado acima confirma foco, cliques, layout visual, desempenho nativo prolongado, instalação limpa, integração real de três sessões ou sucesso de piloto.
