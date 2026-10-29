# Agents Bar 0.9.11 — combate legível

Revisão de 27/10/2026 após a captura enviada pelo usuário e consulta à galeria oficial do TBH: Task Bar Hero (https://www.nugemstudio.com/en/games/taskbar-hero).

O espaço de combate tinha 120 px incluindo título e status, comprimindo o herói para cerca de 27 px. Agora, no preset 984 × 760, recebe 268 px, com cena de 202 px separada do título e indicadores; o cavaleiro ocupa aproximadamente 98 px. O tamanho mínimo expandido passa a 884 × 700 e os presets a 884 × 700, 984 × 760 e 1120 × 820. A janela continua ajustável e contida na área útil do monitor; telas menores podem aplicar escala de ajuste.

- Cenário único com recorte proporcional alinhado ao chão, sem repetir o mesmo prédio pela barra inteira.
- Personagens maiores, com posição limitada à área central em janelas muito largas.
- Escala estável por personagem, calculada considerando todas as poses, inclusive a ultimate do AZHOR, para preservar margem vertical.
- Menus continuam dentro da HUD, com o espaço mínimo anterior preservado e sem rolagem. O modo compacto e o progresso não mudam.

Comparação ilustrativa usando os próprios assets: `art-direction/battle-scale-v01/index.html`. A geometria usada na comparação é exportada do código do jogo; não é uma captura da janela Godot.

Validação: teste de enquadramento cobre quatro larguras, quatro alturas, recortes de cenários e limites verticais das animações. A criação da HUD é verificada apenas em cópia isolada headless, sem janelas ou agentes reais. Renderização real, foco, DPI e aprovação visual continuam com o usuário.

Abra pelo mesmo atalho Agents Bar ou por `Iniciar Agents Bar.cmd`. Pacotes anteriores preservados. Nenhuma conta, sessão real ou cobrança foi ativada.
