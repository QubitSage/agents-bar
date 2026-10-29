# Instalação, atualização e rollback — 0.8

## Portátil

Extraia o ZIP inteiro. Abra `Iniciar Agents Bar.cmd`. O jogo inicia desconectado. Godot e Python estão incluídos. O pacote contém manifesto de arquivos com tamanho e SHA-256. `install.ps1 -Mode Verify -PackageRoot CAMINHO` confere o pacote extraído antes de uso; o manifesto não é assinatura de editor.

## Instalado por usuário

`Instalar ou atualizar.cmd` instala em `%LOCALAPPDATA%\Programs\Agents Bar`, sem administrador, e cria um único atalho `Agents Bar` na Área de Trabalho. Feche o jogo antes. As versões ficam em `versions/<versão>`; `current.json` aponta a ativa e guarda a anterior. Não são criados atalhos para pastas, galerias ou ferramentas.

Para atualizar, extraia uma nova versão recebida de fonte confiável e rode o instalador dela. Os arquivos são verificados antes e depois da cópia; a troca da versão ativa é atômica. A versão anterior permanece disponível. Pacotes incompletos, corrompidos, com caminhos fora da pasta ou arquivos inesperados são recusados.

Rollback: execute `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Programs\Agents Bar\Agents Bar.ps1" -Rollback`. O rollback troca o programa; não reverte progresso. Saves em esquema mais novo ficam protegidos de gravação por versões antigas. Não exclui versões ou dados.

O progresso e a geometria continuam em `%APPDATA%\Agents Bar`, conforme o diretório de usuário do Godot. No modo instalado, tracking/licença/histórico ficam em `<instalação>/data/tracking`, compartilhados entre versões. No modo portátil, continuam em `runtime/tracking`. Não foi feita migração de dados pessoais de outra instalação.

Para preparar snippets no modo instalado, use o launcher `Agents Bar.ps1 -Prepare`. Ele gera referências para a versão atual e para a pasta estável de dados; mescle explicitamente no provedor. Hooks antigos podem apontar para uma versão preservada: regenere/revise ao atualizar. O instalador não modifica configurações de agentes.

## O que foi testado

Instalação, reinstalação idempotente, atualização, rollback, preservação de arquivo fictício na pasta de dados, rejeição de corrupção, arquivo extra, caminho traversal, duplicata, runtime ausente, versão inválida e rollback sem versão anterior. Todos em pastas temporárias; sem atalho e sem iniciar o jogo.

Não há auto-update em rede, assinatura Authenticode, instalador MSI/EXE, desinstalador automático ou publicação em loja nesta alpha. Esses pontos exigem uma próxima entrega de distribuição pública e, para assinatura/publicação, contas externas. Os pacotes antigos do projeto foram preservados.
