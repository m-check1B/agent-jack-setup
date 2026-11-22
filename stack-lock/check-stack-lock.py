#!/usr/bin/env python3
"""Stack lock check (KRA-10845). One file, copied byte for byte into every repo of the stack.

  python3 <path>/check-stack-lock.py agent-jack-3|tentacles|setup|onboarding
  python3 <path>/check-stack-lock.py --self-test

Run from the repository root. agent-jack-3 reads ./stack.lock.json (canonical); the
other repos read stack.lock.json next to this script (a copy) and the FROM file beside it.
Each failure is one line naming the file to change. Exit 0 = in step, 1 = drift.
The procedure is in agent-jack-3 docs/LOCAL-STACK.md.
"""
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PENDING = "pending KRA-10845 proof"
HISTORY_MARK = "KRA-10845 history"
# A fork or patched-T3 requirement may appear only in history-marked files (agent-jack-3 mode).
FORK_WORDS = re.compile(r"t3code-tplus|T3 Code TPLUS|never upstream|patched T3", re.I)
FORK_SKIP = ("docs/LOCAL-STACK.md", "scripts/check-stack-lock.py", "stack.lock.json")
# KRA-10868: the code that enforces the Tentacles minimum holds a copy of it; each copy equals the lock.
MIN_DEF = re.compile(r"\bMIN_TENTACLES_VERSION\s*=\s*[\"']([^\"']+)[\"']")
MIN_DIRS = ("desktop/src/", "api/src/")


def git(root, *args):
    r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def version(v):
    m = re.match(r"v?(\d+)\.(\d+)\.(\d+)", v or "")
    return tuple(map(int, m.groups())) if m else None


def t3_errors(lock, where, version_found):
    """T3 range check shared by the modes that pin a T3 version."""
    t3 = lock["t3"]
    if t3["minimum"] == PENDING and t3["testedThrough"] == PENDING:
        return []
    lo, hi, got = version(t3["minimum"]), version(t3["testedThrough"]), version(version_found)
    if not (lo and hi):
        return [f"stack.lock.json: t3.minimum/testedThrough must be versions or exactly '{PENDING}'"]
    if not got or not lo <= got <= hi:
        return [f"{where}: T3 {version_found or 'missing'} is outside the lock range {t3['minimum']}..{t3['testedThrough']}"]
    return []


def check_agent_jack_3(root, lock):
    errs = []
    tl = lock["tentacles"]
    files = (git(root, "ls-files") or "").splitlines()
    copies = 0
    for name in files:
        if not (name.startswith(MIN_DIRS) and name.endswith((".mjs", ".py"))):
            continue
        for found in MIN_DEF.findall((root / name).read_text()):
            copies += 1
            if found != tl["minimum"]:
                errs.append(f"{name}: MIN_TENTACLES_VERSION {found!r} != lock tentacles.minimum {tl['minimum']!r}")
    if not copies:
        errs.append("desktop/src, api/src: no MIN_TENTACLES_VERSION; the code must enforce lock tentacles.minimum")
    # The lock holds the compatibility set only: a desktop release cut never moves it.
    desktop, floor = json.loads((root / "desktop/package.json").read_text())["version"], lock["agentJackSetup"]["desktopMin"]
    if not (version(desktop) and version(floor) and version(desktop) >= version(floor)):
        errs.append(f"desktop/package.json: version {desktop!r} is below the lock's agentJackSetup.desktopMin {floor!r}")
    # The sandbox image installs the tested tag from the public repo at build time.
    docker = (root / "deploy/fly-sandbox/Dockerfile").read_text()
    for line in (f"ARG TENTACLES_TAG={tl['tag']}", f"ARG TENTACLES_COMMIT={tl['commit']}", f"{tl['repo']}.git"):
        if line not in docker:
            errs.append(f"deploy/fly-sandbox/Dockerfile: must name {line} (lock tentacles)")
    for name in files:
        if name.startswith(FORK_SKIP) or not name.endswith((".md", ".txt", "Dockerfile", ".json", ".yaml", ".yml")):
            continue
        try:
            text = (root / name).read_text()
        except (OSError, UnicodeDecodeError):
            continue
        if FORK_WORDS.search(text) and HISTORY_MARK not in "\n".join(text.splitlines()[:3]):
            errs.append(f"{name}: names a T3 fork or patched build; fix it or add a '{HISTORY_MARK}' line at the top (docs/LOCAL-STACK.md)")
    return errs


