# agent-jack-setup DOCTOR (Windows 11). Read-only: it changes nothing.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1 [-Json] [-SelfTest]
# (-ExecutionPolicy Bypass applies to this one process only; the machine policy is never changed.)
# Same line format and check ids as bin/doctor.sh; Windows-only ids: AJ-WINGET-*, AJ-SYS-02, AJ-TENTLINK-*.
# WAIT = waits for the Windows build of T3 Code TPLUS (T3, Tentacles doctor, Local Bot); like WARN it never fails the run.
# Exit 0 = all PASS/SKIP/WARN/WAIT, 1 = at least one FAIL. No secrets, e-mails or home paths are printed (home is shown as ~).
# Windows PowerShell 5.1 syntax only (no &&, ||, ?:, ??); ASCII only, because 5.1 reads BOM-less files as ANSI.
# Arguments to native programs never contain double quotes: 5.1 drops them (python -c code uses single quotes).
param([switch]$Json, [switch]$SelfTest)
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$Here = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'versions.ps1')
$P = Read-Versions (Join-Path $Here 'versions.env')

$script:Fails = 0
$script:Out = New-Object System.Collections.ArrayList
function Rec($Status, $Code, $Component, $Found, $Expected, $Source) {
  if ($Status -eq 'FAIL') { $script:Fails++ }
  [void]$script:Out.Add([pscustomobject]@{ status = $Status; code = $Code; component = $Component; found = "$Found"; expected = "$Expected"; source = $Source })
}
function Home-Tilde([string]$s) { if ($s) { $s.Replace($HOME, '~') } else { $s } }

if ($SelfTest) { Invoke-SelfTest $P $Here; if ($script:stf -eq 0) { exit 0 } else { exit 1 } }

# 1 system
$build = [Environment]::OSVersion.Version.Build
$arch = $env:PROCESSOR_ARCHITECTURE
if ($build -ge [int]$P.WINDOWS_MIN_BUILD) { Rec PASS AJ-SYS-00 windows "build $build $arch" ">=$($P.WINDOWS_MIN_BUILD) (Windows 11)" microsoft }
else { Rec FAIL AJ-SYS-01 windows "build $build $arch" ">=$($P.WINDOWS_MIN_BUILD) (Windows 11)" microsoft }
if ($arch -ne 'AMD64') { Rec WARN AJ-SYS-02 windows-arch $arch "AMD64 (x64)" "REPAIR.md AJ-SYS-02" }
# 0 backup: File History / OneDrive / other tools are not readable reliably, so the person confirms it by hand
Rec WARN AJ-BAK-01 backup "not-detectable-on-windows" "backup <= 7 days" "File History or another backup (REPAIR.md AJ-BAK-01)"
# 0a recommended hardware (WARN only): 16 GB RAM, 512 GB disk
$memGB = [math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$sysDrive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $env:SystemDrive + "'")
$diskGB = [math]::Floor($sysDrive.Size / 1e9)
$low = @(); if ($memGB -lt 16) { $low += 'ram' }; if ($diskGB -lt 460) { $low += 'disk' }
if ($low.Count -eq 0) { Rec PASS AJ-HW-00 hardware "$memGB GB RAM, $diskGB GB disk" "16GB 512GB" "README: Recommended hardware" }
else { Rec WARN AJ-HW-01 hardware "$memGB GB RAM, $diskGB GB disk (below: $($low -join ' '))" "16GB 512GB" "REPAIR.md AJ-HW-01" }
# 0b free disk space (home drive)
$freeGB = Get-FreeGB
if ($freeGB -lt [int]$P.DISK_FAIL_GB) { Rec FAIL AJ-DISK-02 disk "$freeGB GB free" ">=$($P.DISK_WARN_GB) GB (min $($P.DISK_FAIL_GB))" "REPAIR.md AJ-DISK-02" }
elseif ($freeGB -lt [int]$P.DISK_WARN_GB) { Rec WARN AJ-DISK-01 disk "$freeGB GB free" ">=$($P.DISK_WARN_GB) GB" "REPAIR.md AJ-DISK-01" }
else { Rec PASS AJ-DISK-00 disk "$freeGB GB free" ">=$($P.DISK_WARN_GB) GB" "Win32_LogicalDisk" }

