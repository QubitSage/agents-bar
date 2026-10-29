# Comece a jogar — 0.9.9

1. Abra Agents Bar. Ele começa recolhido e desconectado. Clique **Abrir**.
2. Em uma campanha nova, siga **Primeiros passos → Começar em modo Livre**. Em campanha existente, o guia fica em **Menu → Primeiros passos**.
3. Acompanhe a missão na faixa de combate. **Pausar** congela a missão; **Recolher** no cabeçalho reduz a janela. A ação **Recolher** após o resultado guarda a recompensa.
4. Equipe a primeira relíquia pelo guia ou pelo Inventário. Na Forja, escolha **Aprimorar** ou **Fabricar**; equipamentos e receitas mostram custos/desbloqueios. Não é possível trocar a equipe ou equipamentos durante uma missão.
5. No Mapa, escolha outra rota disponível. Melhorar o Núcleo na Estação libera o terceiro herói da formação.
6. Para acompanhar trabalho real, abra Agentes, ative o coletor e configure apenas o provedor escolhido seguindo INTEGRATIONS.md. Vincule uma sessão a um herói da formação e escolha modo Agentes no Mapa. Instalar MCP não revela automaticamente o consumo de qualquer aplicativo.

## Janela

Arraste pelo cabeçalho. Ajuste pelas bordas ou em **Menu → Janela**. Barra e HUD guardam posição e tamanho separados. Esc recolhe/expande. Em **Menu → Preferências**, ajuste sons, movimento reduzido e Sempre acima.

## Ajuda

- Sem avanço: confira pausa, modo de expedição, vínculo e estado recebido. O modo Livre funciona sem conexão.
- Tokens indisponíveis: a fonte pode fornecer atividade sem contador de uso. O jogo não inventa o número.
- Quer parar o acompanhamento: **Agentes → Desconectar coletor**. O histórico permanece local. Leitores legados iniciados pelo launcher com `-Connect` encerram ao fechar o jogo.
- Após suspensão/interrupção longa: a missão pode voltar pausada. Confira e clique Retomar.
- Problema de progresso: **Menu → Ajuda e diagnóstico**. Salvar diagnóstico cria um JSON local sem conversas ou chaves. Recuperar backup só fica habilitado quando há cópia válida e o progresso está protegido; o original é preservado.

Progresso/geometria/diagnóstico: diretório de usuário `Agents Bar` do Godot, normalmente `%APPDATA%\Agents Bar`. Diagnóstico: `diagnostics/diagnostic.json`. Histórico do coletor: `runtime/tracking` no portátil; `data/tracking` na instalação versionada. O diagnóstico não é enviado automaticamente.

Para ver o confronto final sem alterar o save: execute `Demonstrar AZHOR.cmd`. Para sessões fictícias identificadas: `Demonstrar Agents Bar.cmd`.
