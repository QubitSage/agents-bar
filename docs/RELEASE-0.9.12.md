# Agents Bar 0.9.12 — teste privado (Claude Code guiado)

Candidata para testadores. Não é a 1.0, não está assinada digitalmente e o Windows pode mostrar o aviso do SmartScreen ("Mais informações" → "Executar assim mesmo").

## Como testar

1. Execute `AgentsBar-Setup-0.9.12.exe` (instala para o seu usuário, sem administrador) ou extraia o ZIP e abra `Iniciar Agents Bar.cmd`.
2. O jogo abre **desconectado**. Use o modo **Livre** para jogar sem conectar nada, ou `Demonstrar Agents Bar.cmd` para ver uma demonstração com sessões fictícias.
3. Para usar o Claude Code: aba **Agentes** → **Ativar coletor** → **Instalar hooks Claude** (faz backup do seu `settings.json` e preserva seus hooks; **Remover hooks Claude** desfaz) → reinicie o Claude Code → vincule a sessão a um herói → Mapa → modo Agentes.

## Novidades

- Fluxo guiado de instalação dos hooks do Claude Code na própria HUD, com backup e remoção segura.
- Estado da conexão claro: desconectado, aguardando eventos, funcionando, aguardando permissão, sem informação suficiente.
- Contexto da sessão e tokens observados exibidos separadamente; nenhum deles é o consumo da conta.
- Combate ampliado (0.9.11) e HUD Fortaleza.

## Privacidade

Nada é enviado à internet. O coletor aceita eventos só em `127.0.0.1`. Prompts, respostas, código e caminhos não são guardados. Nenhuma conta, cobrança ou servidor está ativo.

## Limitações conhecidas

Integração com Claude Code ainda não homologada em máquina real; Codex, Cursor, Antigravity e Grok dependem de configuração manual (docs/INTEGRATIONS.md). Pro (US$ 2/mês) ainda não está à venda. Relate problemas sem enviar conversas ou chaves.
