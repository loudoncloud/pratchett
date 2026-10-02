"""Tab-completion checks: drive an interactive zsh in a pseudo-terminal, press
Tab, and read what zsh offers. Run: python3 tests/test_completion.py"""
import os, pty, re, select, shutil, sys, tempfile, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]|\x1b[=>]|\r")

def complete(setup, typed, wait=1.5, tabs=1):
    """Start zsh with `setup` as its .zshrc, type `typed` + Tab(s), return the screen text."""
    home = tempfile.mkdtemp()
    # Debian/Ubuntu's /etc/zsh/zshrc runs its own compinit unless told not to
    Path(home, ".zshenv").write_text("skip_global_compinit=1\n")
    Path(home, ".zshrc").write_text(setup + "\nPS1='> '\n")
    env = dict(os.environ, ZDOTDIR=home, HOME=home, TERM="xterm", COLUMNS="100")
    env.pop("PRATCHETT_DIR", None)
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("zsh", ["zsh", "-i"], env)
    def read(t):
        out, end = b"", time.time() + t
        while time.time() < end:
            if select.select([fd], [], [], 0.1)[0]:
                try: out += os.read(fd, 65536)
                except OSError: break
        return out.decode(errors="replace")
    read(1.0)
    os.write(fd, typed.encode())
    screen = ""
    for _ in range(tabs):
        os.write(fd, b"\t")
        screen += read(wait)
    os.write(fd, b"\x03exit\n"); read(0.3)
    os.close(fd); os.waitpid(pid, 0)
    shutil.rmtree(home, ignore_errors=True)
    return ANSI.sub("", screen)

ok = True
def check(name, cond, screen=""):
    global ok; ok &= bool(cond)
    print(f"  {'PASS' if cond else 'FAIL'}  {name}")
    if not cond: print("        screen:", screen[-300:].replace("\n", "\n        "))

plugin = f"source {ROOT}/pratchett.plugin.zsh"
init = "autoload -Uz compinit && compinit -u -d $HOME/.zcompdump"
before = f"{plugin}\n{init}"          # like oh-my-zsh: plugin, then compinit
after = f"{init}\n{plugin}"           # plugin loaded after compinit

for label, rc in (("plugin before compinit", before), ("plugin after compinit", after)):
    s = complete(rc, "pratchett -")
    check(f"{label}: flags listed with descriptions",
          all(x in s for x in ("short quotes only", "quote of the day", "DEATH says it", "rainbow", "no colour")), s)
s = complete(before, "tp -")
check("tp alias completes flags too", "short quotes only" in s, s)
s = complete(before, "pratchett Nigh")
check("book title completes (Nigh → Night\\ Watch)", "Night\\ Watch" in s, s)
s = complete(before, "pratchett Thief")
check("book title completes (Thief → Thief\\ of\\ Time)", "Thief\\ of\\ Time" in s, s)
s = complete(before, "pratchett -s Nigh")
check("book completes after a flag (-s Nigh → Night\\ Watch)", "Night\\ Watch" in s, s)
s = complete(after, "pratchett The\\ We")
check("multi-word title (The\\ We → The\\ Wee\\ Free\\ Men)", "The\\ Wee\\ Free\\ Men" in s, s)
s = complete(before, "pratchett -b Nigh")
check("-b completes book titles (-b Nigh → Night\\ Watch)", "Night\\ Watch" in s, s)
s = complete(before, "pratchett --book=Thie")
check("--book= completes book titles", "Thief\\ of\\ Time" in s, s)
s = complete(before, "pratchett --bo", tabs=2)
check("--books and --book offered", "--books" in s and "list the books" in s, s)
s = complete(before, "pratchett -b Terry")
check("speaker prefix dropped (-b Terry → the tweet's source)", "Twitter" in s and "Death," not in s, s)
s = complete(before, "pratchett -v ")
check("nothing offered after -v", "short quotes only" not in s and "book title" not in s, s)

# Homebrew-style: plugin not loaded; completion found via fpath, quotes via the command on PATH
brew = f"fpath=({ROOT} $fpath)\npath=({ROOT}/bin $path)\n{init}"
s = complete(brew, "pratchett -")
check("standalone (Homebrew-style): flags", "short quotes only" in s, s)
s = complete(brew, "pratchett Nigh")
check("standalone (Homebrew-style): book titles", "Night\\ Watch" in s, s)

print("ALL PASS" if ok else "SOME FAILED"); sys.exit(0 if ok else 1)
