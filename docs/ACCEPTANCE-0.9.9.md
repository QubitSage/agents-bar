# Aceite para avançar de 0.9.9 a 1.0

Todos os itens abaixo estão PENDENTES de execução real. Os testes automatizados são evidência complementar, não aprovação destes critérios. Registrar resultado e evidência em `acceptance-1.0.json`; não preencher como aprovado por inferência.

| Critério | Exercício e evidência esperada |
|---|---|
| windows_visual | Primeiros passos, todas as abas, estados vazios/erro/resultado; nenhuma área cortada; arrastar/recolher/resize; 100/125/150% DPI; monitor secundário; foco e Sempre acima; imagens ou registro do teste |
| windows_install_upgrade | Instalador gráfico numa máquina limpa; um atalho; iniciar desconectado; atualizar conservando progresso; rollback protegido; desinstalar preservando dados; comportamento do Windows/antivírus |
| real_providers | Provedor e versão registrados; iniciar/ferramenta/aprovação/conclusão; tokens apenas quando disponíveis; reconectar sem crédito antigo; comparar amostra conhecida sem duplicação |
| stripe_test_mode | Checkout confirmado, ativar Pro, renovar, falhar pagamento, cancelar, expirar offline, recuperar chave, recusar replay, webhook repetido/fora de ordem; IDs de teste sem segredos |
| cloud_deployment | Worker/D1 HTTPS, schema aplicado, segredos cadastrados fora do projeto, limites, backup/restauração e observabilidade conferidos |
| publisher_signing | Certificado do responsável; artefatos finais assinados e assinatura verificada; hash dos arquivos distribuídos |
| commercial_content | Identificação do responsável, contato de suporte, privacidade, cancelamento/reembolso e apresentação do preço revisados para publicação |

## Playtest

Completar ao menos a primeira região; experimentar Forja/equipamentos; avaliar duração, clareza de dano, dificuldade e recompensas. Ver AZHOR em demonstração e pela campanha; conferir variantes, ultimate e morte. Usar durante um período de trabalho real para observar consumo de recursos e interrupções. Anotar versão, monitor/DPI, passos e efeito esperado/observado. Não enviar conversas ou chaves no relato.

## Publicação

`tools/python/python.exe scripts/release_gate.py --public` retorna falha enquanto campos públicos ou evidências estiverem pendentes. O comando não acessa contas, não verifica pagamentos por conta própria e não concede aprovação humana. A 0.9.9 deve continuar privada enquanto o gate falhar.

Quando os acessos estiverem disponíveis: separar ambiente Stripe de teste, configurar Worker/D1, homologar os fluxos, revisar o conteúdo comercial e assinar o pacote. Só então preparar a build 1.0. Nenhuma dessas ações externas foi executada nesta entrega.
