# Agents Bar — gameplay da alpha 0.5.0

O jogo é um RPG automático de expedições, com preparação da equipe dentro do HUD. A atividade dos agentes abastece o avanço da missão. Os limites abaixo são parâmetros iniciais para playtest, não um balanceamento final aprovado.

## Ciclo

1. Escolher Cavaleiro, Brasa e/ou Luma; começar com dois integrantes. Melhorar o Núcleo libera o terceiro.
2. Equipar relíquias, treinar e aprimorar armas na Forja.
3. Vincular as sessões recebidas aos heróis e escolher uma missão no Mapa. Também existe modo Livre, que funciona sem agentes.
4. A atividade abastece o tempo de simulação. A equipe caminha, enfrenta ondas e chefes, usa habilidades e termina a missão.
5. Revisar e recolher o resultado. Vitória concede materiais, XP e determinadas relíquias; derrota ou retirada não concede materiais. Coleta única por expedição.

## Trabalho e progressão

O coletor recebe metadados de fontes escolhidas explicitamente. Não lê automaticamente transcrições, pastas de agentes ou janelas.

| Evento observado | Regra inicial |
| --- | --- |
| Atividade de ferramenta | Até um pulso por segundo no coletor; cada pulso abastece 2 segundos de missão, limitado a 6 segundos por atualização |
| Novo turno trabalhando | 2 segundos |
| Novo incremento de tokens informado pela fonte | 1 segundo, independentemente do volume |
| Conclusão explícita de turno/resposta | 6 segundos |
| Aprovação pendente, desconexão ou ausência de evidência | Aguarda; não causa derrota |
| Silêncio por mais de 120 segundos enquanto trabalhando | Estado desconhecido, sem inventar conclusão |

Reserva máxima: 12 segundos. A conexão estabelece uma linha de base; uso anterior não vira uma explosão de recompensas. Sem avanço retroativo pelo tempo fechado. O relógio limita cada passo a 250 ms. Eventos repetidos e leituras cumulativas decrescentes não concedem uso adicional. Mais agentes no Pro não aumentam a formação máxima de três heróis.

Tokens não são moeda, dano proporcional, dinheiro ou crédito resgatável. São uma métrica observada e um pequeno impulso limitado. Fontes sem contagem continuam funcionando pelos eventos de atividade. O modo Livre usa a mesma campanha e persistência, sem depender do coletor; a demonstração usa progresso temporário.

## Conteúdo jogável

- Três personagens: Cavaleiro (vanguarda/defesa), Brasa (guardião/alvo prioritário) e Luma (cura).
- Forja nas Nuvens, Jardins de Vidro e Cinturão de Tempestade; nove missões e nove tipos de inimigos, incluindo três chefes de região.
- Todas as missões usam a timeline de animação: aproximação, preparação, impacto, recuperação, defesa, reação e morte. O dano só entra no instante de impacto; a onda seguinte aguarda a conclusão da morte.
- Treinamento até nível 5; seis relíquias únicas; quatro construções da estação.
- Forja de armas até +5, com +2 ataque por nível. Custo: 8 × próximo nível de sucata; a partir de +3 também 1 núcleo.
- Reciclagem de relíquia desequipada: 4 sucata. Recriação: 24 sucata e 1 núcleo, após concluir a missão que libera a relíquia.
- Save local com checksum, backup e proteção contra coleta repetida. Campos novos preservam compatibilidade com os saves anteriores.

AZHOR e o elenco completo da galeria continuam como biblioteca de arte para a expansão de conteúdo; esta campanha não inclui automaticamente todo o catálogo como encontros jogáveis. A cadência e dificuldade precisam de playtest humano.

## HUD

Uma janela com modo compacto no canto, expansão e faixa de combate persistente. Navegação: Heróis, Inventário, Forja, Mapa, Estação, Agentes, Pro e Menu. Os painéis internos aparecem lado a lado; a campanha não abre uma segunda janela nativa. Pausar o jogo não pausa os agentes.

## Pro aprovado

Pro: mais agentes simultâneos e histórico de uso por US$ 2/mês. Limites iniciais de implementação: Free 3 sessões/24 horas; Pro 12 sessões/90 dias. Histórico local em SQLite, agrupado por dia UTC; conta apenas o consumo observado após conexão, não a fatura completa do provedor. A assinatura usa licença assinada de até 24 horas e retorna aos limites gratuitos ao expirar. O histórico excedente é descartado conforme a retenção do plano vigente. Não há recuperação de dias já descartados ao assinar depois.
