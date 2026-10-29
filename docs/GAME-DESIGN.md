# Agents Bar — campanha inicial

## Experiência

Uma tripulação de pequenos robôs reconecta um arquipélago abandonado. O jogador escolhe missões, forma uma equipe e acompanha combates automáticos. O jogo continua no canto enquanto a pessoa trabalha. Funciona sem conta, IA ou conexão com agentes. Quando uma conexão é escolhida, o estado dos agentes é apresentado separadamente da expedição.

## Personagens e estratégia

- **IO / explorador:** dano rápido e pulso que expõe o alvo. Bom para encurtar confrontos.
- **Brasa / guardião:** prioridade como alvo dos inimigos, armadura e escudo periódico. Protege uma equipe frágil.
- **Luma / botânica:** cura o aliado proporcionalmente mais ferido. Sustenta expedições longas.

Começar com dois tripulantes. O Núcleo nível 2 libera a equipe de três. Cada personagem tem nível de 1 a 5 e um slot de relíquia; não é possível equipar a mesma peça em dois personagens.

## Mapas e missões

| Região | Missões | Chefe |
| --- | --- | --- |
| Arquipélago de Sucata | Primeiro sinal; Ponte de cobre; A última doca | O Rebocador |
| Jardins de Vidro | Sementes de luz; Raízes profundas; Coração da estufa | Coração Silvestre |
| Cinturão de Tempestade | Entre relâmpagos; Farol partido; Um novo horizonte | Arconte da Tempestade |

Cada missão tem duas ondas. A conclusão libera a seguinte. É possível repetir uma missão para obter materiais; a relíquia de primeira conclusão é concedida uma única vez.

## Combate

Rodadas automáticas com ordem por velocidade. Vida, ataque e armadura são explícitos. Habilidades ocorrem a cada três rodadas. Alguns inimigos causam dano contínuo, outros curam ou usam ataques concentrados. A equipe recupera uma pequena fração de vida entre ondas. Não há morte permanente nem gasto de material para tentar uma missão.

As decisões são a composição da equipe, sua evolução, relíquias e melhorias da estação. Não há clique repetitivo para aumentar dano. Um limite de rodadas encerra confrontos travados em derrota; não pode gerar recompensas.

## Economia

Sucata melhora tripulantes e construções; núcleos e sementes especializam a estação. O Observatório melhora a coleta de sucata, a Oficina aumenta ataque, a Estufa aumenta vida e o Núcleo aumenta capacidade. Valores iniciais são parametrizados em `game/content/game.json` e sujeitos ao piloto.

Tokens não concedem poder, moedas ou experiência. Marcos de trabalho aceitos pelo usuário geram registros e lembranças decorativas; não alteram a dificuldade das batalhas. Uma missão vencida e sua coleta são identificadas para impedir recompensa duplicada.

As quatro construções podem trocar de encaixe na estação. Lembranças aceitas acendem pequenas luzes no cenário e podem ser vinculadas a uma construção com o título da entrega. Entregas pequenas podem ser combinadas em uma lembrança única, preservando a deduplicação dos eventos originais.

## Sessões curtas e descanso

O jogo não pune ausência, não compra ações e não executa IA para movimentar o mundo. Não avança batalhas por tempo de relógio enquanto está fechado. A expedição ativa é salva e pode continuar após a reabertura. Retirada e derrota não recebem o prêmio de vitória.

## Recorte desta implementação

Três mapas, nove missões, três personagens, nove inimigos, seis relíquias, quatro construções e histórico local. Fora do recorte: multiplayer, mercado, conta obrigatória, temporadas, moeda paga e geração procedural de conteúdo por IA.
