# Agents Bar 0.3.0 — alpha de campanha

## Abrir e jogar

Extraia a pasta inteira para um local gravável. Abra `Iniciar Agents Bar.cmd`. Não é necessário instalar Godot, Python ou Aseprite para o modo de jogo desconectado. O runtime Windows x64 está incluído. Esta alpha usa o runtime portátil completo; ainda não é um export otimizado nem um instalador assinado.

Na barra do canto, `>` abre o jogo e `+` expande a barra. Na barra expandida, `Jogar` abre a campanha, `Recolher` volta ao canto e `Sair` fecha o aplicativo. Fechar a janela de campanha recolhe essa janela e mantém a barra funcionando. Para encerrar tudo, use Sair na barra.

Comece por Primeiro sinal, recolha o resultado e use os materiais para treinar personagens e melhorar a estação. Núcleo nível 2 permite levar IO, Brasa e Luma juntos. Há três regiões, nove missões, nove tipos de inimigo, três chefes, seis relíquias e quatro construções. Vitórias liberam rotas; retiradas e derrotas não gastam seus materiais.

Na Estação, mude construções entre quatro encaixes. Marcos aceitos no Diário acendem luzes e podem ser vinculados aos módulos como lembranças. Duas ou mais entregas pendentes podem ser combinadas em um marco com o título informado.

Combate ocorre enquanto o app está aberto. O botão de pausa da barra controla apenas a animação da barra; a pausa da expedição fica na janela do jogo. O aplicativo fechado não acumula batalhas nem recompensas. Uma missão em andamento pode ser retomada do último estado salvo.

## Progresso e atualização

O jogo usa a pasta de dados local `%APPDATA%\Agents Bar`. `progress.json` guarda a campanha e `progress.json.bak` é o backup do último estado válido. Preferências da barra ficam em `preferences.json`. Esta versão não precisa importar a preferência antiga em `runtime/`: ela não continha progresso de campanha.

Para atualizar, feche o jogo e extraia a nova versão em outra pasta. O mesmo nome de pasta de dados preserva o progresso. Não sobrescreva manualmente um save de versão futura. Um save inválido que não possa ser recuperado coloca o jogo em modo de leitura, preservando os arquivos para revisão.

Para remover a alpha, feche o jogo e apague somente a pasta extraída e seu atalho. O progresso permanece na pasta de dados. Remover também essa pasta apaga o progresso, portanto só faça isso quando desejar reiniciar definitivamente.

## Conexões opcionais

O início normal não conecta a nenhum agente. `Demonstrar Agents Bar.cmd` exibe dados fictícios. Conexões reais são experimentais, precisam de Python e de caminhos explicitamente informados; veja `docs/CONNECTIONS.md`. Nenhuma sessão real foi lida durante os testes desta alpha. Marcos de trabalho precisam ser aceitos e geram somente lembranças decorativas.

## Limites desta entrega

A lógica, os assets, os saves e a composição do pacote foram verificados sem abrir a interface do aplicativo. Foco, cliques através da transparência, escalas/DPI, áudio, múltiplos monitores, suspensão, sessão de oito horas, instalação em máquina limpa e piloto continuam pendentes. Não há resultado de piloto, assinatura de código ou validação visual desta revisão.

O pacote usa OpenGL compatível e Windows x64. Compatibilidade real de GPU e políticas de execução do PowerShell deve ser verificada no ambiente de teste. Não altera políticas de segurança do Windows.
