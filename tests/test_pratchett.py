"""End-to-end checks for the pratchett command. Run: python3 tests/test_pratchett.py"""
import os, pty, re, subprocess, sys, unicodedata
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
B = str(ROOT / "bin" / "pratchett")
VERSION = re.search(r'PRATCHETT_VERSION="([^"]+)"', (ROOT / "pratchett.plugin.zsh").read_text())[1]
ESC = re.compile(r"\x1b\[[0-9;]*m")

def run(args, cols=80, tty=False, env=None):
    e = dict(os.environ, COLUMNS=str(cols), **(env or {}))
    e.pop("NO_COLOR", None) if not (env and "NO_COLOR" in env) else None
    if not tty:
        return subprocess.run([B, *args], env=e, capture_output=True, text=True).stdout
    pid, fd = pty.fork()
    if pid == 0:
        os.execve(B, [B, *args], e)
    out = b""
    while True:
        try: chunk = os.read(fd, 65536)
        except OSError: break
        if not chunk: break
        out += chunk
    os.close(fd); os.waitpid(pid, 0)
    return out.decode().replace("\r\n", "\n")

def width(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in ESC.sub("", s))

ok = True
def check(name, cond):
    global ok; ok &= bool(cond); print(f"  {'PASS' if cond else 'FAIL'}  {name}")

print("1. colour")
check("piped output has no escape codes", not ESC.search(run(["-s"])))
check("terminal output is coloured", ESC.search(run(["-s"], tty=True)))
check("NO_COLOR=1 on a terminal: no colour", not ESC.search(run(["-s"], tty=True, env={"NO_COLOR": "1"})))
check("-n on a terminal: no colour", not ESC.search(run(["-n", "-s"], tty=True)))
check("--no-color on a terminal: no colour", not ESC.search(run(["--no-color", "-s"], tty=True)))
check("--no-colour (British) too", not ESC.search(run(["--no-colour", "-s"], tty=True)))
check("-r -n: no colour", not ESC.search(run(["-r", "-n", "-s"], tty=True)))
check("-r on a terminal is coloured", ESC.search(run(["-r", "-s"], tty=True)))

print("2. widths (every quote, at each width that matters)")
QUOTES = (ROOT / "quotes" / "pratchett").read_text().split("\n%\n")
KEYS = [q.split("\n")[0][:30] for q in QUOTES]
for c in (12, 29, 30, 47, 48, 80, 200):
    over = [k for k in KEYS
            if max(width(l) for l in run(["--", k], cols=c).split("\n")) > c]
    check(f"COLUMNS={c:<3} all {len(KEYS)} quotes fit" + (f" (over: {over[:3]})" if over else ""), not over)
check("every quote is findable by its opening words",
      all("No quote mentions" not in run(["--", k]) for k in KEYS))
check("frame on a terminal fits too (coloured, COLUMNS=48)",
      all(width(l) <= 48 for _ in range(10) for l in run([], cols=48, tty=True).split("\n")))
out = run(["End-of-the-World"], cols=14)
check("17-char word hard-wraps at COLUMNS=14", max(width(l) for l in out.split("\n")) <= 14)
framed = run(["-s"], cols=29)
check("COLUMNS=29 falls back to plain (no frame)", "╭" not in framed)
check("COLUMNS=30 keeps the frame", "╭" in run(["-s"], cols=30))

print("3. DEATH")
for q in ("WALK TOGETHER", "THERE IS NO HOPE", "HOW ELSE CAN", "FALLING ANGEL", "HARVEST HOPE"):
    check(f"'{q}' is drawn by DEATH", "(___/" in run([q], cols=80))
tweet = " ".join(run(["WALK TOGETHER"]).split())
check("long attribution under DEATH shown in full (wrapped)",
      "— Death, Terry Pratchett's Twitter account, 12 March 2015" in tweet)
check("'CATS ARE NICE' (dialogue) is framed", "╭" in run(["CATS ARE NICE"]))
check("'Today is a good day' not DEATH", "╭" in run(["good day for someone"]))
check("-d forces DEATH", "(___/" in run(["-d", "-s"]))
check("DEATH skipped below 48 columns", "(___/" not in run(["THERE IS NO HOPE"], cols=47))
check("-p never draws DEATH", "(___/" not in run(["-p", "THERE IS NO HOPE"]))
no_cowsay = subprocess.run([B, "THERE IS NO HOPE"], capture_output=True, text=True,
                           env={"PATH": "/usr/bin:/bin", "COLUMNS": "80"}).stdout
check("without cowsay, DEATH's lines are framed", "╭" in no_cowsay and "(___/" not in no_cowsay)

print("locale")
for loc in ({}, {"LANG": "C"}, {"LC_ALL": "C"}):
    out = subprocess.run([B, "-s", "damp handshake"], capture_output=True, text=True,
                         env={"PATH": os.environ["PATH"], "COLUMNS": "60", **loc}).stdout
    widths = {width(l) for l in out.split("\n") if l}
    check(f"frame lines all the same width with {loc or 'no locale'}", len(widths) == 1, )

print("flags")
check("-v", run(["-v"]).strip() == f"pratchett {VERSION}")
check("--version", run(["--version"]).strip() == f"pratchett {VERSION}")
check("--help prints usage", run(["--help"]).startswith("usage:"))
bad = subprocess.run([B, "-x"], capture_output=True, text=True)
check("bad flag: usage on stderr, exit 1", bad.returncode == 1 and bad.stderr.startswith("usage:") and not bad.stdout)
check("search treats ? literally", "What had she ever earned?" in run(["-p", "ever earned?"]))
nozsh = subprocess.run([B, "-s"], capture_output=True, text=True, env={"PATH": "/nonexistent"})
check("without zsh: helpful message on stderr, exit 127",
      nozsh.returncode == 127 and "needs zsh" in nozsh.stderr and not nozsh.stdout)
check("search miss exits 1", subprocess.run([B, "zzqq"], capture_output=True).returncode == 1)
print("ALL PASS" if ok else "SOME FAILED"); sys.exit(0 if ok else 1)