def check_tentacles(root, lock):
    errs = []
    tl = lock["tentacles"]
    tagged = git(root, "rev-parse", f"{tl['tag']}^{{commit}}")
    if tagged != tl["commit"]:
        errs.append(f"stack-lock/stack.lock.json: tag {tl['tag']} is {tagged or 'missing'}, lock says {tl['commit']}")
    else:
        pkg = json.loads(git(root, "show", f"{tl['commit']}:package.json") or "{}")
        if pkg.get("version") != tl["version"]:
            errs.append(f"stack-lock/stack.lock.json: package.json at {tl['tag']} is {pkg.get('version')!r}, lock says {tl['version']!r}")
        if git(root, "merge-base", "--is-ancestor", tl["commit"], "HEAD") is None:
            errs.append(f"stack-lock/stack.lock.json: locked commit {tl['commit'][:12]} is not in this branch")
    # The minimum is a released tag too, older than or equal to the tested one.
    floor = git(root, "rev-parse", f"v{tl['minimum']}^{{commit}}")
    if floor is None or git(root, "merge-base", "--is-ancestor", floor, tl["commit"]) is None:
        errs.append(f"stack-lock/stack.lock.json: minimum v{tl['minimum']} is not a tag at or before {tl['tag']}")
    support = root / "src/t3-support.mjs"
    t3 = lock["t3"]
    if support.exists():
        # The range is the T3_SUPPORT export; node evaluates it, so the check reads what doctor reads.
        js = f"import({json.dumps(support.resolve().as_uri())}).then(m => console.log(JSON.stringify(m.T3_SUPPORT)))"
        r = subprocess.run(["node", "--input-type=module", "-e", js], capture_output=True, text=True)
        if r.returncode:
            return errs + [f"src/t3-support.mjs: node could not read T3_SUPPORT (exit {r.returncode})"]
        s = json.loads(r.stdout)
        for key, skey in (("minimum", "minimum"), ("testedThrough", "testedThrough"), ("tag", "testedTag"), ("publisherRepo", "source")):
            if s.get(skey) != t3.get(key):
                errs.append(f"stack-lock/stack.lock.json: t3.{key} {t3.get(key)!r} != src/t3-support.mjs T3_SUPPORT.{skey} {s.get(skey)!r} (bump the lock in agent-jack-3 first)")
    elif t3["minimum"] != PENDING:
        errs.append("src/t3-support.mjs: missing, but the lock names a T3 range")
    return errs


def check_setup(root, lock):
    env = {}
    for line in (root / "versions.env").read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"')
    tl, st = lock["tentacles"], lock["agentJackSetup"]
    want = {"SETUP_TAG": st["tag"], "JACK_DESKTOP_MIN": st["desktopMin"], "TENTACLES_TAG": tl["tag"],
            "TENTACLES_VERSION": tl["version"], "TENTACLES_COMMIT": tl["commit"]}
    errs = [f"versions.env: {k}={env.get(k)!r}, lock says {v!r}" for k, v in want.items() if env.get(k) != v]
    t3 = lock["t3"]
    if t3["minimum"] != PENDING:
        for k, v in (("T3_REPO", t3["publisherRepo"]), ("T3_TAG", t3["tag"]), ("T3_MIN", t3["minimum"])):
            if env.get(k) != v:
                errs.append(f"versions.env: {k}={env.get(k)!r}, lock says the official {v!r}")
    return errs + t3_errors(lock, "versions.env", env.get("T3_VERSION"))


def check_onboarding(root, lock):
    ob, errs = lock["onboarding"], []
    guide = (root / ob["guide"]).read_text()
    m = re.search(r"Written for \*\*Agent Jack (\d+\.\d+\.\d+)\*\*", guide)
    if not m or m.group(1) != ob["desktopVersion"]:
        errs.append(f"{ob['guide']}: 'Written for **Agent Jack {m.group(1) if m else '?'}**', lock says {ob['desktopVersion']}")
    for tag in sorted(set(re.findall(r"(?:agent-jack-setup|setup|git checkout) (v\d+\.\d+\.\d+)", guide))):
        if tag != lock["agentJackSetup"]["tag"]:
            errs.append(f"{ob['guide']}: names setup {tag}, lock says {lock['agentJackSetup']['tag']}")
    if git(root, "merge-base", "--is-ancestor", ob["revision"], "HEAD") is None:
        errs.append(f"agent-jack/stack-lock/stack.lock.json: onboarding.revision {ob['revision'][:12]} is not in this branch")
    return errs


