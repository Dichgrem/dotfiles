# UTF-8
chcp 65001 > $null
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView

# Git
Import-Module posh-git

# fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider Ctrl+t -PSReadlineChordReverseHistory Ctrl+r

# zoxide
Invoke-Expression (& { zoxide init powershell | Out-String })

# Starship
Invoke-Expression (&starship init powershell)

# Bash 风格快捷键
Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine
Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