# 2 prerequisites
$wg = Find-Tool 'winget'
if ($wg) { Rec PASS AJ-WINGET-00 winget (Get-Ver $wg '--version') any "Microsoft Store: App Installer" } else { Rec FAIL AJ-WINGET-01 winget missing any "Microsoft Store: App Installer" }
$nv = Get-Ver (Find-Tool 'node') '-v'
if (-not $nv) { Rec FAIL AJ-NODE-01 node missing ">=$($P.NODE_MIN_MAJOR)" "winget OpenJS.NodeJS.LTS" }
elseif ([int]($nv.Split('.')[0]) -ge [int]$P.NODE_MIN_MAJOR) { Rec PASS AJ-NODE-00 node $nv ">=$($P.NODE_MIN_MAJOR)" "winget OpenJS.NodeJS.LTS" }
else { Rec FAIL AJ-NODE-02 node $nv ">=$($P.NODE_MIN_MAJOR)" "winget OpenJS.NodeJS.LTS" }
$gitv = Get-Ver (Find-Tool 'git') '--version'
if ($gitv) { Rec PASS AJ-GIT-00 git $gitv any "winget Git.Git" } else { Rec FAIL AJ-GIT-01 git missing any "winget Git.Git" }

# 3 local drivers: both CLIs required; signed in to both recommended (one signed in = WARN for the other, none = FAIL)
$claude = Find-Tool 'claude'; $codex = Find-Tool 'codex'
$cv = Get-Ver $claude '--version'; $xv = Get-Ver $codex '--version'
$cs = $false; if ($cv -and (Ge $cv $P.CLAUDE_CLI_MIN)) { $cs = ((Invoke-Bounded $claude @('auth', 'status') 30).Code -eq 0) }
$xs = $false; if ($xv -and (Ge $xv $P.CODEX_CLI_MIN)) { $xs = ((Invoke-Bounded $codex @('login', 'status') 30).Code -eq 0) }
$cf = 'FAIL'; $cnote = ''; if ($xs) { $cf = 'WARN'; $cnote = ' (recommended: sign in too)' }
$xf = 'FAIL'; $xnote = ''; if ($cs) { $xf = 'WARN'; $xnote = ' (recommended: sign in too)' }
$csrc = "winget $($P.CLAUDE_WINGET_ID)"
if (-not $cv) { Rec FAIL AJ-CLAUDE-01 claude-cli missing ">=$($P.CLAUDE_CLI_MIN)" $csrc }
elseif (-not (Ge $cv $P.CLAUDE_CLI_MIN)) { Rec FAIL AJ-CLAUDE-02 claude-cli $cv ">=$($P.CLAUDE_CLI_MIN)" $csrc }
elseif ($cs) { Rec PASS AJ-CLAUDE-00 claude-cli "$cv signed-in" ">=$($P.CLAUDE_CLI_MIN)" $csrc }
else { Rec $cf AJ-CLAUDE-03 claude-cli "$cv signed-out$cnote" ">=$($P.CLAUDE_CLI_MIN)" $csrc }
if (-not $xv) { Rec FAIL AJ-CODEX-01 codex-cli missing ">=$($P.CODEX_CLI_MIN)" "npm:@openai/codex" }
elseif (-not (Ge $xv $P.CODEX_CLI_MIN)) { Rec FAIL AJ-CODEX-02 codex-cli $xv ">=$($P.CODEX_CLI_MIN)" "npm:@openai/codex" }
elseif ($xs) { Rec PASS AJ-CODEX-00 codex-cli "$xv signed-in" ">=$($P.CODEX_CLI_MIN)" "npm:@openai/codex" }
else { Rec $xf AJ-CODEX-03 codex-cli "$xv signed-out$xnote" ">=$($P.CODEX_CLI_MIN)" "npm:@openai/codex" }
# 3b stray API overrides (names only; values are never read into output)
$stray = @()
foreach ($v in 'ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY') {
  # inside Claude Code the parent process may set these itself, so only a plain terminal's env counts
  if (-not $env:CLAUDECODE -and [Environment]::GetEnvironmentVariable($v, 'Process')) { $stray += "$v(env)" }
  foreach ($scope in 'User', 'Machine') { if ([Environment]::GetEnvironmentVariable($v, $scope)) { $stray += "$v($scope)" } }
  foreach ($f in @($PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost)) {
    if ($f -and (Test-Path -LiteralPath $f) -and (Select-String -LiteralPath $f -Pattern ('^\s*\$env:' + $v + '\s*=') -Quiet)) { $stray += "$v(" + (Split-Path -Leaf $f) + ")" }
  }
}
if ($stray.Count -gt 0) { Rec $cf AJ-ENV-01 claude-env ($stray -join ' ') "no ANTHROPIC_* override" "REPAIR.md AJ-ENV-01" }
else { Rec PASS AJ-ENV-00 claude-env clean "no ANTHROPIC_* override" shell }
# 3b' doctor started inside the Codex app sandbox (no network): the reply checks can't work there
$sandboxed = [bool]($env:CODEX_SANDBOX -and $env:CODEX_SANDBOX_NETWORK_DISABLED)
if ($sandboxed) { Rec FAIL AJ-DOC-01 doctor "inside Codex sandbox (no network)" "run with approval, outside the sandbox" "REPAIR.md AJ-DOC-01" }
# 3c / 3d one tiny headless reply each (60 s / 90 s), from an empty temp folder
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("aj-doctor-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
if ($cs -and $stray.Count -eq 0 -and -not $sandboxed) {
  $r = Invoke-Bounded $claude @('-p', 'Reply with exactly: OK') 60 $tmp
  if ((Last-Line $r.Out) -eq 'OK') { Rec PASS AJ-CLAUDE-05 claude-reply OK OK claude } else { Rec $cf AJ-CLAUDE-04 claude-reply "no-OK-in-60s" OK "REPAIR.md AJ-CLAUDE-04" }
}
if ($xs -and -not $sandboxed) {
  $r = Invoke-Bounded $codex @('exec', '--skip-git-repo-check', '--sandbox', 'read-only', 'Reply with exactly: OK') 90 $tmp
  if ((Last-Line $r.Out) -eq 'OK') { Rec PASS AJ-CODEX-05 codex-reply OK OK codex } else { Rec $xf AJ-CODEX-04 codex-reply "no-OK-in-90s" OK "REPAIR.md AJ-CODEX-04" }
}
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

# 4 T3 Code (our pinned fork)
$t3src = "$($P.T3_REPO)@$($P.T3_TAG)"
$t3wait = ($P.T3_ASSET_WIN_X64 -eq 'TBD')
if ($t3wait) { Rec WAIT AJ-PIN-00 t3code "waiting" "Windows build of T3 Code TPLUS" "VERSIONS.md" }
else {
  $t3 = Get-InstalledApp ($P.T3_APP_NAME + '*')
  if (-not $t3) { Rec FAIL AJ-T3-01 t3code missing $P.T3_VERSION $t3src }
  elseif ($t3.DisplayVersion -ne $P.T3_VERSION) { Rec FAIL AJ-T3-02 t3code $t3.DisplayVersion $P.T3_VERSION $t3src }
  else { Rec PASS AJ-T3-00 t3code $t3.DisplayVersion $P.T3_VERSION $t3src }
}
# Names only, never values, of what `tentacles doctor --json` reports as not ready (lab:code, t3:code),
# or a fixed label for a CLI error, so a non-T3 cause stays visible while T3 waits. The error text itself is never printed.
function Tentacles-NotReady($R) {
  if ($R.Code -eq -1) { return 'timeout' }
  $names = @()
  $d = $null; try { $d = "$($R.Out)" | ConvertFrom-Json } catch { $d = $null }
  if ($d) {
    if ($d.t3 -and $d.t3.auth -and $d.t3.auth.code) { $names += 't3:' + $d.t3.auth.code }
    foreach ($l in @($d.labs)) { if ($l -and -not $l.ready) { $names += "$($l.instanceId):$($l.code)" } }
  }
  elseif ("$($R.Err)" -match 'token') { $names += 't3-token' }
  elseif ("$($R.Err)" -match 'ECONNREFUSED|fetch failed|connect') { $names += 't3-unreachable' }
  elseif ("$($R.Err)" -match 'T3') { $names += 't3-other' }
  else { $names += 'other-error' }
  if ($names.Count -eq 0) { return 'unknown' }
  return (($names | Select-Object -Unique) -join ',')
}
# 5 Tentacles: a pinned checkout run through bin\tentacles.cmd (npm link's shim needs /bin/sh, so it is not used on Windows)
$tsrc = "$($P.TENTACLES_REPO)@$($P.TENTACLES_TAG)"
$tcmd = Join-Path $HOME 'Developer\t3-code-tentacles\bin\tentacles.cmd'
if (-not (Test-Path -LiteralPath $tcmd)) { Rec FAIL AJ-TENT-01 tentacles missing $P.TENTACLES_VERSION $tsrc }
else {
  $tv = Get-Ver $tcmd '--version'
  if ($tv -ne $P.TENTACLES_VERSION) { Rec FAIL AJ-TENT-02 tentacles $tv $P.TENTACLES_VERSION $tsrc }
  else {
    $td = Invoke-Bounded $tcmd @('doctor', '--json') 60
    if ($td.Code -eq 0) { Rec PASS AJ-TENT-00 tentacles "$tv doctor-ok" $P.TENTACLES_VERSION $tsrc }
    elseif ($t3wait) { Rec WAIT AJ-TENT-03 tentacles "$tv waiting-for-t3; not-ready: $(Tentacles-NotReady $td)" $P.TENTACLES_VERSION $tsrc }
    else { Rec FAIL AJ-TENT-03 tentacles "$tv doctor-not-ready: $(Tentacles-NotReady $td)" $P.TENTACLES_VERSION $tsrc }
  }
}
# 5b the pairer where Agent Jack desktop looks for it on Windows (npm link of the pinned checkout)
$lsrc = "npm link in ~\Developer\t3-code-tentacles (REPAIR.md AJ-TENTLINK-01)"
$lpkg = Join-Path (Get-TentaclesLinkDir) 'package.json'
$lv = $null
if ((Test-Path -LiteralPath $lpkg) -and (Test-Path -LiteralPath (Join-Path (Get-TentaclesLinkDir) 'src\cli.mjs'))) {
  try { $lv = (Get-Content -LiteralPath $lpkg -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch { $lv = $null }
}
if ($lv -eq $P.TENTACLES_VERSION) { Rec PASS AJ-TENTLINK-00 tentacles-link $lv $P.TENTACLES_VERSION "%APPDATA%\npm\node_modules\tentacles" }
elseif ($lv) { Rec FAIL AJ-TENTLINK-01 tentacles-link $lv $P.TENTACLES_VERSION $lsrc }
else { Rec FAIL AJ-TENTLINK-01 tentacles-link not-linked $P.TENTACLES_VERSION $lsrc }
# 6 estate-guardian: the classifier + router for Tentacles (standard), the guard checkout (optional)
$gsrc = "$($P.GUARDIAN_REPO)@$($P.GUARDIAN_TAG)"
$vpy = Join-Path $P.CLASSIFY_VENV 'Scripts\python.exe'
$ev = $null; if (Test-Path -LiteralPath $vpy) { $ev = Last-Line (& $vpy -c "import importlib.metadata as m; print(m.version('estate-classify'))" 2>$null) }
if (-not $ev) { Rec FAIL AJ-EC-01 estate-classify not-installed $P.CLASSIFY_VERSION $gsrc }
elseif ($ev -ne $P.CLASSIFY_VERSION) { Rec FAIL AJ-EC-02 estate-classify $ev $P.CLASSIFY_VERSION $gsrc }
else {
  $commit = Last-Line (& $vpy -c "import json,importlib.metadata as m; print((json.loads(m.distribution('estate-classify').read_text('direct_url.json') or '{}').get('vcs_info') or {}).get('commit_id','')[:7])" 2>$null)
  $want = $P.GUARDIAN_COMMIT.Substring(0, 7)
  if ($commit -ne $want) { Rec FAIL AJ-EC-02 estate-classify "$ev other-commit" $P.GUARDIAN_TAG $gsrc }
  else {
    # offline smoke: import both modules, classify against an empty in-memory taxonomy (no key, no network, no writes)
    $smoke = @'
import json, tempfile, os, classify, worker_route
d = tempfile.mkdtemp()
p = os.path.join(d, "smoke.json")
json.dump({"name": "smoke", "taxonomy": {"classes": {}}, "question": "smoke?", "min_conf": 0.6,
           "paths": {"judge_queue": os.path.join(d, "q.jsonl"), "answers": os.path.join(d, "a.jsonl")},
           "key": {"source": "env", "env": "AJ_SMOKE_NO_KEY"}, "questions": {}}, open(p, "w"))
r = classify.Classifier(p).classify("smoke test", key="smoke")
assert r["class"] == "unclassified"
'@
    $smoke | & $vpy - 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Rec PASS AJ-EC-00 estate-classify "$ev smoke-ok" $P.CLASSIFY_VERSION $gsrc } else { Rec FAIL AJ-EC-03 estate-classify "$ev smoke-fail" $P.CLASSIFY_VERSION $gsrc }
  }
}
$eg = Join-Path $HOME 'Developer\estate-guardian'
if (-not (Test-Path -LiteralPath (Join-Path $eg '.git'))) { Rec SKIP AJ-EG-00 guard-checkout not-installed $P.GUARDIAN_TAG "$($P.GUARDIAN_REPO) (optional)" }
else {
  $gv = Last-Line (& git -C $eg describe --tags --exact-match 2>$null); if (-not $gv) { $gv = 'untagged' }
  if ($gv -ne $P.GUARDIAN_TAG) { Rec FAIL AJ-EG-02 guard-checkout $gv $P.GUARDIAN_TAG "$($P.GUARDIAN_REPO) (optional)" }
  else { Rec PASS AJ-EG-00 guard-checkout $gv $P.GUARDIAN_TAG "$($P.GUARDIAN_REPO) (optional)" }
}
# 7 Agent Jack desktop (per-user installer; its uninstall entry carries the version)
$ajsrc = "agentjack.kraliki.com/downloads (signed in)"
$aj = Get-InstalledApp 'Agent Jack*'
if (-not $aj) { Rec FAIL AJ-JACK-01 agent-jack-app missing ">=$($P.JACK_DESKTOP_MIN)" $ajsrc }
elseif (Ge $aj.DisplayVersion $P.JACK_DESKTOP_MIN) { Rec PASS AJ-JACK-00 agent-jack-app $aj.DisplayVersion ">=$($P.JACK_DESKTOP_MIN)" $ajsrc }
else { Rec FAIL AJ-JACK-02 agent-jack-app $aj.DisplayVersion ">=$($P.JACK_DESKTOP_MIN)" $ajsrc }
# 7b Google Chrome (required; it updates itself, so no pin)
$gc = Get-InstalledApp 'Google Chrome'
if ($gc) { Rec PASS AJ-CHROME-00 google-chrome $gc.DisplayVersion any google.com/chrome } else { Rec FAIL AJ-CHROME-01 google-chrome missing any "google.com/chrome (REPAIR.md AJ-CHROME-01)" }
# 8 manual checks (inside the Agent Jack app; doctor cannot see them)
Rec SKIP AJ-PAIR-00 pairing manual "Paired - ready" "Settings > Computers & labs"
if ($t3wait) { Rec WAIT AJ-LOCAL-00 local-bot "waiting; Bot runs on Server" "Local reply OK" "needs the Windows build of T3 Code TPLUS" }
else { Rec SKIP AJ-LOCAL-00 local-bot manual "Local reply OK" "Bot > Provider > Local > Codex or Claude Code" }
Rec SKIP AJ-BROWSER-00 browser "manual (optional)" "extension Connected" "BROWSER.md: Codex > ChatGPT extension (OpenAI); Claude > Claude in Chrome (Anthropic)"

if ($Json) {
  $rows = @($script:Out | ForEach-Object { $_.found = Home-Tilde $_.found; $_ })
  [pscustomobject]@{ doctor = 'agent-jack-setup'; os = 'windows'; setup_tag = $P.SETUP_TAG; fails = $script:Fails; checks = $rows } | ConvertTo-Json -Depth 4 -Compress
} else {
  "AGENT JACK DOCTOR v1 (windows) - setup $($P.SETUP_TAG) - $(Get-Date -Format yyyy-MM-dd)"
  foreach ($o in $script:Out) { '{0,-4} {1,-12} {2,-16} found={3,-22} expected={4,-16} source={5}' -f $o.status, $o.code, $o.component, (Home-Tilde $o.found), $o.expected, $o.source }
  "fails: $($script:Fails)  (fix each FAIL code with REPAIR.md, then run bin/doctor.ps1 again)"
}
if ($script:Fails -eq 0) { exit 0 } else { exit 1 }
