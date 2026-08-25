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
    Runs without elevation. Developer Mode improves the result but is not
    required; the script probes for symlink permission and adapts.

    Three linking mechanisms, chosen per target rather than uniformly:

      * Directories use junctions. A junction reads identically to a symlink
        but needs no privilege, so nvim and the rest keep working even if
        Developer Mode is later turned off by policy or a reset. There is no
        upside to a directory symlink here.

      * Read-only single files use symlinks when permitted, because a symlink
        is transparent: an editor opening the path sees the real config, and
        nothing depends on the consuming tool supporting an include syntax.
        When symlinks are unavailable these fall back to shims (below), so the
        install still completes on a locked-down machine.

      * .gitconfig always uses an [include] shim, deliberately, even when
        symlinks are available. Git writes config by write-and-rename, which
        would replace a symlink with a regular file and silently strand the
        mirror. [include] is git's own supported mechanism and survives that.
        A consequence worth knowing: `git config --global ...` appends to the
        shim after the [include] line, so machine-local settings override the
        repo and are not tracked. That is the intended behaviour for
        machine-local overrides, but it is not obvious.

    Hard links were deliberately NOT used anywhere. `git pull` writes a new
    file and renames it over the old one, which severs a hard link -- the
    mirror would silently stop updating.

    Removing a junction by hand needs care: Remove-Item -Recurse in
    PowerShell 5.1 follows a junction and deletes the TARGET's contents, which
    here means the repo itself. Use (Get-Item x -Force).Delete() instead --
    which is what Clear-Destination does.

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

# PowerShell 5.1's New-Item -ItemType SymbolicLink calls CreateSymbolicLinkW
# WITHOUT SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE, so it fails for a
# non-elevated user even when Developer Mode is on -- Developer Mode is exactly
# what that flag unlocks. PowerShell 7 fixed this; 5.1 never will. Call the API
# directly so Developer Mode is actually usable.
Add-Type -Namespace ConfigMe -Name Native -MemberDefinition @'
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool CreateSymbolicLinkW(string link, string target, int flags);
'@

function New-Symlink {
    param(
        [Parameter(Mandatory)][string]$Link,
        [Parameter(Mandatory)][string]$Target,
        [switch]$Directory
    )

    $base = if ($Directory) { 0x1 } else { 0x0 }

    # 0x2 is ALLOW_UNPRIVILEGED_CREATE. Windows builds without Developer Mode
    # support reject the unknown flag outright with ERROR_INVALID_PARAMETER, so
    # retry without it before giving up.
    if ([ConfigMe.Native]::CreateSymbolicLinkW($Link, $Target, $base -bor 0x2)) { return $true }
    if ([ConfigMe.Native]::CreateSymbolicLinkW($Link, $Target, $base)) { return $true }
    return $false
}

function Test-SymlinkCapability {
    # Probe with a real attempt rather than reading the Developer Mode registry
    # value: what matters is whether this process can actually create one, and
    # a failure is not an error condition -- it just selects the shim path.
    $probe = Join-Path $env:TEMP ('configme-symlink-probe-' + [guid]::NewGuid())
    if (New-Symlink -Link $probe -Target $env:TEMP -Directory) {
        (Get-Item $probe -Force).Delete()
        return $true
    }
    return $false
}

$CanSymlink = Test-SymlinkCapability

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

function New-FileLink {
    # Read-only file targets. Prefers a transparent symlink; falls back to the
    # supplied shim text when symlinks are not permitted, so the install still
    # completes without Developer Mode.
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Shim
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "  skip $Destination (no $Source)" -ForegroundColor DarkGray
        return
    }

    if ($script:CanSymlink) {
        if (-not (Clear-Destination $Destination)) { return }
        if (New-Symlink -Link $Destination -Target $Source) {
            Write-Host "  symlink $Destination" -ForegroundColor Green
        } else {
            # Privilege was probed successfully, so a failure here is specific
            # to this path. Fall back rather than aborting the whole install.
            Write-Host "  symlink failed, using shim: $Destination" -ForegroundColor Yellow
            New-Shim -Destination $Destination -Content $Shim
        }
    } else {
        New-Shim -Destination $Destination -Content $Shim
    }
}

Write-Host "==> dotfiles: $Dotfiles"
Write-Host "==> target:   $env:USERPROFILE"
Write-Host ("==> file links: " + $(if ($CanSymlink) { 'symlinks' } else { 'shims (no symlink privilege)' }))
Write-Host ''

Write-Host '==> nvim'
New-DirLink -Source (Join-Path $Dotfiles 'nvim') -Destination (Join-Path $env:LOCALAPPDATA 'nvim')

Write-Host '==> bash (Git Bash / MinGW)'
# The whole bash/ directory is junctioned into place, which is what makes
# ~/.config/dotfiles/common.sh resolve -- the same path the Linux and macOS
# installs use, so common.sh needs no per-platform lookup logic.
New-DirLink -Source (Join-Path $Dotfiles 'bash') -Destination (Join-Path $env:USERPROFILE '.config\dotfiles')
New-FileLink -Source (Join-Path $Dotfiles 'bash\bashrc.windows') `
             -Destination (Join-Path $env:USERPROFILE '.bashrc') `
             -Shim @"
# managed by ConfigMe -- edit $DotfilesPosix/bash/bashrc.windows instead
. "$DotfilesPosix/bash/bashrc.windows"
"@
New-FileLink -Source (Join-Path $Dotfiles 'bash\bash_profile.windows') `
             -Destination (Join-Path $env:USERPROFILE '.bash_profile') `
             -Shim @"
# managed by ConfigMe -- edit $DotfilesPosix/bash/bash_profile.windows instead
. "$DotfilesPosix/bash/bash_profile.windows"
"@

Write-Host '==> git'
# Deliberately a shim even when symlinks are available: git writes config by
# write-and-rename, which would replace a symlink with a regular file and
# strand the mirror. See .NOTES.
#
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
New-FileLink -Source (Join-Path $Dotfiles 'wezterm\wezterm.lua') `
             -Destination (Join-Path $env:USERPROFILE '.wezterm.lua') `
             -Shim @"
-- managed by ConfigMe -- edit $DotfilesPosix/wezterm/wezterm.lua instead
return dofile("$DotfilesPosix/wezterm/wezterm.lua")
"@

Write-Host '==> claude'
# .claude\skills on this machine is a tree of links into %USERPROFILE%\.agents
# and is managed separately, so only memory and CLAUDE.md are mirrored.
New-DirLink -Source (Join-Path $Dotfiles 'claude\memory') -Destination (Join-Path $env:USERPROFILE '.claude\memory')
New-FileLink -Source (Join-Path $Dotfiles 'claude\CLAUDE.md') `
             -Destination (Join-Path $env:USERPROFILE '.claude\CLAUDE.md') `
             -Shim @"
<!-- managed by ConfigMe -- edit $DotfilesPosix/claude/CLAUDE.md instead -->
@$DotfilesPosix/claude/CLAUDE.md
"@

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host 'This clone is a read-only mirror. Edit in WSL, push, then pull here.' -ForegroundColor DarkGray
