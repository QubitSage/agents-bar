# Agents Bar 0.5.0 — alpha privada

HUD único com painéis internos e combate persistente, campanha animada de nove missões, Forja, vínculos de agentes, coletor local e modelo Pro. Leia README.md da pasta de projeto para contexto e docs/GAMEPLAY-0.5.md para as regras.

Abra `Iniciar Agents Bar.cmd`. No jogo: Abrir → Mapa → Livre → Primeiro Sinal para testar sem conexão. `Demonstrar Agents Bar.cmd` usa dados fictícios sem salvar progresso normal. Para acompanhar trabalho real, siga docs/INTEGRATIONS.md; o início é desconectado.

Pro: US$ 2/mês; 12 sessões/90 dias, comparado com Free 3 sessões/24 horas. Limites iniciais. Nenhuma cobrança está publicada nesta build. A formação continua com até três heróis em ambos os planos. Python portátil incluído apenas para tracking opcional; nenhuma instalação global é necessária.

Validação automatizada: testes de Python/HTTP com fixtures, cobrança/assinatura com mocks, compilação de scripts e simulação Godot sem instanciar aplicação. Consulte o relatório VERIFY-0.5.0.md no projeto. Validação manual de UI, desempenho e agentes reais pendente. Backend entregue como fonte, sem deploy; credenciais, recuperação de licença e aceite comercial ainda necessários para vender.

O pacote não contém sessões, saves do desenvolvedor, chaves de licença, segredos de Stripe ou a chave privada de assinatura. SHA-256 de todos os arquivos em manifest.json. Fontes Aseprite e backend permanecem no projeto de desenvolvimento; esta distribuição contém o runtime.