CHECKS = {"agent-jack-3": check_agent_jack_3, "tentacles": check_tentacles, "setup": check_setup, "onboarding": check_onboarding}


def run(mode, root, lock_dir):
    lock_path = root / "stack.lock.json" if mode == "agent-jack-3" else lock_dir / "stack.lock.json"
    lock = json.loads(lock_path.read_text())
    run.revision = lock.get("revision")
    errs = [] if lock.get("schema") == 1 else [f"{lock_path.name}: unknown schema {lock.get('schema')!r}"]
    if mode != "agent-jack-3":
        src = (lock_dir / "FROM").read_text().strip() if (lock_dir / "FROM").exists() else ""
        if not re.fullmatch(r"[0-9a-f]{40}", src):
            errs.append(f"{lock_dir.name}/FROM: must hold the 40-hex agent-jack-3 commit this copy came from")
    return errs + CHECKS[mode](root, lock)


def self_test():
    base = Path(tempfile.mkdtemp(prefix="stack-lock-self-test-"))
    try:
        _self_test(base)
    finally:
        shutil.rmtree(base, ignore_errors=True)  # the self-test leaves no temporary repos behind
    assert not base.exists(), base


def _self_test(base):
    lock = {"schema": 1, "revision": 1,
            "tentacles": {"repo": "https://example.invalid/tentacles", "minimum": "0.5.0-x", "tag": "v0.5.0-x",
                          "version": "0.5.0-x", "commit": "", "t3Contract": "c/v1"},
            "t3": {"publisherRepo": "https://example.invalid/t3", "tag": PENDING, "minimum": PENDING, "testedThrough": PENDING},
            "agentJackSetup": {"tag": "v1.0.0", "desktopMin": "1.2.0"},
            "onboarding": {"guide": "g.md", "revision": "", "desktopVersion": "1.2.3"},
            "flySandbox": {}}

    def repo(files):
        d = Path(tempfile.mkdtemp(dir=base))
        for name, text in files.items():
            (d / name).parent.mkdir(parents=True, exist_ok=True)
            (d / name).write_text(text)
        for cmd in (["init", "-q"], ["add", "-A"], ["-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false",
                                                    "-c", "core.hooksPath=/dev/null", "commit", "-qm", "t"]):
            git(d, *cmd)
        return d, git(d, "rev-parse", "HEAD")

    # Tentacles repo: tag the release commit, then lock its commit.
    t, head = repo({"package.json": '{"version": "0.5.0-x"}'})
    git(t, "tag", "v0.5.0-x")
    lock["tentacles"]["commit"] = head
    o, lock["onboarding"]["revision"] = repo({"g.md": "Written for **Agent Jack 1.2.3**. Run `git checkout v1.0.0`."})
    docker = f"ARG TENTACLES_TAG=v0.5.0-x\nARG TENTACLES_COMMIT={head}\nRUN git clone https://example.invalid/tentacles.git\n"
    j, _ = repo({"desktop/src/t.mjs": 'export const MIN_TENTACLES_VERSION = "0.5.0-x";\n', "desktop/package.json": '{"version": "1.2.3"}',
                 "api/src/t.py": 'MIN_TENTACLES_VERSION = "0.5.0-x"\n', "deploy/fly-sandbox/Dockerfile": docker, "ok.md": "stock T3 only\n"})
    s, _ = repo({"versions.env": "SETUP_TAG=v1.0.0\nJACK_DESKTOP_MIN=1.2.0  # c\nTENTACLES_TAG=v0.5.0-x\n"
                 f"TENTACLES_VERSION=0.5.0-x\nTENTACLES_COMMIT={head}\nT3_REPO=https://fork.invalid\nT3_VERSION=0.0.1\n"})
    roots = {"agent-jack-3": j, "tentacles": t, "setup": s, "onboarding": o}
    for mode, root in roots.items():
        (root / "stack.lock.json").write_text(json.dumps(lock))
        (root / "FROM").write_text("a" * 40)
        assert run(mode, root, root) == [], (mode, run(mode, root, root))
    # Drift: each mode names the file to change.
    (j / "bad.md").write_text("needs the patched T3 build\n")
    git(j, "add", "-A")
    assert any(e.startswith("bad.md:") for e in run("agent-jack-3", j, j))
    (j / "bad.md").write_text(f"{HISTORY_MARK}: was a patched T3\n")
    assert run("agent-jack-3", j, j) == []
    # A newer desktop (the next release cut) passes; one below the setup minimum fails.
    (j / "desktop/package.json").write_text('{"version": "1.10.0"}')
    assert run("agent-jack-3", j, j) == []
    (j / "desktop/package.json").write_text('{"version": "1.1.9"}')
    assert run("agent-jack-3", j, j)[0].startswith("desktop/package.json: version '1.1.9' is below")
    (j / "desktop/package.json").write_text('{"version": "1.2.3"}')
    # A minimum copy that drifted, or a sandbox image on another tag, names its file.
    (j / "api/src/t.py").write_text('MIN_TENTACLES_VERSION = "0.4.0"\n')
    assert run("agent-jack-3", j, j)[0].startswith("api/src/t.py: MIN_TENTACLES_VERSION '0.4.0'")
    (j / "api/src/t.py").write_text('MIN_TENTACLES_VERSION = "0.5.0-x"\n')
    (j / "deploy/fly-sandbox/Dockerfile").write_text(docker.replace("v0.5.0-x", "v0.5.0-w"))
    assert run("agent-jack-3", j, j)[0].startswith("deploy/fly-sandbox/Dockerfile: must name ARG TENTACLES_TAG")
    (j / "deploy/fly-sandbox/Dockerfile").write_text(docker)
    (s / "versions.env").write_text((s / "versions.env").read_text().replace("v1.0.0", "v1.0.1"))
    assert run("setup", s, s)[0].startswith("versions.env: SETUP_TAG")
    (o / "g.md").write_text("Written for **Agent Jack 1.2.3**. Run `git checkout v9.9.9`.")
    assert run("onboarding", o, o)[0].startswith("g.md: names setup v9.9.9")
    # A proven T3 range: the pending marker no longer excuses the setup T3 lines.
    lock["t3"].update(tag="v0.1.11", minimum="0.1.0", testedThrough="0.1.11")
    (t / "stack.lock.json").write_text(json.dumps(lock))
    assert run("tentacles", t, t)[0].startswith("src/t3-support.mjs: missing")
    if shutil.which("node"):  # the Tentacles CI has node; other repos' runners may not
        (t / "src").mkdir()
        support = {"source": "https://example.invalid/t3", "minimum": "0.1.0", "testedThrough": "0.1.11", "testedTag": "v0.1.11"}
        (t / "src/t3-support.mjs").write_text(f"export const T3_SUPPORT = Object.freeze({json.dumps(support)});\n")
        assert run("tentacles", t, t) == []
        support.update(testedThrough="0.1.12", testedTag="v0.1.12")
        (t / "src/t3-support.mjs").write_text(f"export const T3_SUPPORT = Object.freeze({json.dumps(support)});\n")
        assert len(run("tentacles", t, t)) == 2
    lock["tentacles"]["minimum"] = "0.4.9"
    (t / "stack.lock.json").write_text(json.dumps(lock))
    assert any(e.endswith("minimum v0.4.9 is not a tag at or before v0.5.0-x") for e in run("tentacles", t, t))
    lock["tentacles"]["minimum"] = "0.5.0-x"
    (s / "stack.lock.json").write_text(json.dumps(lock))
    assert any("T3_REPO" in e for e in run("setup", s, s)) and any("outside the lock range" in e for e in run("setup", s, s))
    # A Tentacles bump the setup has not taken yet.
    lock["tentacles"]["tag"] = "v0.5.0-y"
    (s / "stack.lock.json").write_text(json.dumps(lock))
    assert any(e.startswith("versions.env: TENTACLES_TAG") for e in run("setup", s, s))
    print("stack-lock self-test: OK")


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    if len(argv) != 1 or argv[0] not in CHECKS:
        sys.exit(__doc__)
    root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel") or Path.cwd())
    errs = run(argv[0], root, Path(__file__).resolve().parent)
    for e in errs:
        print(f"stack-lock: {e}")
    if errs:
        sys.exit(1)
    print(f"stack-lock: OK {argv[0]} is in step with lock revision {run.revision}")


if __name__ == "__main__":
    main(sys.argv[1:])
