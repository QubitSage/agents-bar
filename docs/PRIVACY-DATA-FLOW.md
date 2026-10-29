# Fluxo de dados — base para revisão de publicação

Documento técnico da 0.9.9. Ainda falta inserir responsável, contato de suporte e definições comerciais; não é uma política pública final.

## Local

Progresso, preferências e geometria ficam no diretório de usuário do jogo. O coletor é opcional e começa desconectado. Hooks/MCP recebem metadados fornecidos pelo provedor escolhido; os adaptadores mantêm provedor, identificadores necessários à deduplicação, modelo, estado, tipo de atividade e contadores. IDs de sessão usados no snapshot são derivados por hash. Esse hash é pseudonimização, não garantia de anonimato.

Campos de prompt, resposta, conteúdo de arquivo, argumentos de ferramenta, e-mail e caminho de projeto não entram no snapshot/histórico do coletor. O observador não transmite o payload a um serviço externo: usa somente loopback autenticado e ignora proxies HTTP do ambiente.

Free mantém até 24 horas de eventos; Pro válido permite 90 dias. Ao perder o Pro e voltar ao Free, o histórico além da retenção Free pode ser removido pelo coletor; reativar não recupera registros já excluídos. Fechar/desconectar não apaga progresso ou o histórico ainda dentro da retenção. Não há sincronização de histórico com o servidor de cobrança.

O diagnóstico é criado apenas ao clicar Salvar diagnóstico local. Contém versão, contagens e estado do jogo; não inclui conversas, títulos do diário, IDs de sessão ou chaves. Não é enviado automaticamente.

## Cobrança, quando publicada

Worker/D1 armazena hashes de chave/recuperação, identificadores de cliente/assinatura, status, vencimento e deduplicação de webhooks. Stripe recebe os dados fornecidos diretamente no checkout/portal. O backend não recebe histórico de tokens, conversas ou progresso. Tráfego e logs da infraestrutura precisam da revisão operacional antes de publicação; configurar coleta mínima e retenção apropriada.

Chave e kit de recuperação dão acesso à assinatura: guardar privadamente. Sem ambos, a recuperação exige suporte ainda a definir. Licenças assinadas já emitidas podem valer por até 24 horas após cancelamento/rotação enquanto o cliente está offline.

## Controle

Desconectar pelo HUD encerra o coletor próprio. Remover os snippets interrompe os observadores nos clientes. A desinstalação preserva dados; exclusão de dados e solicitações referentes à cobrança precisam de procedimento específico antes da 1.0. Nenhuma telemetria de gameplay é enviada automaticamente por esta versão.
