"""End-to-end checks for the pratchett command. Run: python3 tests/test_pratchett.py"""
import os, pty, re, shutil, subprocess, sys, tempfile, unicodedata
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
B = str(ROOT / "bin" / "pratchett")
# Keep the tests' no-repeat history away from the real one
HISTDIR = tempfile.mkdtemp()
os.environ["PRATCHETT_HISTORY_FILE"] = os.path.join(HISTDIR, "history")
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
      "— Death, Terry Pratchett's Twitter account (12 March 2015)" in tweet)
check("'CATS ARE NICE' (dialogue) is framed", "╭" in run(["CATS ARE NICE"]))
check("'Today is a good day' not DEATH", "╭" in run(["good day for someone"]))
check("-d forces DEATH", "(___/" in run(["-d", "-s"]))
check("DEATH skipped below 48 columns", "(___/" not in run(["THERE IS NO HOPE"], cols=47))
check("-p never draws DEATH", "(___/" not in run(["-p", "THERE IS NO HOPE"]))
no_cowsay = subprocess.run([B, "THERE IS NO HOPE"], capture_output=True, text=True,
                           env={"PATH": "/usr/bin:/bin", "COLUMNS": "80"}).stdout
check("without cowsay, DEATH's lines are framed", "╭" in no_cowsay and "(___/" not in no_cowsay)

print("books")
def by(book, out):
    """The output's attribution is this book, with or without a speaker."""
    return re.search(r"— (?:[^,\n]+, )?" + re.escape(book) + r"\s*$", out, re.M) is not None
def res(args):
    r = subprocess.run([B, *args], capture_output=True, text=True, env=dict(os.environ, COLUMNS="80"))
    return r.returncode, r.stdout, r.stderr
listing = res(["--books"])[1].splitlines()
counts = {l[5:]: int(l[:3]) for l in listing}
check(f"--books lists every book once ({len(counts)} books)", len(counts) == len(listing) > 30)
check("--books counts add up to every quote", sum(counts.values()) == len(QUOTES))
check("--books in collection order (The Colour of Magic first)", listing[0].endswith("The Colour of Magic"))
check("--books has no colour when piped", not ESC.search("\n".join(listing)))
for book, n in counts.items():
    seen = {res(["-p", "-b", book])[1].strip().splitlines()[-1 if n == 1 else -2].strip() for _ in range(3)}
    if not all(l.endswith(book) for l in seen):
        check(f"-b {book!r} only gives quotes from it", False); break
else:
    check("-b <exact title> only gives that book, for every book", True)
code, out, _ = res(["-p", "-b", "jingo"])
check("-b is case-insensitive and partial (jingo)", code == 0 and by("Jingo", out))
check("note says which book (1 of 7 quotes from Jingo)", f"(1 of {counts['Jingo']} quotes from Jingo)" in out)
code, out, _ = res(["-p", "-b", "wee free"])
check("-b matches part of a title (wee free → The Wee Free Men)", code == 0 and by("The Wee Free Men", out))
code, out, err = res(["-b", "the"])
check("-b ambiguous: lists the matching books, exit 1", code == 1 and "matches" in err and "Hogfather" in err and not out)
code, out, err = res(["-b", "zzz"])
check("-b unknown: error on stderr, exit 1", code == 1 and "no book matches" in err and not out)
code, out, err = res(["-b"])
check("-b with no title: error, exit 1", code == 1 and "needs a book title" in err)
code, out, _ = res(["-p", "--book=Thud!"])
check("--book=TITLE works", code == 0 and by("Thud!", out))
code, out, _ = res(["-p", "--book", "Thud!"])
check("--book TITLE works", code == 0 and by("Thud!", out))
code, out, _ = res(["-p", "-b", "Terry Pratchett's Twitter account (12 March 2015)"])
check("-b exact title with brackets and apostrophe", code == 0 and "WALK TOGETHER" in out)
code, out, _ = res(["-p", "-b", "Going Postal", "crowd"])
check("-b with search words", code == 0 and "crowd" in out and by("Going Postal", out))
code, out, _ = res(["-b", "Jingo", "zzqq"])
check("-b with a search that misses: says so, exit 1", code == 1 and "No quote from Jingo mentions" in out)
code, out, _ = res(["-p", "-s", "-b", "Mort"])
check("-b with -s", code == 0 and by("Mort", out))
code, out, _ = res(["-p", "--", "--helpful"])
check("words after -- are search words, not options", code == 1 and "--helpful" in out)

print("no repeats")
hist = os.environ["PRATCHETT_HISTORY_FILE"]
def first_lines(args, n):
    return [run(["-p", *args]).split("\n")[1] for _ in range(n)]
if os.path.exists(hist): os.remove(hist)
seen = first_lines([], 50)
check("50 random quotes in a row: no repeats", len(set(seen)) == 50)
with open(hist) as f: lines = f.read().splitlines()
check("history records what was shown", len(lines) == 50)
first_lines([], 70)
with open(hist) as f: lines = f.read().splitlines()
check("history keeps only the last 100", len(lines) == 100)
os.remove(hist)
jingo = first_lines(["-b", "Jingo"], 14)
check("7-quote book: no repeat within any 3 picks in a row",
      all(jingo[i] not in jingo[i - 3:i] for i in range(3, 14)))
check("1-quote book still works every time",
      all("Mister Lipwig" in l or "drop everything" in l for l in first_lines(["-b", "Raising Steam"], 3)))
check("1-match search still works every time", all("whole sword" in l for l in first_lines(["whole sword"], 3)))
os.remove(hist)
out = subprocess.run([B, "-p"], capture_output=True, text=True, env=dict(os.environ, PRATCHETT_NO_HISTORY="1")).stdout
check("PRATCHETT_NO_HISTORY=1: quote shown, nothing recorded", "—" in out and not os.path.exists(hist))
r = subprocess.run([B, "-p"], capture_output=True, text=True,
                   env=dict(os.environ, PRATCHETT_HISTORY_FILE="/nonexistent-root/x/history"))
check("unwritable history: quote still shown, exit 0, no error", r.returncode == 0 and "—" in r.stdout and not r.stderr)
leaky = [o for o in ([], ["-b", "Jingo"], ["-s"], ["vimes"], ["-b", "Jingo", "-s"])
         for _ in range(3) if re.match(r"^\w+=", run(["-p", *o]).lstrip("\n"))]
check("no stray variable dumps in the output (q=...)", not leaky)
code, out, _ = res(["-p", "-b", "  jingo "])
check("-b ignores surrounding spaces", code == 0 and by("Jingo", out))

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
shutil.rmtree(HISTDIR, ignore_errors=True)
print("ALL PASS" if ok else "SOME FAILED"); sys.exit(0 if ok else 1)
