# Distribuição Windows — 0.9.9

## Instalador gráfico

`AgentsBar-Setup-0.9.9.exe` contém o ZIP completo. Não baixa dependências nem inicia o jogo. Confira pasta de destino e opção de criar o único atalho Agents Bar; clique Instalar/atualizar. A extração tem limite de tamanho e confere o SHA-256 embutido. O instalador PowerShell interno confere o manifesto antes/depois da cópia. O `.exe` requer .NET Framework com suporte a ZipArchive; precisa de teste em máquina limpa antes da 1.0.

Padrão: `%LOCALAPPDATA%\Programs\Agents Bar`. Não pede administrador; pasta protegida pode ser recusada. Feche o jogo antes. A verificação do payload e a extração foram testadas sem GUI. A aparência do formulário e o fluxo de clique ainda precisam de aceite nativo.

O executável ainda não tem assinatura digital de editor: Windows/SmartScreen pode pedir confirmação ou bloquear conforme a política da máquina. Hash não substitui Authenticode. A assinatura depende do certificado e do processo de publicação que serão fornecidos depois; não foi desabilitada proteção do Windows.

## ZIP e atualizações

O ZIP é alternativa portátil. Extraia tudo, então use `Iniciar Agents Bar.cmd`. Para instalar via scripts, use `Instalar ou atualizar.cmd` de uma extração limpa. Não tente instalar a partir de uma pasta portátil já modificada pelo uso: arquivos extras são recusados para preservar a integridade do pacote.

Cada versão instalada fica em `versions/<versão>`. `current.json` aponta a ativa e anterior; atualização não apaga as antigas. O programa começa desconectado. O progresso permanece no diretório de usuário do Godot; tracking e licença da instalação ficam em `data/tracking`, compartilhados entre versões.

## Manutenção

A partir da pasta instalada, execute o launcher PowerShell com uma destas opções:

- `Agents Bar.ps1 -Prepare`: gerar snippets de integração, sem mesclar configurações de terceiros.
- `Agents Bar.ps1 -Rollback`: trocar o programa para a versão anterior. Não reverte progresso; save esquema 4 fica protegido em versões antigas.
- `Agents Bar.ps1 -Uninstall`: remover arquivos reconhecidos do programa e seu atalho, preservando saves, histórico e arquivos desconhecidos. Arquivos de programa modificados fazem a operação parar antes de excluir qualquer pacote.

Os caminhos de remoção são resolvidos dentro da instalação; dados pessoais não são alvos da desinstalação. Se quiser também apagar dados locais, isso é uma ação separada e não é feita automaticamente.

Fontes: `installer/Setup.cs`, `install.ps1`, `installed-launcher.ps1`. Build: primeiro `scripts/package.py`, depois `scripts/build_installer.ps1`. Builds existentes são preservadas. O `.exe` é uma interface para o mesmo instalador verificado e não é um MSI registrado no painel de aplicativos do Windows.

Ainda não há atualização automática em rede, catálogo público ou certificado de editor. Antes da 1.0, realizar instalação gráfica em máquina limpa, atualização com progresso real, desinstalação, assinatura e revisão dos avisos do Windows.
