# Verificação 0.8.0 — 27/10/2026

## Resultado automatizado

| Grupo | Resultado |
|---|---|
| Python: tracking, protocolo, fixtures HTTP, instalador, pipeline | 55 testes, 0 falhas |
| Backend Workers/Stripe simulado + recuperação transacional SQLite | 10 testes, 0 falhas |
| Godot: apresentação | 17 verificações, 0 falhas |
| Godot: campanha/economia/save | 378 verificações, 0 falhas |
| Godot: primeira missão/timeline | 731 verificações, 0 falhas |
| Godot: integração HUD/modelo (compilação) | 26 verificações, 0 falhas |
| Godot: AZHOR/tracking | 77 verificações, 0 falhas |
| Godot: geometria/paginação/posição | 2.043 verificações, 0 falhas |
| Godot: equipamentos/migração | 64 verificações, 0 falhas |
| Godot: snapshots Python dos seis provedores → simulação | 42 verificações, 0 falhas |
| Aseprite batch | 24 fontes reabertas e comparadas pixel a pixel |

Total Godot: 3.378. O pipeline de 42 verificações é disparado por um dos testes Python. PNG 48 × 48 corresponde ao editável; PNG 96 × 96 é ampliação exata 2×; alpha só 0/255; margem mínima 4 px. A galeria HTML dos itens foi renderizada e inspecionada; ela não é screenshot do jogo.

Comando principal: `scripts/verify.ps1 -NodeExecutable CAMINHO_DO_NODE`. Usa o Python portátil e Godot console local. O teste HTTP abre somente um servidor temporário em loopback com fixtures e encerra ao terminar. `scripts/verify-items.lua` é executado em batch pelo Aseprite.

## Limites da evidência

A compilação de scripts não instancia a HUD. Geometria de regiões não comprova legibilidade de todo texto, foco, DPI ou clique/arraste reais. Nenhuma janela do jogo foi aberta. Nenhuma sessão real, hook de usuário, conta Cloudflare ou conta Stripe foi usada. Os testes de cobrança usam mocks da API e SQLite local; não provam deploy D1 ou pagamento Stripe.

Aceite pendente: roteiro visual do HUD; playtest humano; homologação dos provedores escolhidos nas versões instaladas; instalação real/atalho; Cloudflare/Stripe em ambiente de teste e posteriormente publicação. Não declarar todas as sprints encerradas comercialmente.
