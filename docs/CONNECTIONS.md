# Conexões opcionais e explícitas

A campanha funciona desconectada. Estes comandos são documentação para quando o usuário decidir conectar; nenhum deles foi executado sobre sessões reais nesta revisão.

## Uma sessão

```powershell
.\start.ps1 -Connect -SessionFile 'C:\caminho-escolhido\rollout-ID-DA-SESSAO.jsonl' -ThreadId 'ID-DA-SESSAO'
```

## Até três sessões

Crie um JSON com os arquivos escolhidos. A ordem associa as sessões a IO, Brasa e Luma. Não há varredura de pastas ou descoberta automática.

```json
{
  "sessions": [
    {"sessionId": "sessao-a", "file": "C:\\caminho-escolhido\\rollout-sessao-a.jsonl", "label": "Projeto A"},
    {"sessionId": "sessao-b", "file": "C:\\caminho-escolhido\\rollout-sessao-b.jsonl", "label": "Projeto B"}
  ]
}
```

```powershell
.\start.ps1 -Connect -ConnectionsFile 'C:\caminho-escolhido\conexoes.json'
```

Requer Python disponível no PATH. Arquivos ausentes afetam apenas o slot correspondente; configurações duplicadas ou sem caminhos absolutos são rejeitadas. Cada execução escreve seu próprio snapshot e encerra o leitor ao fechar o aplicativo. O leitor copia apenas eventos permitidos de ciclo de vida e atividade; conteúdo de mensagens, argumentos e resultados de ferramentas não é exportado.

O formato local é experimental. Não detecta aprovação: silêncio é ausência de sinal, não sucesso. O normalizador App Server em `bridge/hub.py` é uma função testada, ainda sem transporte conectado. Seleção gráfica de sessões e abertura da conversa de origem ficam no backlog; esta alpha usa configuração explícita por arquivo.

Uma conclusão nova e explícita pode oferecer uma lembrança no Diário. O usuário aceita ou descarta; a decisão é deduplicada. Conclusões anteriores à abertura do app não são importadas como novas entregas. Demonstração não gera marcos de trabalho.
