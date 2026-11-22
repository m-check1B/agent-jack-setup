#!/usr/bin/env python3
"""bin/uninstall.sh moves T3 Code (Beta) aside instead of deleting it (audit 3, KRA-10893), removes only what the
doctor installed, and changes nothing without --yes. Runs with a throwaway HOME; AJ_TEST_BASH picks the shell
(use a bash 3.2.57 build, the macOS /bin/bash)."""
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("AJ_TEST_BASH", "/bin/bash")


class Uninstall(unittest.TestCase):
    def setUp(self):
        self.home = Path(tempfile.mkdtemp(prefix="aj-uninstall-"))
        self.addCleanup(shutil.rmtree, self.home, True)
        self.app = self.home / "Applications/T3 Code (Beta).app/Contents"
        self.app.mkdir(parents=True)
        (self.app / "Info.plist").write_text("theirs")
        for d in (".agent-jack/node/bin", ".agent-jack/tentacles/0.5.0-jack.19", ".agent-jack/venv"):
            (self.home / d).mkdir(parents=True)
        (self.home / ".zprofile").write_text('export A=1\nexport PATH="$HOME/.agent-jack/node/bin:$PATH"   # Agent Jack doctor\n')

    def run_it(self, *args):
        env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin"}
        return subprocess.run([BASH, str(ROOT / "bin/uninstall.sh"), *args], env=env, capture_output=True, text=True)

    def record(self):
        (self.home / ".agent-jack/installed-apps").write_text("T3 Code (Beta)|0.1.11|2026-11-21T12:00:00Z|~/Applications\n")

    def test_lists_without_changing(self):
        self.record()
        r = self.run_it()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Would move to the Trash (the doctor installed it): ~/Applications/T3 Code (Beta).app", r.stdout)
        self.assertNotIn(str(self.home), r.stdout)
        self.assertTrue(self.app.exists() and (self.home / ".agent-jack/node").exists())

    def test_yes_moves_the_recorded_app_to_the_trash_and_removes_ours(self):
        self.record()
        r = self.run_it("--yes")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertFalse((self.home / "Applications/T3 Code (Beta).app").exists())
        kept = list((self.home / ".Trash").iterdir())
        self.assertEqual(len(kept), 1)
        self.assertEqual((kept[0] / "Contents/Info.plist").read_text(), "theirs")
        for d in ("node", "tentacles", "venv"):
            self.assertFalse((self.home / ".agent-jack" / d).exists(), d)
        self.assertEqual((self.home / ".zprofile").read_text(), "export A=1\n")
        self.assertFalse((self.home / ".agent-jack/installed-apps").exists())

    def test_app_without_a_record_is_left_whole_with_the_manual_command(self):
        r = self.run_it("--yes")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((self.app / "Info.plist").read_text(), "theirs")
        self.assertFalse((self.home / ".Trash").exists())
        self.assertIn('Left whole (not installed by the doctor): ~/Applications/T3 Code (Beta).app. To remove it yourself: mv ~/"Applications/T3 Code (Beta).app" ~/.Trash/', r.stdout)

    def test_path_line_is_removed_when_it_is_the_only_line(self):
        (self.home / ".zprofile").write_text('export PATH="$HOME/.agent-jack/node/bin:$PATH"   # Agent Jack doctor\n')
        r = self.run_it("--yes")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((self.home / ".zprofile").read_text(), "")

    def test_space_in_home_removes_only_fixed_paths(self):
        top = Path(tempfile.mkdtemp(prefix="aj-space-"))
        self.addCleanup(shutil.rmtree, top, True)
        home = top / "a b"
        for d in (".agent-jack/node/bin", ".agent-jack/venv"):
            (home / d).mkdir(parents=True)
        (top / "a").mkdir(); (top / "a/canary").write_text("keep")            # the sibling the old word split removed
        (top / "b/.agent-jack/venv").mkdir(parents=True); (top / "b/.agent-jack/venv/canary").write_text("keep")
        r = subprocess.run([BASH, str(ROOT / "bin/uninstall.sh"), "--yes"], cwd=top, capture_output=True, text=True,
                           env={"HOME": str(home), "PATH": "/usr/bin:/bin"})
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((top / "a/canary").read_text(), "keep")
        self.assertEqual((top / "b/.agent-jack/venv/canary").read_text(), "keep")
        self.assertFalse((home / ".agent-jack/node").exists())
        self.assertFalse((home / ".agent-jack/venv").exists())

    def test_unsafe_home_is_refused_before_anything_is_touched(self):
        top = Path(tempfile.mkdtemp(prefix="aj-badhome-"))
        self.addCleanup(shutil.rmtree, top, True)
        for rel in ("rel", "-rel", "."):
            (top / rel / ".agent-jack/node").mkdir(parents=True, exist_ok=True)
        cases = {"unset": None, "empty": "", "relative": "rel", "dot": ".", "dash": "-rel", "root": "/", "root twice": "//",
                 "root via ..": str(top) + "/" + "/".join([".."] * len(top.parts)), "newline": str(top / "a") + "\nb"}
        for what, h in cases.items():
            env = {"PATH": "/usr/bin:/bin"}
            if h is not None:
                env["HOME"] = h
            r = subprocess.run([BASH, str(ROOT / "bin/uninstall.sh"), "--yes"], cwd=top, capture_output=True, text=True, env=env)
            self.assertEqual(r.returncode, 2, what + r.stdout + r.stderr)
            self.assertIn("so nothing was removed", r.stderr, what)
            self.assertEqual(r.stdout, "", what)
        for rel in ("rel", "-rel", "."):
            self.assertTrue((top / rel / ".agent-jack/node").is_dir(), rel)

    def test_linked_doctor_folder_is_refused(self):
        docs = self.home / "Documents"; (docs / "node").mkdir(parents=True); (docs / "node/keep").write_text("mine")
        shutil.rmtree(self.home / ".agent-jack"); (self.home / ".agent-jack").symlink_to(docs)
        r = self.run_it("--yes")
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertIn("is a link", r.stderr)
        self.assertEqual((docs / "node/keep").read_text(), "mine")

    def test_newline_home_keeps_sibling_and_cwd_folders_even_without_the_home_guard(self):
        # the refusal above is the first wall; the per-path re-check must hold on its own (B3 P3-2)
        top = Path(tempfile.mkdtemp(prefix="aj-nl-"))
        self.addCleanup(shutil.rmtree, top, True)
        (top / "bin").mkdir()
        shutil.copy(ROOT / "versions.env", top / "versions.env")
        script = "".join(l for l in (ROOT / "bin/uninstall.sh").read_text().splitlines(True) if "# newline guard" not in l)
        (top / "bin/uninstall.sh").write_text(script)
        home = top / "w" / "a\nb"
        for d in (home / ".agent-jack/node", top / "w/a/.agent-jack/node", top / "w/b/.agent-jack/node"):
            d.mkdir(parents=True); (d / "canary").write_text("keep")
        r = subprocess.run([BASH, str(top / "bin/uninstall.sh"), "--yes"], cwd=top / "w", capture_output=True, text=True,
                           env={"HOME": str(home), "PATH": "/usr/bin:/bin"})
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((top / "w/a/.agent-jack/node/canary").read_text(), "keep")   # the sibling
        self.assertEqual((top / "w/b/.agent-jack/node/canary").read_text(), "keep")   # relative to the working directory
        self.assertNotIn("in the Trash", r.stdout)


    def test_newline_home_keeps_a_recorded_app_and_its_record(self):
        # the kept-app branch (v1.1.4 bump, B3 #11 approve P3): a recorded app whose path holds a newline is never moved
        top = Path(tempfile.mkdtemp(prefix="aj-nl-app-"))
        self.addCleanup(shutil.rmtree, top, True)
        (top / "bin").mkdir()
        shutil.copy(ROOT / "versions.env", top / "versions.env")
        script = "".join(l for l in (ROOT / "bin/uninstall.sh").read_text().splitlines(True) if "# newline guard" not in l)
        (top / "bin/uninstall.sh").write_text(script)
        home = top / "w" / "a\nb"
        app = home / "Applications/T3 Code (Beta).app/Contents"
        decoy = top / "w/b/Applications/T3 Code (Beta).app/Contents"   # the second half of the split path, from the working directory
        for d in (app, decoy, home / ".agent-jack"):
            d.mkdir(parents=True)
        (app / "Info.plist").write_text("recorded"); (decoy / "Info.plist").write_text("decoy")
        rec = home / ".agent-jack/installed-apps"
        rec.write_text("T3 Code (Beta)|0.1.11|2026-11-21T12:00:00Z|~/Applications\n")
        r = subprocess.run([BASH, str(top / "bin/uninstall.sh"), "--yes"], cwd=top / "w", capture_output=True, text=True,
                           env={"HOME": str(home), "PATH": "/usr/bin:/bin"})
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("(not one of the app paths this script may move)", r.stdout)
        self.assertEqual((app / "Info.plist").read_text(), "recorded")
        self.assertEqual((decoy / "Info.plist").read_text(), "decoy")
        self.assertTrue(rec.exists(), "the record of a kept app was removed")
        self.assertNotIn("in the Trash", r.stdout)
        self.assertFalse((home / ".Trash").exists() and any((home / ".Trash").iterdir()))

    def test_linked_developer_folder_is_refused(self):
        other = self.home / "Elsewhere"; (other / "t3-code-tentacles").mkdir(parents=True); (other / "t3-code-tentacles/keep").write_text("mine")
        (self.home / "Developer").symlink_to(other)
        r = self.run_it("--yes")
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertIn("~/.agent-jack or ~/Developer is a link", r.stderr)
        self.assertEqual((other / "t3-code-tentacles/keep").read_text(), "mine")
        self.assertTrue((self.home / ".agent-jack/node").is_dir())   # refused before anything was touched


