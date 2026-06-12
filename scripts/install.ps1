# botopink installer — Windows PowerShell.
#
# Usage:
#   iex (irm 'https://botopink.dev/install.ps1')
#   .\install.ps1 [-Target <tuple>] [-Version <v>] [-InstallDir <path>]
#                 [-Force] [-Quiet]
#
# Env (lower precedence than flags):
#   BOTOPINK_VERSION         - pin a release tag (default: latest)
#   BOTOPINK_INSTALL_DIR     - override $BPMP_HOME (default: %USERPROFILE%\.bpmp)
#   BOTOPINK_INSTALL_FORCE=1 - overwrite an existing install
#
# Refuses to clobber an existing $BPMP_HOME unless -Force / env override.
# Symlink fallback: if `New-Item -ItemType SymbolicLink` errors (no developer
# mode, no admin), falls back to a copy and prints a one-line note.

[CmdletBinding()]
param(
    [string]$Target,
    [string]$Version,
    [string]$InstallDir,
    [switch]$Force,
    [switch]$Quiet,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
    if (-not $Quiet) { Write-Host $msg }
}

function Fail($msg, $code = 1) {
    Write-Error $msg
    exit $code
}

if ($Help) {
    @"
botopink installer (Windows)

Usage:
  .\install.ps1 [-Target <tuple>] [-Version <v>] [-InstallDir <path>]
                [-Force] [-Quiet]

Supported targets:
  windows-x86_64

Env (lower precedence than flags):
  BOTOPINK_VERSION         pin a release tag (default: latest)
  BOTOPINK_INSTALL_DIR     override `$BPMP_HOME (default: %USERPROFILE%\.bpmp)
  BOTOPINK_INSTALL_FORCE=1 overwrite an existing install
"@ | Write-Host
    exit 0
}

# ── Target detection ───────────────────────────────────────────────────────

if (-not $Target) {
    $arch = switch ($env:PROCESSOR_ARCHITECTURE) {
        'AMD64' { 'x86_64' }
        'ARM64' { Fail 'windows-aarch64 is not a supported target in v0.beta.18' }
        default { Fail "unsupported arch: $($env:PROCESSOR_ARCHITECTURE)" }
    }
    $Target = "windows-$arch"
}
Write-Step "detected target: $Target"

if ($Target -ne 'windows-x86_64') {
    Fail "install.ps1 supports only windows-x86_64 (got $Target). Use install.sh on linux/macos."
}
$Ext = 'zip'

# ── Version ────────────────────────────────────────────────────────────────

if (-not $Version) {
    $Version = if ($env:BOTOPINK_VERSION) { $env:BOTOPINK_VERSION } else { 'latest' }
}

$repoOwner = 'botopink'
$repoName  = 'botopink-lang'

if ($Version -eq 'latest') {
    $urlBase = "https://github.com/$repoOwner/$repoName/releases/latest/download"
    Write-Step "resolving latest version (via GitHub's releases/latest/download redirect)"
} else {
    $urlBase = "https://github.com/$repoOwner/$repoName/releases/download/$Version"
    Write-Step "version pin: $Version"
}

# ── Install root ───────────────────────────────────────────────────────────

if (-not $InstallDir) {
    $InstallDir = if ($env:BOTOPINK_INSTALL_DIR) { $env:BOTOPINK_INSTALL_DIR } else { Join-Path $env:USERPROFILE '.bpmp' }
}
$BpmpHome = $InstallDir
Write-Step "install root: $BpmpHome"

if (Test-Path $BpmpHome) {
    $existing = Get-ChildItem -Force -ErrorAction SilentlyContinue $BpmpHome
    $forceOverride = $Force -or ($env:BOTOPINK_INSTALL_FORCE -eq '1')
    if ($existing -and -not $forceOverride) {
        Fail @"
`$BPMP_HOME ($BpmpHome) already exists.
       To upgrade, run:    bpmp self update
       To start over, run: bpmp self uninstall   (then re-run this installer)
       To force overwrite: `$env:BOTOPINK_INSTALL_FORCE = '1'; .\install.ps1
"@
    } elseif ($existing) {
        Write-Warning "`$BPMP_HOME exists - overwriting (BOTOPINK_INSTALL_FORCE)"
    }
}

# ── Layout helpers ─────────────────────────────────────────────────────────

$VersionDir = Join-Path $BpmpHome "botopink\versions\$Version"
New-Item -ItemType Directory -Force -Path $VersionDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BpmpHome 'bin') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BpmpHome 'botopink\versions') | Out-Null

$TmpDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "botopink-install-$([guid]::NewGuid().ToString('N'))")
try {
    $Binaries = @('botopink', 'botopink-lsp', 'botopink-lib-test', 'bpmp')
    foreach ($bin in $Binaries) {
        $archiveName = "$bin-$Version-$Target.$Ext"
        $shaName     = "$archiveName.sha256"
        $archivePath = Join-Path $TmpDir.FullName $archiveName
        $shaPath     = Join-Path $TmpDir.FullName $shaName

        Write-Step "downloading $bin ... ($urlBase/$archiveName)"
        Invoke-WebRequest -UseBasicParsing -Uri "$urlBase/$archiveName" -OutFile $archivePath
        Invoke-WebRequest -UseBasicParsing -Uri "$urlBase/$shaName" -OutFile $shaPath

        $want = (Get-Content -Raw $shaPath).Trim() -split '\s+' | Select-Object -First 1
        $got = (Get-FileHash -Algorithm SHA256 $archivePath).Hash.ToLowerInvariant()
        if ($want -ne $got) {
            Fail "sha256 mismatch for $bin`n  expected: $want`n  got:      $got"
        }
        Write-Step "  verified sha256 ($want)"

        Expand-Archive -LiteralPath $archivePath -DestinationPath $VersionDir -Force
    }
} finally {
    Remove-Item -Recurse -Force $TmpDir.FullName -ErrorAction SilentlyContinue
}

# ── stable / bin shim ──────────────────────────────────────────────────────

$StableLink = Join-Path $BpmpHome 'botopink\versions\stable'
if (Test-Path $StableLink) { Remove-Item -Force -Recurse $StableLink }

$linkOk = $true
try {
    New-Item -ItemType SymbolicLink -Path $StableLink -Target $VersionDir | Out-Null
} catch {
    $linkOk = $false
    Write-Warning "SymbolicLink failed (developer mode off?) - falling back to directory copy. `bpmp self update` may take a tick longer to swap."
    Copy-Item -Recurse -Force $VersionDir $StableLink
}
Write-Step "stable -> $Version"

$BinShim = Join-Path $BpmpHome 'bin\bpmp.exe'
if (Test-Path $BinShim) { Remove-Item -Force $BinShim }
try {
    if ($linkOk) {
        New-Item -ItemType SymbolicLink -Path $BinShim -Target (Join-Path $StableLink 'bpmp.exe') | Out-Null
    } else {
        Copy-Item -Force (Join-Path $StableLink 'bpmp.exe') $BinShim
    }
} catch {
    Copy-Item -Force (Join-Path $StableLink 'bpmp.exe') $BinShim
}
Write-Step "bin\bpmp.exe -> bpmp"

# ── Post-install messaging ────────────────────────────────────────────────

Write-Step ''
Write-Step "botopink $Version installed at $BpmpHome."
@"

Add to your PowerShell profile (`$PROFILE`):
  `$env:Path = "$BpmpHome\bin;" + `$env:Path

Verify with:
  bpmp version
  botopink --version
"@ | Write-Host
