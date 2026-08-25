#Requires -Version 5.1
<#
.SYNOPSIS
    Installs this dotfiles checkout into the native Windows profile.

.DESCRIPTION
    This is the read-only mirror half of the setup. The WSL checkout is the
    source of truth: edit there, commit, push, then `git pull` here and re-run
    this script. Nothing in this repo should be edited from Windows.

    A second, native checkout is used rather than pointing Windows at
    \\wsl.localhost because everything read through that path crosses the 9p
    bridge -- roughly an order of magnitude slower per file operation. Neovim
    opens dozens of files at startup and lazy.nvim touches thousands during a
    sync, so the difference is plainly visible. The native clone also keeps
    Windows working while the WSL VM is stopped.

.NOTES
    No elevation or Developer Mode required.

    Creating a *symbolic* link on Windows is a privileged operation, but the
    two mechanisms this script actually relies on are not:

      * Directory junctions are unprivileged and behave like symlinks for
        reads, so every directory target uses one.
      * For the handful of single files, each target format has its own native
        include directive (git's [include], bash's `.`, Lua's dofile,
        CLAUDE.md's @import). A tiny real file carrying that directive
        redirects into the repo, so edits still flow through with no copying.

    Hard links were deliberately NOT used for the file targets. `git pull`
    writes a new file and renames it over the old one, which severs a hard
    link -- the mirror would silently stop updating.

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

# Forward slashes for the shims: bash and git both reject the backslashes of a
# native Windows path as escape sequences.
$DotfilesPosix = $Dotfiles -replace '\\', '/'

function Clear-Destination {
    # Returns $true if the caller should proceed with writing $Destination.
    param([Parameter(Mandatory)][string]$Destination)

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Destination)) { return $true }

    $item = Get-Item -LiteralPath $Destination -Force

    # ReparsePoint covers both symlinks and junctions; either way it is a link
    # a previous run made, so replace it silently rather than accumulating
    # .bak links pointing at old checkouts.
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $item.Delete()
        return $true
    }

    # A shim we wrote previously is ours to replace too.
    if (-not $item.PSIsContainer) {
        # Match the marker without any comment prefix: the shims use whatever
        # comment syntax their consumer understands (#, --, <!--), so keying on
        # one of them makes the script fail to recognise its own output and
        # back a shim up over the genuine original on the next run.
        $existing = Get-Content -LiteralPath $Destination -Raw -EA SilentlyContinue
        if ($existing -and $existing.Contains('managed by ConfigMe')) {
            Remove-Item -LiteralPath $Destination -Force
            return $true
        }
    }

    $backup = "$Destination.bak"
    if (Test-Path -LiteralPath $backup) {
        if (-not $Force) {
            Write-Host "  SKIP $Destination - $backup already exists (use -Force)" -ForegroundColor Yellow
            return $false
        }
        Remove-Item -LiteralPath $backup -Recurse -Force
    }
    Write-Host "  backing up $Destination -> $backup" -ForegroundColor DarkYellow
    Move-Item -LiteralPath $Destination -Destination $backup -Force
    return $true
}

function New-DirLink {
    # Directory targets: a junction reads exactly like a symlink and needs no
    # privilege, so prefer it unconditionally over a symlink.
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "  skip $Destination (no $Source)" -ForegroundColor DarkGray
        return
    }
    if (-not (Clear-Destination $Destination)) { return }

    New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
    Write-Host "  junction $Destination" -ForegroundColor Green
}

function New-Shim {
    # File targets: write a real file whose contents tell the consuming tool to
    # read the repo copy, using that tool's own include mechanism.
    param(
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Content
    )

    if (-not (Clear-Destination $Destination)) { return }

    # ASCII, LF, no BOM: bash chokes on CRLF and on a UTF-8 BOM at the top of a
    # sourced file, and git's config parser dislikes a BOM equally.
    $text = ($Content -replace "`r`n", "`n")
    [IO.File]::WriteAllText($Destination, $text, (New-Object Text.UTF8Encoding $false))
    Write-Host "  shim $Destination" -ForegroundColor Green
}

Write-Host "==> dotfiles: $Dotfiles"
Write-Host "==> target:   $env:USERPROFILE"
Write-Host ''

Write-Host '==> nvim'
New-DirLink -Source (Join-Path $Dotfiles 'nvim') -Destination (Join-Path $env:LOCALAPPDATA 'nvim')

Write-Host '==> bash (Git Bash / MinGW)'
# The whole bash/ directory is junctioned into place, which is what makes
# ~/.config/dotfiles/common.sh resolve -- the same path the Linux and macOS
# installs use, so common.sh needs no per-platform lookup logic.
New-DirLink -Source (Join-Path $Dotfiles 'bash') -Destination (Join-Path $env:USERPROFILE '.config\dotfiles')
New-Shim -Destination (Join-Path $env:USERPROFILE '.bashrc') -Content @"
# managed by ConfigMe -- edit $DotfilesPosix/bash/bashrc.windows instead
. "$DotfilesPosix/bash/bashrc.windows"
"@
New-Shim -Destination (Join-Path $env:USERPROFILE '.bash_profile') -Content @"
# managed by ConfigMe -- edit $DotfilesPosix/bash/bash_profile.windows instead
. "$DotfilesPosix/bash/bash_profile.windows"
"@

Write-Host '==> git'
# core.excludesfile is re-pointed after the include so it resolves to the repo
# copy; the shared config sets it to ~/.gitignore_global, which does not exist
# on this side.
New-Shim -Destination (Join-Path $env:USERPROFILE '.gitconfig') -Content @"
# managed by ConfigMe -- edit $DotfilesPosix/git/config instead
[include]
	path = $DotfilesPosix/git/config
[core]
	excludesfile = $DotfilesPosix/git/gitignore_global
"@

Write-Host '==> wezterm'
New-Shim -Destination (Join-Path $env:USERPROFILE '.wezterm.lua') -Content @"
-- managed by ConfigMe -- edit $DotfilesPosix/wezterm/wezterm.lua instead
return dofile("$DotfilesPosix/wezterm/wezterm.lua")
"@

Write-Host '==> claude'
# .claude\skills on this machine is a tree of links into %USERPROFILE%\.agents
# and is managed separately, so only memory and CLAUDE.md are mirrored.
New-DirLink -Source (Join-Path $Dotfiles 'claude\memory') -Destination (Join-Path $env:USERPROFILE '.claude\memory')
New-Shim -Destination (Join-Path $env:USERPROFILE '.claude\CLAUDE.md') -Content @"
<!-- managed by ConfigMe -- edit $DotfilesPosix/claude/CLAUDE.md instead -->
@$DotfilesPosix/claude/CLAUDE.md
"@

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host 'This clone is a read-only mirror. Edit in WSL, push, then pull here.' -ForegroundColor DarkGray
