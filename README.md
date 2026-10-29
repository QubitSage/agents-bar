# Agents Bar — 0.9.12

**0.9.12:** fluxo guiado do Claude Code na HUD (hooks com backup), status de conexão claro e contexto separado de tokens. [Notas](docs/RELEASE-0.9.12.md) · [Página](docs/index.html). Instalador e ZIP em Releases; o Windows pode alertar porque ainda não há assinatura digital.

**Para compilar a partir do código:** coloque o Godot 4.7.2 Windows em `tools/godot/` (não versionado), rode `scripts/verify.ps1`, `scripts/package.py` e `scripts/build_installer.ps1`.

Candidata privada à 1.0 para Windows. Abra `Iniciar Agents Bar.cmd` ou o atalho Agents Bar existente. A introdução fica em **Menu → Primeiros passos** e inicia uma missão real em modo Livre, sem conexão.

O HUD Fortaleza reúne jogo, inventário, Forja, formação, mapa, agentes, ajuda e preferências. Arraste/redimensione a janela, recolha a barra e escolha Sempre acima no Menu. Progresso e histórico ficam locais; acompanhamento exige ativação explícita.

Combate ampliado: [notas da 0.9.11](docs/RELEASE-0.9.11.md) e [comparação visual](art-direction/battle-scale-v01/index.html).

Correção de abertura: [notas da 0.9.10](docs/RELEASE-0.9.10.md). Corrige argumentos do inicializador e tamanho zero da HUD.

Novidades da 0.9.9: guia inicial, desconexão do coletor, confirmação de retirada, diagnóstico/recuperação de backup, pausa após interrupção, save com tamanho limitado, instalação gráfica e desinstalação preservando dados.

- [Como começar](docs/QUICKSTART-0.9.9.md)
- [Notas da 0.9.9](docs/RELEASE-0.9.9.md)
- [Instalação e manutenção](docs/DISTRIBUTION-0.9.9.md)
- [Testes e limites](docs/VERIFY-0.9.9.md)
- [O que validar antes da 1.0](docs/ACCEPTANCE-0.9.9.md)
- [Integrações](docs/INTEGRATIONS.md)
- [Fluxo de dados](docs/PRIVACY-DATA-FLOW.md)

Em release/: instalador `AgentsBar-Setup-0.9.11.exe` e ZIP portátil `AgentsBar-0.9.11-win64.zip`. Versões anteriores e fontes da arte preservadas. A assinatura digital e a publicação do Pro continuam pendentes; não existe cobrança ativa nesta build.

Validação base: 65 testes Python, 12 backend e 3.936 verificações Godot sem instanciar o aplicativo. A correção adiciona seis testes do inicializador e 48 verificações da HUD real em cópia isolada headless. GUI nativa, sessões reais e infraestrutura externa ainda precisam de homologação. A 0.9.9 não equivale a uma 1.0 comercial publicada.
