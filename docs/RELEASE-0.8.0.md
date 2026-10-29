# Agents Bar 0.8.0 — Fortaleza

Alpha privada para Windows x64. Esta entrega implementa a direção A e conclui a rodada local das seis frentes. O aceite visual no Windows, a homologação com versões reais dos agentes e a publicação comercial continuam pendentes.

## Abrir

Na pasta do projeto, use `Iniciar Agents Bar.cmd` ou o atalho Agents Bar já existente. Começa recolhido e desconectado. Para jogar sem integração: **Abrir → Mapa → Livre → Primeiro Sinal**. Ao terminar, **Revisar e recolher**. `Demonstrar AZHOR.cmd` prepara uma batalha temporária contra o chefe final sem modificar a campanha.

No ZIP: extraia tudo antes de executar. `Iniciar Agents Bar.cmd` roda a versão portátil. `Instalar ou atualizar.cmd` instala por usuário e cria um único atalho Agents Bar. Não é necessário instalar Godot ou Python separadamente.

## Entregue

- HUD Fortaleza: formação lateral persistente, dois painéis internos, combate e navegação inferior. Sem rolagem vertical ou menus externos. Arraste pelo cabeçalho; redimensione pelas bordas ou Menu. Padrão 984 × 640, mínimo lógico 884 × 600; recolhida 360 × 92.
- 24 itens produzidos em Aseprite: arquivos editáveis separados, PNGs 48 × 48 e 96 × 96, paleta comum e transparência binária. Os conceitos gerados foram convertidos por script Lua no Aseprite; não são desenhos manuais feitos pixel a pixel.
- 12 equipamentos: seis armas e seis armaduras. Três armas iniciais; nove receitas desbloqueadas pela campanha. Equipar/desequipar, compatibilidade de classe, posse única e bônus reais. Trocas e fabricação ficam bloqueadas durante expedições.
- Seis relíquias redesenhadas. Três materiais usados na economia; outros três ficam reservados como arte, sem moedas/receitas extras nesta versão.
- Dez missões, três regiões, três heróis, três chefes regionais e AZHOR com variantes, defesa, ultimate e morte. Conteúdo adicional da galeria continua para expansões.
- Saves antigos migram para esquema 3 com armas iniciais, preservando recursos, campanha e batalha em andamento. Versões antigas devem tratar o save novo como somente leitura.
- Integrações locais preparadas para Codex, Claude Code, Cursor, Antigravity, Grok API e MCP explícito. Os testes usam fixtures; nenhuma sessão real foi conectada.
- Instalação por versões, manifesto SHA-256, atualização manual e rollback do programa. Dados locais ficam separados da instalação; não há download automático de atualizações.
- Pro: US$ 2/mês, até 12 sessões acompanhadas e 90 dias de histórico local. Free: três sessões e 24 horas. Não aumenta a formação de combate nem concede poder. Backend preparado com recuperação de chave por kit de uso único; ainda não publicado.

## Conferência

55 testes Python, 10 testes do backend e 3.378 verificações Godot passaram. As 42 verificações do pipeline Godot são executadas dentro de um dos 55 testes Python; não são 42 testes Python extras. O Aseprite conferiu os 24 editáveis contra seus PNGs. Esses resultados não substituem teste visual/nativo no Windows nem homologação Stripe.

Detalhes: `docs/VERIFY-0.8.0.md`, `docs/HUD-0.8.md`, `docs/GAMEPLAY-0.8.md`, `docs/DISTRIBUTION-0.8.md` e `docs/INTEGRATIONS.md`.

O pacote não tem assinatura digital de editor. A conferência SHA-256 detecta corrupção; não autentica por si só a origem de um download. Distribua esta alpha de forma privada. Cobrança e URLs públicas permanecem desativadas.
