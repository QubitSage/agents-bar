# Gameplay de lançamento privado — 0.8

Mantém as regras de `GAMEPLAY-0.6.md` e acrescenta os equipamentos Fortaleza.

## Ciclo

Escolher heróis → montar formação → escolher missão disponível → acompanhar combate → revisar/recolher → fabricar, equipar ou treinar → abrir a próxima missão. Em Livre, a simulação avança sem um agente. Em Agentes, somente sessões explicitamente vinculadas aos heróis da formação abastecem pequenos trechos de simulação.

Eventos novos concedem crédito limitado; não existe conversão proporcional de tokens em dano, XP ou moeda. Contadores acumulados antigos não geram recompensa ao conectar. Aprovação pendente, falta de sinal e desconexão interrompem avanço sem evidência. Pro amplia acompanhamento e histórico, não o tamanho ou o poder da equipe.

## Conteúdo fechado para esta alpha

Três heróis (Io, Brasa, Luma), três regiões, dez missões, três chefes regionais e AZHOR. A campanha é completável com os recursos ganhos em teste determinístico; equipamentos são alternativas opcionais de progressão, não pré-requisitos adicionais. Personagens e bosses restantes da galeria não estão todos adicionados à campanha.

Armas iniciais: espada de Io, martelo de Brasa e cajado de Luma, sem bônus adicional sobre a base anterior. Alternativas: machado para Brasa (+3 ataque), arco para Luma (+2 ataque/+1 velocidade), lança para Io (+2 ataque/+1 armadura). Aprimorar arma continua sendo progresso do herói e vale para a arma que ele usa, sem duplicar o bônus ao trocar.

Armaduras: elmo (+1 armadura), peitoral (+12 vida), manoplas (+1 ataque), grevas (+1 velocidade), escudo (+1 armadura), manto (+8 vida). Cada peça ocupa seu próprio slot. Uma unidade física por item no inventário; transferir entre heróis exige desequipar primeiro. Armas respeitam classe. Não se remove a arma obrigatória nem se altera equipamento durante missão.

Seis relíquias mantêm suas regras anteriores. Sucata, núcleos e sementes continuam as três moedas. Lingotes, cristais e fibra têm arte pronta e ficam reservados; não aparecem como novos recursos coletáveis. Receita, custo, desbloqueio e bônus têm fonte única em `game/content/items.json`.

## Balanceamento e persistência

Custos das nove peças fabricáveis: 16–56 sucata, 0–2 núcleos, 0–4 sementes. Desbloqueios distribuídos de scrap-1 a storm-2/garden-3. O custo não é cobrado em operações recusadas. Itens não duplicam, bônus entram nos atributos usados no combate e o estado da batalha é mantido ao salvar.

A suíte percorre dez missões sem inventar moeda, verifica limites de formação, derrota, fuga, recompensa única, defesa, impacto, morte e reload durante ultimate. 15.500 passos adicionais de combate sintético verificam repetibilidade. Isto é uma primeira calibração determinística; ritmo, dificuldade percebida e clareza dos ataques precisam de playtest humano.
