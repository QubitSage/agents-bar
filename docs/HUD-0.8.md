# HUD A — Fortaleza / implementação 0.8

## Estrutura consolidada

Janela única: cabeçalho com recursos e ações Recolher/Fechar; resumo da sessão; formação lateral com os três heróis; dois painéis de contexto; faixa de combate; ações da expedição; oito abas inferiores; status. Heróis, Inventário, Forja, Mapa, Estação, Agentes, Diário e Menu são páginas internas. Pro abre a partir do Menu.

Padrão expandido: 984 × 640; mínimo lógico 884 × 600. Barra: 360 × 92, mínimo 320 × 84. Monitores menores usam escala do canvas; a legibilidade precisa de conferência no equipamento real. As regiões geométricas passaram por testes sem sobreposição em 20 combinações de dimensões, de 884 × 600 a 1920 × 1080. Isso não é validação pixel a pixel do runtime.

A posição e o tamanho da barra e do HUD são independentes e persistidos. Arraste no cabeçalho; oito bordas/cantos permitem resize. Menu oferece três presets e largura/altura. Trocar aba ou receber novo evento não move a janela. Esc recolhe/expande. A janela continua acima das demais.

## Interações

- Formação lateral: seleciona o herói e exibe nível, presença na equipe e estado observado do agente.
- Inventário: Relíquias / Equipamento. Grade de seis itens por página; detalhe, classe, estado e ações no painel direito. Nunca depende de scroll.
- Forja: Aprimorar / Fabricar. Aprimoramento conserva o sistema +0 a +5; fabricação usa novas receitas da campanha. Equipamento é único e o custo é descontado uma vez.
- Agentes e histórico: paginação de sessões/registros, com uso desconhecido apresentado como indisponível.
- Itens: 48 pixels nativos nos slots, filtro nearest, sem reamostragem fracionária dos ícones em tamanho lógico normal. A escala de DPI/monitor continua dependente do Windows.

## Aceite nativo pendente

Abrir pelo usuário e conferir: leitura de nomes/custos; mudança entre todas as abas; ícones bloqueados/selecionados; menus sem conteúdo cortado; arraste/resize em 100/125/150% DPI; recolher/expandir; foco sobre outros aplicativos; monitor secundário; retomada após fechar; gameplay e efeitos sonoros. A implementação não foi instanciada graficamente nesta entrega, conforme a restrição de acesso do projeto.
