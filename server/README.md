# Backend Pro — implantação pendente

Use Node e Wrangler no ambiente de deploy. Não publique segredos no repositório ou no pacote do jogo.

1. `npx wrangler login` e `npx wrangler d1 create agents-bar`.
2. Coloque o ID retornado no `wrangler.toml`; ajuste `PUBLIC_URL` para a URL HTTPS escolhida.
3. `npx wrangler d1 execute agents-bar --remote --file=schema.sql`.
4. Crie na Stripe de teste um preço USD 2 recorrente mensal e configure `STRIPE_PRICE_ID`. Habilite o portal de clientes.
5. Gere a chave em uma pasta segura fora do projeto: `node generate-signing-key.mjs CAMINHO_SEGURO_NOVO`. Configure o conteúdo de `private.jwk` com `npx wrangler secret put LICENSE_PRIVATE_JWK`. Não copie esse arquivo para o cliente.
6. Configure `npx wrangler secret put STRIPE_SECRET_KEY` e `npx wrangler secret put STRIPE_WEBHOOK_SECRET`.
7. Cadastre o webhook HTTPS `/v1/webhook` para `checkout.session.completed`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid` e `invoice.payment_failed`. Confira o segredo do endpoint exato.
8. `npx wrangler deploy`. Teste o ciclo completo em modo teste. Não basta receber sucesso do checkout: a licença depende do estado confirmado por webhook.
9. Em `game/content/online.json`, configure `api_url`, `portal_url` (página raiz do Worker) e `license_public_key` com o JWK público. Refaça o pacote e valide ativação, expiração e cancelamento.
10. Só após o aceite comercial e testes reais em modo teste, configure os recursos live correspondentes. Nunca misture IDs/segredos de teste e produção.

`node --test server/test.mjs server/recovery.test.mjs server/input.test.mjs` a partir da raiz executa mocks de cobrança e verificação de licença entre JavaScript e Python. A implantação deve manter separação entre ambientes e dados. Veja `docs/INFRASTRUCTURE.md` para limites e pendências antes da venda pública.


0.9.9: recuperação transacional por kit, limite de corpos HTTP e respostas 400/413 para entradas inválidas. Execute `scripts/release_gate.py --public` antes de preparar publicação; exige configuração pública e aceites registrados. Dados/segredos de teste e live permanecem separados. Todos os testes atuais são locais, sem D1 ou Stripe reais.
