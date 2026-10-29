# Verificacao - Agents Bar 0.6.0

26/10/2026. Codigo/fixtures/localhost sintetico e Godot headless; nenhuma interface ou sessao real instanciada.

| Suite | Resultado |
| --- | --- |
| Python | 46 testes aprovados |
| Node - cobranca simulada/assinatura | 7 testes aprovados |
| Godot apresentacao | 17 verificacoes |
| Godot campanha | 378 verificacoes; dez missoes vencidas em dez tentativas |
| Godot primeira missao/recursos | 731 verificacoes |
| Godot HUD/Forja | 26 verificacoes |
| Godot AZHOR/tracking | 77 verificacoes |

Total Godot: 1.229 verificacoes, zero falhas. A suite de combate inclui 500 replays/15.500 passos sinteticos.

Pacote: scripts compilados, 170 entradas visuais carregadas, primeira missao e AZHOR concluidos em memoria. A demonstracao passou pelas duas fases e usou ultimate. Os 16 sheets de AZHOR sao identicos em bytes aos aprovados na galeria; nenhum pixel foi editado nesta revisao.

Cobertura nova: sete acoes do boss, quadro exato de impacto, dano em um alvo/em area, defesa, impedir dano repetido, salvar/reabrir durante ultimate, morte completa antes do resultado, recompensa unica, demonstracao isolada da campanha, restricao de formacao/vinculos, reconexao sem premiar historico, rejeicao de snapshot futuro, reinicio do coletor desconectado e expiracao Pro.

Manifesto do pacote: 301 entradas SHA-256 conferidas. Python isolado do pacote importou e executou o coletor em memoria. ZIP: 103946066 bytes. SHA-256: `1f43b3d9dad768747a5ca433fb45c8e602f33f11909fac64933c59d151724133`.

Arquivos anteriores alterados preservados em runtime/source-before-0.6.0. Pacotes 0.5.0 e anteriores preservados.

## Pendencias deliberadas

- Aceite visual, DPI/foco, desempenho e playtest humano, conforme limite de acesso definido pelo usuario.
- Conexao/teste de cada provedor real apenas por escolha explicita.
- Contas, publicacao e cobranca adiadas pelo usuario para o final. Nenhuma conta acessada, deploy ou pagamento efetuado.
- Demais personagens/chefes da galeria ainda podem virar conteudo adicional; a campanha atual tem tres herois, tres chefes regionais e AZHOR local.

Reproduzir: scripts/verify.ps1 com -PythonExecutable apontando tools/python/python.exe; node --test server/test.mjs. Para a integridade do pacote, conferir manifest.json. Nao executar a cena principal como parte da verificacao de codigo.
