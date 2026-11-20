# agent-jack-setup INSTALL (Windows 11). Idempotent: brings each component to the exact pin in versions.env.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File bin/install.ps1 <claude|codex|t3|tentacles|classify|guardian|all>
# (all = claude codex t3 tentacles classify; guardian = optional guard checkout). The policy flag applies to this process only.
# No administrator rights: winget portable (user scope), npm -g into %APPDATA%\npm, checkouts under ~\Developer, venv under ~\.agent-jack.
# Never touches secrets; downloads only from the public sources in versions.env. Windows PowerShell 5.1 syntax only; ASCII only.
param([Parameter(Position = 0)][string]$Component)
# Continue, not Stop: on 5.1, Stop turns a native tool's redirected stderr into a terminating error. Every step checks its own result.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$Here = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'versions.ps1')
$P = Read-Versions (Join-Path $Here 'versions.env')
$Dev = Join-Path $HOME 'Developer'

function Die($Code, $Msg) { [Console]::Error.WriteLine("FAIL ${Code}: $Msg"); exit 1 }
function Need-Pin($Value, $Name) { if ($Value -eq 'TBD') { Die AJ-PIN-00 "pin $Name not published yet (versions.env)" } }
function Run([string]$Exe, [string[]]$ArgList, $Code, $Msg) {
  & $Exe @ArgList
  if ($LASTEXITCODE -ne 0) { Die $Code $Msg }
}
function Checkout([string]$Repo, [string]$Dir, [string]$Tag) {
  $git = Find-Tool 'git'; if (-not $git) { Die AJ-GIT-01 'git missing (winget install --id Git.Git -e --source winget --scope user)' }
  New-Item -ItemType Directory -Force -Path $Dev | Out-Null
  if (-not (Test-Path -LiteralPath (Join-Path $Dir '.git'))) { Run $git @('clone', '-q', ($Repo + '.git'), $Dir) AJ-GIT-01 "git clone $Repo failed" }
  Run $git @('-C', $Dir, 'fetch', '-q', '--tags', 'origin') AJ-GIT-01 "git fetch $Repo failed"
  Run $git @('-C', $Dir, '-c', 'advice.detachedHead=false', 'checkout', '-q', $Tag) AJ-GIT-01 "git checkout $Tag failed"
}

function Do-Claude {
  $cur = Get-Ver (Find-Tool 'claude') '--version'
  if ($cur -and (Ge $cur $P.CLAUDE_CLI_MIN)) { "ok claude-cli $cur (>= $($P.CLAUDE_CLI_MIN))"; return }
  $wg = Find-Tool 'winget'; if (-not $wg) { Die AJ-WINGET-01 'winget missing (Microsoft Store: App Installer)' }
  Run $wg @('install', '--id', $P.CLAUDE_WINGET_ID, '-e', '--version', $P.CLAUDE_CLI_MIN, '--source', 'winget', '--scope', 'user', '--accept-source-agreements', '--accept-package-agreements') AJ-CLAUDE-01 'winget install of Claude Code failed'
  "ok claude-cli $($P.CLAUDE_CLI_MIN) (the scripts refresh PATH themselves; in your own commands put the PATH line from SETUP-PROMPT-WINDOWS.md at the start of the same command; sign in yourself: claude auth login)"
}

function Do-Codex {
  # npm, not winget: winget's OpenAI.Codex pulls the VC++ runtime, which can need an administrator.
  $npm = Find-Tool 'npm'; if (-not $npm) { Die AJ-NODE-01 'node/npm missing (winget install --id OpenJS.NodeJS.LTS -e --source winget)' }
  $cur = Get-Ver (Find-Tool 'codex') '--version'
  if ($cur -and (Ge $cur $P.CODEX_CLI_MIN)) { "ok codex-cli $cur (>= $($P.CODEX_CLI_MIN))"; return }
  Run $npm @('install', '-g', "@openai/codex@$($P.CODEX_CLI_MIN)") AJ-CODEX-01 'npm install failed (see REPAIR.md AJ-NPM-01)'
  "ok codex-cli $($P.CODEX_CLI_MIN) (sign in yourself: codex login)"
}

function Do-T3 {
  Need-Pin $P.T3_ASSET_WIN_X64 T3_ASSET_WIN_X64
  $have = Get-InstalledApp ($P.T3_APP_NAME + '*')
  if ($have -and $have.DisplayVersion -eq $P.T3_VERSION) { "ok t3code $($P.T3_VERSION)"; return }
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('aj-t3-' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    $file = Join-Path $tmp $P.T3_ASSET_WIN_X64
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    try { Invoke-WebRequest -Uri "$($P.T3_REPO)/releases/download/$($P.T3_TAG)/$($P.T3_ASSET_WIN_X64)" -OutFile $file -UseBasicParsing -ErrorAction Stop } catch { Die AJ-T3-03 'download failed' }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLower() -ne $P.T3_SHA256_WIN_X64) { Die AJ-T3-04 'checksum mismatch, not installing' }
    # the installer runs in front of the person; SmartScreen: "More info" > "Run anyway" (REPAIR.md AJ-T3-05)
    $proc = Start-Process -FilePath $file -PassThru -Wait
    if ($proc.ExitCode -ne 0) { Die AJ-T3-03 "installer exited with $($proc.ExitCode)" }
  } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
  "ok t3code $($P.T3_VERSION)"
}

