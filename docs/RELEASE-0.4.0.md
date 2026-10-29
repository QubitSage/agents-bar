# Agents Bar 0.4.0 — Primeiro Sinal

Primeira missão com a biblioteca visual v04 integrada ao Godot. O Cavaleiro e Brasa atravessam a Forja, enfrentam Vigia de Latão, Caranguejo de Cobre e Rebocador e voltam à estação com núcleo, sucata, experiência e a primeira relíquia.

## Abrir e testar

1. Extraia a pasta inteira em um local gravável e abra `Iniciar Agents Bar.cmd`. Godot portátil está incluído; o jogo offline dispensa instalar Godot, Python ou Aseprite.
2. No canto, use **>**. Na barra expandida, use **Jogar**.
3. Em Expedições, use **Iniciar Primeiro Sinal · Forja**. Combate é automático.
4. **Pausar / retomar expedição** pausa também o relógio das ações. **Recolher no canto** mantém a missão avançando enquanto o aplicativo está aberto.
5. Na vitória, use **Receber recompensa e voltar**. A aba Estação abre; materiais, experiência e relíquia são guardados uma vez.

Fechar a janela da campanha mantém a barra aberta. Para encerrar tudo, use **Sair** na barra expandida. O progresso é salvo em `%APPDATA%\Agents Bar\progress.json`, com backup. Fechar interrompe a simulação; o tempo fechado não produz recompensas. Uma expedição salva retoma sua ação, incluindo se o impacto já foi aplicado.

## Conteúdo desta revisão

- 154 entradas do catálogo v04 copiadas para o jogo, incluindo os personagens usados pela campanha, cenários, estação e HUD. Fontes Aseprite permanecem no projeto de arte.
- Primeiro Sinal tem preparação, aproximação, impacto, recuperação, defesa, reação, morte e vitória. Dano usa o mesmo alcance mostrado na apresentação. A morte termina antes da troca de encontro.
- Vida, escudo e progresso reais no HUD; alerta da ação sendo preparada; sprites e construções com suas durações originais.
- A formação, treinamento, relíquias, construções e outras oito missões existentes foram preservados. Essas oito missões ainda usam o ritmo anterior de combate; não receberam a sincronização detalhada de Primeiro Sinal.
- Início desconectado. Nenhuma conexão ou leitura de conversa é necessária para jogar. As conexões experimentais continuam opcionais e explícitas; consulte `docs/CONNECTIONS.md`.

## Atualização e limites

Feche a versão anterior antes de abrir esta. Extraia a nova versão em outra pasta; a pasta de progresso continua a mesma. A compatibilidade foi testada com saves fictícios e modelos em memória. Arquivos de versão futura ou inválidos são preservados.

Lógica, retomada no meio do golpe, recompensa única e assets passaram por testes headless. O aplicativo não foi instanciado nem aberto graficamente pelo assistente. A revisão visual, foco/cliques, DPI, monitores, áudio, suspensão e instalação em outra máquina continuam no roteiro `docs/MANUAL-TESTS.md`.

Alpha privada, com runtime Windows x64 completo. Ainda não é um export otimizado nem instalador assinado. AZHOR e o elenco completo da galeria permanecem conteúdo de arte para integração futura; esta missão termina no Rebocador.
