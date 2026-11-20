# agent-jack-setup: shared helpers for bin\doctor.ps1 and bin\install.ps1 (dot-sourced, never run alone).
# Windows PowerShell 5.1 syntax only; ASCII only.

# The AI app's shell keeps the PATH it started with, so a fresh winget install is invisible to it.
# Add Machine + User PATH after this process's own entries (so the app's own tools keep priority); SETUP-PROMPT-WINDOWS
# and REPAIR.md give the agent this exact line. shortcut: splits on every ';', so a quoted PATH entry containing ';'
# (legal, rare) is broken up; parse quotes if a real install ever needs one.
$env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'

# versions.env -> hashtable. KEY=VALUE lines; "# comment" stripped, surrounding quotes removed, $HOME expanded.
function Read-Versions([string]$Path) {
  $p = @{}
  foreach ($raw in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    $line = ($raw -replace '#.*$', '').Trim()
    if (-not $line) { continue }
    $i = $line.IndexOf('=')
    if ($i -lt 1) { continue }
    $v = $line.Substring($i + 1).Trim().Trim('"')
    if ($v.StartsWith('$HOME')) { $v = $HOME + $v.Substring(5).Replace('/', '\') }
    $p[$line.Substring(0, $i)] = $v
  }
  return $p
}

# A command's full path: PATH first (executables only, so npm's blocked .ps1 shims are skipped),
# then the per-user folders winget, npm and the native installers use before a new terminal picks them up.
function Find-Tool([string]$Name) {
  $c = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Where-Object { $_.Source -match '\.(exe|cmd|bat)$' } | Select-Object -First 1
  if ($c) { return $c.Source }
  $dirs = @((Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'), (Join-Path $env:APPDATA 'npm'), (Join-Path $HOME '.local\bin'), (Join-Path $env:LOCALAPPDATA 'Programs\codex'))
  foreach ($d in $dirs) { foreach ($ext in '.exe', '.cmd') { $f = Join-Path $d ($Name + $ext); if (Test-Path -LiteralPath $f) { return $f } } }
  return $null
}

# Run a program with stdin closed and a time limit; returns @{ Code; Out; Err }. Code -1 = timed out (process tree killed).
function Invoke-Bounded([string]$Exe, [string[]]$ArgList, [int]$Seconds, [string]$Dir) {
  if (-not $Exe) { return @{ Code = -2; Out = '' } }
  # shortcut: escapes only embedded double quotes, not backslashes before a quote or at the end of an argument
  # (Windows C runtime rules); no caller passes such an argument today. Upgrade to full CommandLineToArgvW quoting if one does.
  $quoted = ($ArgList | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }) -join ' '
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  if ($Exe -match '\.(cmd|bat)$') { $psi.FileName = $env:ComSpec; $psi.Arguments = '/d /s /c ""' + $Exe + '" ' + $quoted + '"' }
  else { $psi.FileName = $Exe; $psi.Arguments = $quoted }
  $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
  $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
  if ($Dir) { $psi.WorkingDirectory = $Dir }
  try { $proc = [System.Diagnostics.Process]::Start($psi) } catch { return @{ Code = -2; Out = '' } }
  $proc.StandardInput.Close()
  $out = $proc.StandardOutput.ReadToEndAsync(); $err = $proc.StandardError.ReadToEndAsync()
  if (-not $proc.WaitForExit($Seconds * 1000)) {
    & "$env:SystemRoot\System32\taskkill.exe" /PID $proc.Id /T /F 2>$null | Out-Null
    return @{ Code = -1; Out = ''; Err = '' }
  }
  $proc.WaitForExit()
  return @{ Code = $proc.ExitCode; Out = $out.Result; Err = $err.Result }
}

function Last-Line($Text) {
  $lines = @(("$Text" -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  if ($lines.Count -eq 0) { return '' }
  return $lines[-1]
}

# First x.y.z[-suffix] in a program's version output, or $null.
function Get-Ver([string]$Exe, [string]$Arg) {
  if (-not $Exe) { return $null }
  $r = Invoke-Bounded $Exe @($Arg) 30
  $m = [regex]::Match("$($r.Out)", '[0-9]+\.[0-9]+\.[0-9]+[-A-Za-z0-9.]*')
  if ($m.Success) { return $m.Value } else { return $null }
}

# $A >= $B on the numeric x.y.z part (CLI minimums are plain releases).
function Ge($A, $B) {
  $ma = [regex]::Match("$A", '^[0-9]+\.[0-9]+\.[0-9]+'); $mb = [regex]::Match("$B", '^[0-9]+\.[0-9]+\.[0-9]+')
  if (-not $ma.Success -or -not $mb.Success) { return $false }
  return ([version]$ma.Value -ge [version]$mb.Value)
}

# Free GB on the home drive; a UNC (redirected) profile has no drive letter, so fall back to the system drive.
function Get-FreeGB {
  $d = $HOME.Substring(0, 2)
  if ($d -notmatch '^[A-Za-z]:$') { $d = $env:SystemDrive }
  $disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $d + "'")
  return [math]::Floor($disk.FreeSpace / 1GB)
}

# Where Agent Jack desktop looks for the Tentacles pairer on Windows (resolveTentaclesLaunch): the npm link / npm -g location.
function Get-TentaclesLinkDir { return (Join-Path $env:APPDATA 'npm\node_modules\tentacles') }

# An installed program's uninstall entry (per-user first, then machine-wide), or $null.
function Get-InstalledApp([string]$Like) {
  $keys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
  foreach ($k in $keys) {
    $hit = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $Like } | Select-Object -First 1
    if ($hit) { return $hit }
  }
  return $null
}

# Same dry check as `bin/doctor.sh --selftest`: parse, checksum/commit format, every pinned URL and tag answers.
# Prints one line per check and leaves the FAIL count in $script:stf. Installs and changes nothing; runs on Windows PowerShell 5.1 and PowerShell 7 (any OS).
function Invoke-SelfTest($P, [string]$Here) {
  $script:stf = 0
  function Ok($m) { "PASS selftest $m" | Write-Output }
  function Bad($m) { "FAIL selftest $m" | Write-Output; $script:stf++ }
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  function Answers([string]$Url) {
    try { $null = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 10; return $true } catch { return $false }
  }
  function TagSha([string]$Repo, [string]$Tag) {
    $lines = @(& git ls-remote ($Repo + '.git') "refs/tags/$Tag" "refs/tags/$Tag^{}" 2>$null)
    if ($lines.Count -eq 0) { return '' }
    return ($lines[-1] -split '\s+')[0]
  }
  $file = Join-Path $Here 'versions.env'
  foreach ($raw in (Get-Content -LiteralPath $file -Encoding UTF8)) {
    $line = ($raw -replace '#.*$', '').Trim()
    if (-not $line) { continue }
    if ($line -cnotmatch '^[A-Z0-9_]+=([^\s"]+|"[^"]+")$') { Bad "parse: $line" }
  }
  foreach ($k in @($P.Keys | Where-Object { $_ -like '*SHA256*' } | Sort-Object)) {
    $v = $P[$k]
    if ($v -eq 'TBD' -or $v -cmatch '^[0-9a-f]{64}$') { Ok "checksum $k" } else { Bad "checksum $k is not 64 lowercase hex or TBD" }
    $a = $P[$k.Replace('SHA256', 'ASSET')]; if (-not $a) { $a = 'TBD' }
    if (($a -eq 'TBD') -ne ($v -eq 'TBD')) { Bad "checksum $k and $($k.Replace('SHA256', 'ASSET')) disagree on TBD" }
  }
  if ($P.TENTACLES_COMMIT -cmatch '^[0-9a-f]{40}$') { Ok 'commit TENTACLES_COMMIT' } else { Bad 'commit TENTACLES_COMMIT is not 40 hex' }
  if ($P.GUARDIAN_COMMIT -cmatch '^[0-9a-f]{7,40}$') { Ok 'commit GUARDIAN_COMMIT' } else { Bad 'commit GUARDIAN_COMMIT is not hex' }
  $wid = $P.CLAUDE_WINGET_ID
  $urls = @($P.SETUP_REPO, $P.T3_REPO, $P.TENTACLES_REPO, $P.GUARDIAN_REPO,
    "https://registry.npmjs.org/@openai/codex/$($P.CODEX_CLI_MIN)", "https://registry.npmjs.org/@anthropic-ai/claude-code/$($P.CLAUDE_CLI_MIN)",
    ("https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/" + $wid.Substring(0, 1).ToLower() + '/' + $wid.Replace('.', '/') + "/$($P.CLAUDE_CLI_MIN)/$wid.yaml"))
  foreach ($u in $urls) { if (Answers $u) { Ok "url $u" } else { Bad "url $u does not answer" } }
  foreach ($k in @($P.Keys | Where-Object { $_ -like 'T3_ASSET_*' } | Sort-Object)) {
    if ($P[$k] -eq 'TBD') { "SKIP selftest asset $k not published yet (AJ-PIN-00)"; continue }
    $u = "$($P.T3_REPO)/releases/download/$($P.T3_TAG)/$($P[$k])"
    if (Answers $u) { Ok "asset $u" } else { Bad "asset $u does not answer" }
  }
  if (TagSha $P.T3_REPO $P.T3_TAG) { Ok "tag $($P.T3_TAG) on $($P.T3_REPO)" } else { Bad "tag $($P.T3_TAG) missing on $($P.T3_REPO)" }
  $got = TagSha $P.TENTACLES_REPO $P.TENTACLES_TAG
  if ($got -eq $P.TENTACLES_COMMIT) { Ok "tag $($P.TENTACLES_TAG) = $got" } else { Bad "tag $($P.TENTACLES_TAG) = $got, want $($P.TENTACLES_COMMIT)" }
  $got = TagSha $P.GUARDIAN_REPO $P.GUARDIAN_TAG; $want = $P.GUARDIAN_COMMIT
  if ($got -and $got.StartsWith($want)) { Ok "tag $($P.GUARDIAN_TAG) = $want" } else { Bad "tag $($P.GUARDIAN_TAG) = $got, want $want" }
  "selftest fails: $($script:stf)"
}