function Do-Tentacles {
  Need-Pin $P.TENTACLES_TAG TENTACLES_TAG
  $dir = Join-Path $Dev 't3-code-tentacles'
  Checkout $P.TENTACLES_REPO $dir $P.TENTACLES_TAG
  $head = Last-Line (& (Find-Tool 'git') -C $dir rev-parse HEAD)
  if ($head -ne $P.TENTACLES_COMMIT) { Die AJ-TENT-02 "checkout is $head, want $($P.TENTACLES_COMMIT)" }
  # Tentacles has no npm dependencies; the agent and doctor run it as bin\tentacles.cmd (npm link's command shim needs /bin/sh).
  $v = Get-Ver (Join-Path $dir 'bin\tentacles.cmd') '--version'
  if ($v -ne $P.TENTACLES_VERSION) { Die AJ-TENT-01 "bin\tentacles.cmd --version gave '$v'" }
  # npm link still matters: it puts the checkout at %APPDATA%\npm\node_modules\tentacles, where Agent Jack desktop finds the pairer.
  $npm = Find-Tool 'npm'; if (-not $npm) { Die AJ-NODE-01 'node/npm missing (winget install --id OpenJS.NodeJS.LTS -e --source winget)' }
  Push-Location -LiteralPath $dir
  & $npm link --no-audit --no-fund --loglevel=error
  $rc = $LASTEXITCODE
  Pop-Location
  if ($rc -ne 0) { Die AJ-TENTLINK-01 'npm link failed (see REPAIR.md AJ-NPM-01)' }
  if (-not (Test-Path -LiteralPath (Join-Path (Get-TentaclesLinkDir) 'src\cli.mjs'))) { Die AJ-TENTLINK-01 'npm link did not reach %APPDATA%\npm (see REPAIR.md AJ-TENTLINK-01)' }
  "ok tentacles $v @ $($P.TENTACLES_TAG) (~\Developer\t3-code-tentacles, linked for Agent Jack)"
}

function Do-Classify {
  Need-Pin $P.GUARDIAN_TAG GUARDIAN_TAG
  $vpy = Join-Path $P.CLASSIFY_VENV 'Scripts\python.exe'
  if (-not (Test-Path -LiteralPath $vpy)) {
    # the py launcher, never bare "python" (that can open the Microsoft Store)
    $py = Find-Tool 'py'; if (-not $py) { Die AJ-PY-01 "Python >= $($P.PYTHON_MIN) needed (winget install --id Python.Python.3.12 -e --source winget --scope user)" }
    $pick = $null
    foreach ($v in '-3.13', '-3.12', '-3.11') { & $py $v -c 'import sys' 2>$null; if ($LASTEXITCODE -eq 0) { $pick = $v; break } }
    if (-not $pick) { Die AJ-PY-01 "Python >= $($P.PYTHON_MIN) needed (winget install --id Python.Python.3.12 -e --source winget --scope user)" }
    Run $py @($pick, '-m', 'venv', $P.CLASSIFY_VENV) AJ-EC-01 'python venv failed'
  }
  Run $vpy @('-m', 'pip', 'install', '-q', '--upgrade', '--force-reinstall', "git+$($P.GUARDIAN_REPO).git@$($P.GUARDIAN_TAG)") AJ-EC-01 'pip install of estate-classify failed'
  "ok estate-classify @ $($P.GUARDIAN_TAG) in ~\.agent-jack\venv"
}

function Do-Guardian {
  Need-Pin $P.GUARDIAN_TAG GUARDIAN_TAG
  Checkout $P.GUARDIAN_REPO (Join-Path $Dev 'estate-guardian') $P.GUARDIAN_TAG
  "ok estate-guardian guard checkout @ $($P.GUARDIAN_TAG) (optional; no scheduled task is created)"
}

$freeGB = Get-FreeGB
if ($freeGB -lt [int]$P.DISK_FAIL_GB) { Die AJ-DISK-02 "only $freeGB GB free; need at least $($P.DISK_FAIL_GB) GB (recommended $($P.DISK_WARN_GB) GB). See REPAIR.md AJ-DISK-02" }
switch ($Component) {
  'claude' { Do-Claude } 'codex' { Do-Codex } 't3' { Do-T3 } 'tentacles' { Do-Tentacles } 'classify' { Do-Classify } 'guardian' { Do-Guardian }
  # until the Windows T3 build is published, `all` installs the rest and doctor reports AJ-PIN-00 for T3
  'all' { Do-Claude; Do-Codex; if ($P.T3_ASSET_WIN_X64 -eq 'TBD') { 'WAIT t3code: Windows build not published yet (AJ-PIN-00)' } else { Do-T3 }; Do-Tentacles; Do-Classify }
  default { 'usage: powershell -NoProfile -ExecutionPolicy Bypass -File bin/install.ps1 <claude|codex|t3|tentacles|classify|guardian|all>'; exit 2 }
}
'next: powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1'