class Rollback(unittest.TestCase):
    def roll(self, tag, cwd=ROOT):
        return subprocess.run([BASH, str(Path(cwd) / "bin/rollback.sh"), tag], capture_output=True, text=True, env={"PATH": "/usr/bin:/bin", "HOME": tempfile.gettempdir()})

    def test_refuses_tags_that_install_the_fork(self):
        for tag in ("v1.0.0", "v1.0.5", "v1.1.0"):
            r = self.roll(tag)
            self.assertEqual(r.returncode, 2, tag)
            self.assertIn("T3 Code TPLUS fork", r.stderr)

    def test_refuses_git_revision_syntax(self):
        for tag in ("v1.1.1^{commit}~12", "v1.1.4^", "v1.1.4~1", "v1.1.4:bin", "refs/tags/v1.1.4", "../v1.1.4", "-v1.1.4", "--orphan=x", "v2@{1}", "v1.1.4-rc1", "main"):
            r = self.roll(tag)
            self.assertEqual(r.returncode, 2, tag)
            self.assertIn("is not a setup tag", r.stderr, tag)
        self.assertIn("usage", self.roll("").stderr)

    def test_refuses_installer_tags_and_names_the_doctor(self):
        for tag in ("v1.1.1", "v1.1.2", "v1.1.3"):
            r = self.roll(tag)
            self.assertEqual(r.returncode, 2, tag)
            self.assertIn("KRA-10943", r.stderr)
            self.assertIn("onboarding/main/agent-jack/doctor.sh", r.stderr)

    def git(self, *a, cwd):
        subprocess.run(["git", *a], cwd=cwd, check=True, capture_output=True,
                       env={"PATH": "/usr/bin:/bin", "HOME": tempfile.gettempdir(), "GIT_CONFIG_NOSYSTEM": "1",
                            "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid"})

    def repo(self):
        top = Path(tempfile.mkdtemp(prefix="aj-rollback-"))
        self.addCleanup(shutil.rmtree, top, True)
        origin, work = top / "origin.git", top / "work"
        self.git("init", "-q", "--bare", str(origin), cwd=top)
        self.git("clone", "-q", str(origin), str(work), cwd=top)
        (work / "bin").mkdir()
        doctor = work / "bin/doctor.sh"
        doctor.write_text('#!/bin/bash\necho "doctor of $(git -C "$(dirname "$0")/.." describe --tags)" > "$(dirname "$0")/../../ran"\nexit 3\n')
        doctor.chmod(0o755)
        shutil.copy(ROOT / "bin/rollback.sh", work / "bin/rollback.sh")
        self.git("add", "-A", cwd=work); self.git("commit", "-qm", "tag", cwd=work); self.git("tag", "v1.1.4", cwd=work)
        doctor.write_text("#!/bin/bash\nexit 0\n"); self.git("commit", "-qam", "later", cwd=work)
        self.git("branch", "-M", "main", cwd=work); self.git("push", "-q", "origin", "main", "--tags", cwd=work)
        return top, origin, work

    def head(self, work):
        return subprocess.run(["git", "-C", str(work), "symbolic-ref", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()

    def test_allowed_tag_hands_over_to_its_doctor_and_restores_the_folder(self):
        top, origin, work = self.repo()
        r = self.roll("v1.1.4", work)
        self.assertEqual(r.returncode, 3, r.stdout + r.stderr)   # the tag's doctor ran and its code comes through
        self.assertEqual((top / "ran").read_text(), "doctor of v1.1.4\n")
        self.assertEqual(self.head(work), "main")
        self.assertEqual((work / "bin/doctor.sh").read_text(), "#!/bin/bash\nexit 0\n")
        r = self.roll("v9.9.9", work)
        self.assertEqual(r.returncode, 2)
        self.assertIn("is not a tag on origin", r.stderr)

    def test_local_only_or_repointed_tag_is_refused(self):
        top, origin, work = self.repo()
        self.git("tag", "v1.5.0", "main", cwd=work)   # never pushed
        r = self.roll("v1.5.0", work)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertIn("is not a tag on origin (it exists only here, or not at all)", r.stderr)
        self.git("tag", "-f", "v1.1.4", "main", cwd=work)   # same name, another commit than origin's
        r = self.roll("v1.1.4", work)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertIn("Your local tag v1.1.4 points elsewhere than origin's; remove it with: git -C", r.stderr)
        self.assertFalse((top / "ran").exists())
        self.assertEqual(self.head(work), "main")

    def test_only_the_exact_tag_ref_on_origin_counts(self):
        # ls-remote matches pattern tails: a branch named refs/tags/<tag> on origin must not stand in for the tag
        top, origin, work = self.repo()
        self.git("push", "-q", "origin", "main:refs/heads/refs/tags/v1.6.0", cwd=work)
        self.git("tag", "v1.6.0", "main", cwd=work)   # local only, at the same commit as that branch
        r = self.roll("v1.6.0", work)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertIn("is not a tag on origin", r.stderr)
        self.assertFalse((top / "ran").exists())

    def test_unreachable_origin_says_so_in_one_sentence(self):
        top, origin, work = self.repo()
        shutil.rmtree(origin)
        r = self.roll("v1.1.4", work)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
        self.assertEqual(r.stderr.strip(), "Could not reach origin to check v1.1.4; connect to the internet, then run this again.")

    def test_public_text_names_no_unreleased_tag(self):   # B3 P3-4: refusals print the doctor line, never a tag to go to
        r = self.roll("v1.0.5")
        self.assertIn("Run the Agent Jack doctor instead:", r.stderr)
        self.assertIn("onboarding/main/agent-jack/doctor.sh", r.stderr)
        self.assertNotRegex(r.stderr, r"v1\.1\.[4-9]")
        # the guide names no tag newer than the one this commit is cut as (the bump and its tag go public in one publish)
        tag = re.search(r"^SETUP_TAG=(\S+)", (ROOT / "versions.env").read_text(), re.M).group(1)
        key = lambda v: tuple(map(int, v[1:].split(".")))
        self.assertEqual([v for v in re.findall(r"\bv\d+\.\d+\.\d+\b", (ROOT / "AGENTS.md").read_text()) if key(v) > key(tag)], [])


class Selftest(unittest.TestCase):
    """bin/doctor.sh --selftest offline: fake curl and git answer, so only the pin rules decide (P2-1 shell twin, P2-2, P3-3)."""

    def run_with(self, edit):
        top = Path(tempfile.mkdtemp(prefix="aj-selftest-"))
        self.addCleanup(shutil.rmtree, top, True)
        (top / "bin").mkdir(); (top / "fake").mkdir()
        shutil.copy(ROOT / "bin/doctor.sh", top / "bin/doctor.sh")
        (top / "versions.env").write_text(edit((ROOT / "versions.env").read_text()))
        for tool, body in (("curl", "exit 0"), ("git", "exit 0")):
            (top / "fake" / tool).write_text("#!/bin/sh\n" + body + "\n"); (top / "fake" / tool).chmod(0o755)
        r = subprocess.run([BASH, str(top / "bin/doctor.sh"), "--selftest"], capture_output=True, text=True,
                           env={"PATH": f"{top / 'fake'}:/usr/bin:/bin", "HOME": str(top)})
        return [l for l in (r.stdout + r.stderr).splitlines() if "FAIL" in l or "unbound" in l]

    @staticmethod
    def drop(key):
        return lambda t: "".join(l for l in t.splitlines(True) if not l.startswith(key + "="))

    def test_shipped_pins_pass_the_pin_rules(self):
        fails = self.run_with(lambda t: t)
        self.assertEqual([l for l in fails if "tag " not in l], [])   # only the faked tag lookups fail offline

    def test_node_pins_are_one_unit(self):
        cases = {
            "NODE_SHA256_MAC_X64": self.drop("NODE_SHA256_MAC_X64"),
            "NODE_SHA256_MAC_ARM64": lambda t: t.replace("NODE_SHA256_MAC_ARM64=e7131995", "NODE_SHA256_MAC_ARM64=E7131995"),
            "NODE_VERSION": self.drop("NODE_VERSION"),
        }
        for key, edit in cases.items():
            fails = self.run_with(edit)
            self.assertIn(f"FAIL selftest node {key}", "\n".join(fails), key)
            self.assertIn("(AJ-PIN-01)", "\n".join(fails), key)
            self.assertFalse(any("unbound" in l for l in fails), fails)
            self.assertFalse(any("disagree" in l for l in fails), fails)   # Node keys are not paired with an asset key

    def test_t3_checksum_still_pairs_with_its_asset(self):
        fails = self.run_with(lambda t: t.replace("T3_SHA256_WIN_X64=TBD", "T3_SHA256_WIN_X64=" + "a" * 64))
        self.assertIn("FAIL selftest checksum T3_SHA256_WIN_X64 and T3_ASSET_WIN_X64 disagree on TBD", fails)

    def test_guardian_commit_must_be_40_hex(self):
        fails = self.run_with(lambda t: t.replace("GUARDIAN_COMMIT=bbba0e26c61fe7a8b25484749ffb0b34a71db96b", "GUARDIAN_COMMIT=bbba0e2"))
        self.assertIn("FAIL selftest commit GUARDIAN_COMMIT is not 40 hex", fails)


class Docs(unittest.TestCase):
    def test_every_doc_checks_out_the_setup_tag(self):   # the 12 paste-block places cannot drift from versions.env (P3-2)
        tag = re.search(r"^SETUP_TAG=(\S+)", (ROOT / "versions.env").read_text(), re.M).group(1)
        found = [(p.name, t) for p in ROOT.glob("*.md") for t in re.findall(r"git checkout (v\d+\.\d+\.\d+)", p.read_text())]
        self.assertGreaterEqual(len(found), 12)
        self.assertEqual([f for f in found if f[1] != tag], [])


class RetiredPointers(unittest.TestCase):
    def test_installer_and_doctor_point_to_the_one_doctor(self):
        for f in ("bin/install.sh", "bin/doctor.sh"):
            r = subprocess.run([BASH, str(ROOT / f), "all"], capture_output=True, text=True, env={"PATH": "/usr/bin:/bin", "HOME": tempfile.gettempdir()})
            self.assertEqual(r.returncode, 3, f)
            self.assertIn("raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh", r.stdout)


if __name__ == "__main__":
    unittest.main()
