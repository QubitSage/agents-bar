# Verificação — Agents Bar 0.5.0

Data: 26/10/2026. Execução restrita a código, fixtures, localhost sintético e Godot headless, sem instanciar a aplicação/UI.

| Verificação | Resultado |
| --- | --- |
| Python unittest | 44 testes aprovados |
| Backend Node | 7 testes aprovados |
| Godot apresentação | 17 verificações aprovadas |
| Godot campanha | 374 verificações aprovadas; nove missões vencidas em nove tentativas de progressão; 500 replays/15.500 passos sintéticos |
| Godot primeira missão/assets | 683 verificações aprovadas |
| Godot HUD/Forja/trabalho | 26 verificações aprovadas |
| Pacote portátil Godot | Scripts compilados, 154 assets v04 carregados, primeira missão concluída em memória |
| Pacote portátil Python | Runtime próprio importou adaptadores/SQLite e processou fixture em memória |
| Integridade | 283 entradas SHA-256 verificadas; ZIP passou testzip |

Total Godot: 1.100 verificações. São verificações automatizadas de lógica, recursos e compilação; não equivalem a uma avaliação visual do HUD.

Cobertura nova: limites Free/Pro, linha de base de tokens cumulativos, deduplicação/reinício, estados antigos/terminais, silêncio, retenção, privacidade de metadados, autenticação HTTP, rejeição de Origin, payload inválido, wrappers Windows com espaços e acentos, reserva de trabalho limitada, pausa/aprovação, modo Livre, Forja/reciclagem/recriação, assinatura RS256 JavaScript → Python, expiração/adulteração, checkout simulado, webhook assinado/duplicado e cancelamento.

Os primeiros testes no sandbox encontraram restrições de temporário e loopback do ambiente de execução; a execução final usou temporários dentro do projeto e autorização de teste localhost, com resultado aprovado. Nenhuma sessão real foi acompanhada. A validação final usou Python 3.14.10 portátil, com hash do download conferido contra o manifesto oficial, e Godot 4.7.2.

Pacote: release/AgentsBar-0.5.0-win64.zip

Tamanho: 102.542.666 bytes.
SHA-256: `15452329b39a0385c0db94b1e03142ee004e0c6a54ff7ef00b8c14378b80700e`.

Arquivos anteriores modificados preservados em runtime/source-before-0.5.0. Pacotes 0.4.0 preservados. O pacote não inclui saves, sessões, banco de tracking, chave de licença ou chave privada de assinatura.

## Ainda pendente

- Aceite visual, foco de teclado, DPI, monitores, acessibilidade e desempenho do HUD no Windows.
- Ativação escolhida e teste real de cada provedor nas versões instaladas; hooks podem variar por versão e escopo.
- Implantar Workers/D1, configurar Stripe em modo teste, confirmar o ciclo financeiro real de teste e a distribuição da chave pública.
- Recuperação autenticada de licença, políticas comerciais, assinatura/atualização do executável e piloto antes de distribuição pública.
- Integrar AZHOR e o restante do elenco como conteúdo jogável adicional; a campanha atual tem três personagens e três chefes de região.

## Reproduzir

Na raiz, executar scripts/verify.ps1 passando -PythonExecutable com o caminho tools/python/python.exe. Depois executar node --test server/test.mjs. O teste HTTP usa somente eventos fictícios e um servidor temporário em localhost, encerrado ao final. Não execute a cena principal para esta verificação de código.
