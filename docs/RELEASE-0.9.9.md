# Agents Bar 0.9.9 — candidata privada à 1.0

Entrega local de 27/10/2026. Implementa a preparação até a 0.9.9; não representa publicação ou homologação em contas reais.

## Abrir

No projeto, use `Iniciar Agents Bar.cmd` ou o atalho Agents Bar existente. Uma campanha nova mostra **Primeiros passos** ao expandir a barra. O guia também está em **Menu → Primeiros passos**. **Começar em modo Livre** inicia a primeira missão real, sem configurar provedores. Para olhar o chefe final com progresso temporário, use `Demonstrar AZHOR.cmd`.

Para instalar em outro local, use `AgentsBar-Setup-0.9.9.exe`: selecione a pasta e escolha se deseja um único atalho na Área de Trabalho. O instalador não abre o jogo ao terminar. Alternativa portátil: extraia o ZIP completo e use o inicializador. A assinatura digital do instalador ainda está pendente do certificado de publicação.

## Novidades desde a 0.8

- Introdução integrada à HUD, guiada pelo estado real: partir, acompanhar, recolher a recompensa, equipar a primeira relíquia e preparar a próxima viagem. Pode pular e reabrir.
- Menu separado em Janela/Preferências; opção persistida Sempre acima, sons e movimento reduzido. Ajuda e diagnóstico ficam no próprio HUD.
- Retirada de missão exige confirmação interna. Recuperação de backup também pede confirmação, preserva o arquivo anterior e só fica disponível com backup válido. Progresso de uma versão futura permanece protegido.
- Interrupção longa de execução pausa uma expedição ativa e limpa crédito de atividade; após retomar, o usuário confere a missão. Não há recompensas pelo tempo fechado/suspenso.
- Desconectar coletor pela tela Agentes. Encerramento autenticado, gravação final de desconexão e histórico preservado. O observador local ignora proxies HTTP externos.
- Saves no esquema 4: migração dos esquemas 1/2/3, registro de recompensas limitado a 100 entradas e marcador monotônico que impede recontar recompensas antigas. Diário mantém até 100 entradas.
- Atualização da HUD evita serializar o progresso completo a cada frame. Preferência Sempre acima só é aplicada à janela quando muda.
- Verificação mais estrita de argumentos MCP e licenças; escrita atômica do cache de licença. Backend rejeita corpos grandes ou inválidos antes de processar os pedidos.
- Instalador Windows `.exe`, além do ZIP; instalação, atualização, rollback e desinstalação preservando dados. Fontes do instalador em `installer/Setup.cs`.
- Checklist de aceite e verificador de publicação: configuração ausente e critérios manuais pendentes impedem marcar a entrega como pronta para venda.

Conteúdo mantido: 24 itens de arte, 12 equipamentos, seis relíquias, três moedas, três heróis, três regiões, dez missões, três chefes regionais e AZHOR. Outros personagens/bosses da galeria continuam fora da campanha desta versão. Não foram adicionadas novas moedas ou artes nesta rodada.

## Evidência e limites

65 testes Python e 12 do backend passaram. Godot: 3.936 verificações, incluindo o pipeline dos seis provedores e oito horas simuladas de campanha. O teste repetiu 460 missões; maior save observado: 12.710 bytes. O coletor recebeu 8.640 eventos fictícios ao longo de oito horas simuladas. São testes da lógica, não medições da janela real aberta durante oito horas.

O código do instalador foi compilado. A verificação e extração do pacote embutido usam modos CLI que não criam janelas. A aparência e o fluxo gráfico do instalador precisam do aceite do usuário, assim como HUD, DPI, foco e desempenho gráfico.

Pendente para 1.0: aceite nativo no Windows; playtest humano; homologação de provedores reais; Cloudflare/D1/Stripe de teste e produção; certificado de assinatura; responsável, suporte e informações comerciais finais. Nenhuma sessão real, conta de cobrança ou configuração de terceiros foi acessada. A assinatura Pro permanece desativada no cliente até configuração válida.

Veja `docs/QUICKSTART-0.9.9.md`, `docs/ACCEPTANCE-0.9.9.md`, `docs/DISTRIBUTION-0.9.9.md` e `docs/VERIFY-0.9.9.md`.
