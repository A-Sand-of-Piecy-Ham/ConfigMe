#Requires -Version 5.1
<#
.SYNOPSIS
    Installs this dotfiles checkout into the native Windows profile.

.DESCRIPTION
    This is the read-only mirror half of the setup. The WSL checkout is the
    source of truth: edit there, commit, push, then `git pull` here and re-run
    this script. Nothing in this repo should be edited from Windows.

    A second, native checkout is used rather than symlinking into
    \\wsl.localhost because everything Windows reads through that path goes
    over the 9p bridge -- roughly an order of magnitude slower per file
    operation. Neovim touches dozens of files at startup and lazy.nvim touches
    thousands during a sync, so the difference is plainly visible. The native
    clone also keeps Windows working when the WSL VM is shut down.

    Creating symlinks requires either Developer Mode (Settings > System > For
    developers) or an elevated shell.

.PARAMETER Force
    Overwrite existing real files without prompting. They are still backed up
    to <name>.bak first.
#>
[CmdletBinding()]
param(
    [switch]$Force
)

# Keep this file pure ASCII. PowerShell 5.1 decodes -File scripts as
# Windows-1252 when there is no BOM, so a UTF-8 em dash (E2 80 94) arrives as
# a right smart quote (0x94 in CP1252), which opens a string that never closes
# and produces parse errors pointing at unrelated lines further down.
$ErrorActionPreference = 'Stop'
$Dotfiles = $PSScriptRoot

function Test-SymlinkCapability {
    # Creating a symlink without Developer Mode or elevation fails with a
    # privilege error that is easy to misread as "the path is wrong", so probe
    # for it once and report it clearly instead.
    $probe = Join-Path $env:TEMP ("dotfiles-symlink-probe-" + [guid]::NewGuid())
    try {
        New-Item -ItemType SymbolicLink -Path $probe -Target $env:TEMP -EA Stop | Out-Null
        Remove-Item $probe -Force -EA SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function New-ConfigLink {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "  skip $Destination (no $Source)" -ForegroundColor DarkGray
        return
    }

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Destination) {
        $item = Get-Item -LiteralPath $Destination -Force
        # ReparsePoint covers both symlinks and directory junctions; either way
        # it is a link we (or a previous run) made, so replace it silently
        # rather than accumulating .bak links.
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $item.Delete()
        } else {
            $backup = "$Destination.bak"
            if (Test-Path -LiteralPath $backup) {
                if (-not $Force) {
                    Write-Host "  SKIP $Destination -- $backup already exists (use -Force)" -ForegroundColor Yellow
                    return
                }
                Remove-Item -LiteralPath $backup -Recurse -Force
            }
            Write-Host "  backing up $Destination -> $backup" -ForegroundColor DarkYellow
            Move-Item -LiteralPath $Destination -Destination $backup -Force
        }
    }

    New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
    Write-Host "  linked $Destination" -ForegroundColor Green
}

if (-not (Test-SymlinkCapability)) {
    Write-Error @'
Cannot create symlinks.

Enable Developer Mode (Settings > System > For developers > Developer Mode),
or re-run this script from an elevated PowerShell prompt.
'@
    exit 1
}

Write-Host "==> dotfiles: $Dotfiles"
Write-Host "==> target:   $env:USERPROFILE"
Write-Host ''

Write-Host '==> nvim'
New-ConfigLink -Source (Join-Path $Dotfiles 'nvim') `
               -Destination (Join-Path $env:LOCALAPPDATA 'nvim')

Write-Host '==> wezterm'
New-ConfigLink -Source (Join-Path $Dotfiles 'wezterm\wezterm.lua') `
               -Destination (Join-Path $env:USERPROFILE '.wezterm.lua')

Write-Host '==> git'
New-ConfigLink -Source (Join-Path $Dotfiles 'git\config') `
               -Destination (Join-Path $env:USERPROFILE '.gitconfig')
New-ConfigLink -Source (Join-Path $Dotfiles 'git\gitignore_global') `
               -Destination (Join-Path $env:USERPROFILE '.gitignore_global')

Write-Host '==> bash (Git Bash / MinGW)'
New-ConfigLink -Source (Join-Path $Dotfiles 'bash\common.sh') `
               -Destination (Join-Path $env:USERPROFILE '.config\dotfiles\common.sh')
New-ConfigLink -Source (Join-Path $Dotfiles 'bash\bashrc.windows') `
               -Destination (Join-Path $env:USERPROFILE '.bashrc')
New-ConfigLink -Source (Join-Path $Dotfiles 'bash\bash_profile.windows') `
               -Destination (Join-Path $env:USERPROFILE '.bash_profile')

Write-Host '==> claude'
# Only CLAUDE.md and memory are mirrored. .claude\skills on this machine is a
# tree of links into %USERPROFILE%\.agents and is managed separately.
New-ConfigLink -Source (Join-Path $Dotfiles 'claude\CLAUDE.md') `
               -Destination (Join-Path $env:USERPROFILE '.claude\CLAUDE.md')
New-ConfigLink -Source (Join-Path $Dotfiles 'claude\memory') `
               -Destination (Join-Path $env:USERPROFILE '.claude\memory')

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host 'This clone is a read-only mirror. Edit in WSL, push, then pull here.' -ForegroundColor DarkGray
