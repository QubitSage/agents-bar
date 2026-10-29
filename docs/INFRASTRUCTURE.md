# Infraestrutura e publicação

## Arquitetura entregue

O combate, sprites, saves e histórico rodam no Windows. Godot executa o jogo; Python portátil executa o coletor opcional e SQLite local. Não precisamos de servidor de batalha, banco de prompts, chave de inferência compartilhada ou API paga de IA para o jogo funcionar.

O backend em `server/` foi preparado para Cloudflare Workers + D1 + Stripe Checkout/Billing. Responsabilidades: criar checkout de US$ 2/mês, receber webhooks assinados, manter estado de assinatura, emitir licença RS256 de curta duração e abrir o portal de cancelamento/cobrança. O cliente fixa a chave pública; a chave privada fica somente no servidor. Uso dos agentes e progresso não são sincronizados com esse backend.

## Necessário para publicar

- Conta Cloudflare com Workers e D1; URL HTTPS do Worker ou domínio próprio.
- Conta Stripe habilitada para o responsável pelo produto, preço recorrente **USD 200 centavos / mês**, portal de cliente e endpoint de webhook.
- Segredos `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `LICENSE_PRIVATE_JWK`; IDs públicos no wrangler.toml e online.json.
- Revisão comercial: identificação do vendedor, suporte, política de cancelamento/reembolso e privacidade; os dados de pagamento ficam no checkout hospedado da Stripe.
- Recuperação implementada na 0.8: kit privado contém chave e código de recuperação de uso único. O código troca ambos os segredos em uma transação, mantendo a assinatura. Apenas hashes ficam no D1. Testes locais cobrem replay e falha transacional. Ainda é necessário homologar o fluxo no D1/Stripe e definir suporte para perda de ambos. Compartilhar a chave permite gerenciar a assinatura; compartilhar o kit permite recuperá-la.
- Testar pagamento, renovação, falha, cancelamento e expiração em **Stripe test mode** antes de habilitar cobrança real. Os testes automatizados entregues usam mocks, não Stripe real.

Nenhum serviço foi provisionado, assinatura criada ou pagamento realizado. `online.json` mantém as URLs vazias; o jogo explica que a cobrança ainda não foi publicada. O código de checkout falha fechado quando a configuração essencial está ausente.

## Operação

O banco guarda hash da chave, IDs de cliente/assinatura, estado, vencimento e IDs de webhook. Webhooks são verificados por HMAC, têm janela de 5 minutos e deduplicação; o serviço consulta o estado atual da assinatura para reduzir problemas de eventos fora de ordem. Checkout exige o preço exato. Rotas públicas têm binding de limitação de requisições. Origem cruzada é rejeitada. Erros não registram payloads ou segredos.

A licença é renovada aproximadamente a cada hora e pode manter o Pro até seu vencimento assinado (máximo 24 horas), inclusive durante uma indisponibilidade. Cancelamento imediato pode, portanto, levar até esse período para refletir em um cliente offline. Sem licença válida o cliente retorna ao Free. Como o jogo é local, isso não pretende ser DRM inviolável nem sistema antifraude para prêmios em dinheiro.

Para produção: alertas de erros, backup/restauração D1, rotação planejada da chave de assinatura com atualização do cliente, teste de carga, builds assinadas para Windows e atualização segura. Multiplayer, ranking global, marketplace e recompensas financeiras não fazem parte desta alpha.

## Orçamento inicial

Planejamento: usar Workers/D1 no piloto e reservar **a partir de US$ 5/mês** para o plano pago Workers, além do domínio e taxas de cobrança. As cotas gratuitas podem atender testes pequenos, mas dependem dos limites e bindings do plano. Não é orçamento fechado: tráfego, leituras/escritas e observabilidade mudam a conta. [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/).

US$ 2 é receita bruta por assinante. A taxa fixa de cartão pesa nesse ticket. O ponto de equilíbrio é `custo mensal / (2 USD − taxas de pagamento/Billing − impostos − custo variável)`. País da conta, câmbio, moeda de liquidação e pagamentos internacionais precisam ser definidos para calcular a margem. Conferir a tabela do país da empresa, incluindo [Stripe Brasil](https://stripe.com/br/pricing) e [Stripe Billing](https://stripe.com/br/billing/pricing), antes de lançar. Não prometemos margem líquida sem essas informações.


## Fechamento da 0.8

A camada local não exige servidor de jogo. Publicação exige configurar Workers/D1, Stripe e chave RSA. `scripts/release_readiness.py` inspeciona somente os campos públicos do projeto; não consulta credenciais ou contas. Nesta entrega retorna pendências, pois URLs, banco, preço e chave pública não foram configurados.

Procedimento de homologação: criar D1 e aplicar `server/schema.sql`; definir o preço mensal em modo de teste; configurar portal Stripe e webhook; cadastrar segredos no Worker; publicar HTTPS; inserir URL e chave pública no cliente; gerar uma nova build. O schema cria também `license_recovery` de forma aditiva. Não coloque a chave privada no cliente ou no repositório.

Aceite em ambiente de teste: checkout → pagamento confirmado → licença Pro; renovação; pagamento falho; cancelamento no fim do período; cancelamento imediato; expiração offline; duplicata de webhook; recuperação e replay recusado; kit perdido; indisponibilidade do Worker. Licenças emitidas antes da rotação da chave individual podem continuar válidas até seu vencimento assinado de até 24 horas. Definir suporte e procedimento de recuperação quando ambos os segredos forem perdidos.

Não habilitar cobrança real só porque os mocks passaram. Registrar aprovação do responsável e configurações comerciais reais depois da homologação. A integração, monitoramento/backup e distribuição assinada ainda não estão provisionados.

Referências de configuração: [Wrangler](https://developers.cloudflare.com/workers/wrangler/configuration/), [D1](https://developers.cloudflare.com/d1/get-started/), [portal Stripe](https://docs.stripe.com/customer-management). Nenhum segredo deve ser enviado no chat.


## Preparação 0.9.9

Gate em scripts/release_gate.py e checklist ACCEPTANCE-0.9.9.md. O verificador retorna as configurações públicas e sete aceites pendentes; não acessa contas nem segredos. Backend com leitura limitada de corpos e validação de JSON; tokens/cache do cliente têm validação temporal adicional. Instalador .exe existe sem assinatura de editor. Recursos Cloudflare/Stripe e contato/responsável comercial continuam necessários para publicar. A documentação PRIVACY-DATA-FLOW.md descreve o fluxo técnico para a revisão final, não substitui os dados comerciais que faltam.
