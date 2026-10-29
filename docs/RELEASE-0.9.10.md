# Agents Bar 0.9.10 — correção de abertura

Correção privada de 27/10/2026, posterior à candidata 0.9.9.

- Corrige a montagem de argumentos do inicializador no Windows PowerShell: caminhos e aspas estavam virando elementos separados, acrescentando espaços ao caminho recebido pelo Godot. Corrige também os argumentos das conexões explícitas.
- Corrige a HUD com dimensões zero: sua raiz Control está sob um Node2D, por isso passa a acompanhar explicitamente o tamanho do viewport, inclusive no redimensionamento.
- Reporta saída anormal do processo. Os arquivos CMD mantêm a mensagem de erro visível quando a abertura falha.
- Continua desconectado por padrão. Progresso pessoal, sessões e cobrança não são usados nos testes.

Abra `Iniciar Agents Bar.cmd` no projeto ou pelo atalho Agents Bar existente. Distribuição: `AgentsBar-Setup-0.9.10.exe` ou `AgentsBar-0.9.10-win64.zip`. As versões anteriores permanecem disponíveis.

Validação: seis regressões do inicializador executam o script real com programas fictícios sem janela; verificam caminhos com espaços/acentos, demonstrações, argumentos de conexão fictícia e falhas. Teste isolado de HUD cria a cena real, confere dimensões, redimensionamento, dez painéis e retorno ao compacto nos modos desconectado, demo e AZHOR (48 verificações). Os testes de HUD usam uma cópia do projeto e diretórios de dados temporários; não abrem janelas.

A aparência real, renderização por GPU, foco e DPI ainda dependem do teste visual do usuário. As pendências comerciais e de integrações reais da 0.9.9 permanecem em `docs/ACCEPTANCE-0.9.9.md`.
