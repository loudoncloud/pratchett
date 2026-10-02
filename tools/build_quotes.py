#!/usr/bin/env python3
"""Rebuild quotes/pratchett from Wikiquote.

Every quote in the collection is copied verbatim from English Wikiquote, so the
text can be checked against a cited source. The picks live in tools/picks.json:

  {"book": "Jingo", "starts": "The man had a point."}
      the Wikiquote entry under that book whose text starts with "starts"
  ... "from": "X", "to": "Y"
      keep only the excerpt from X through Y (both must appear verbatim)
  ... "replace": [["old", "new"]]
      fix an obvious typo in the source before using it
  {"book": "Diggers", "page": "Terry Pratchett", "text": "..."}
      a quote from another page, kept only if the text appears there verbatim
  ... "speaker": "Death"
      who says it; shown as "— Death, Reaper Man" (and DEATH's lines get the drawing)

The Wikiquote revisions used are pinned in tools/revisions.json, so a rebuild is
reproducible. Pass --update to fetch the latest revisions instead.

Usage: tools/build_quotes.py [--update]
"""
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
OUT = ROOT / "quotes" / "pratchett"
API = "https://en.wikiquote.org/w/api.php"
UA = "pratchett-quotes-builder/1.0 (https://github.com/loudoncloud/pratchett)"

# The main Discworld page covers Small Gods onwards; earlier novels have their own pages
PAGES = {
    "Discworld": None,
    "The Colour of Magic": "The Colour of Magic",
    "The Light Fantastic": "The Light Fantastic",
    "Equal Rites": "Equal Rites",
    "Mort": "Mort",
    "Sourcery": "Sourcery",
    "Wyrd Sisters": "Wyrd Sisters",
    "Pyramids (novel)": "Pyramids",
    "Guards! Guards!": "Guards! Guards!",
    "Eric (novel)": "Eric",
    "Moving Pictures (novel)": "Moving Pictures",
    "Reaper Man": "Reaper Man",
    "Witches Abroad": "Witches Abroad",
    "Terry Pratchett": None,
}


def fetch(title, revid=None):
    """Return (revid, wikitext) for a page, optionally at a pinned revision."""
    params = {"action": "query", "prop": "revisions", "rvprop": "ids|content",
              "rvslots": "main", "format": "json", "formatversion": "2"}
    if revid:
        params["revids"] = revid
    else:
        params["titles"] = title
    req = urllib.request.Request(API + "?" + urllib.parse.urlencode(params),
                                 headers={"User-Agent": UA})
    with urllib.request.urlopen(req) as r:
        page = json.load(r)["query"]["pages"][0]
    rev = page["revisions"][0]
    return rev["revid"], rev["slots"]["main"]["content"]


def clean(s):
    s = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", s)
    s = re.sub(r"'''|''", "", s)
    s = re.sub(r"<br\s*/?>", " ", s)
    s = re.sub(r"\{\{(?:sc|smallcaps|small caps)\|([^}]*)\}\}",
               lambda m: m.group(1).upper(), s, flags=re.I)
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"\{\{[^}]*\}\}", "", s)
    return s.strip()


def parse(text, out, stop=None):
    """Collect bulleted quotes (with ':' continuation lines) under each === Book === heading."""
    book = cur = None
    for line in text.splitlines():
        if stop and line.startswith(stop):
            break
        m = re.match(r"^===+\s*(.*?)\s*===+", line)
        if m:
            book = re.sub(r"\s*\(\d{4}.*?\)\s*$", "", clean(m.group(1)))
            cur = None
        elif line.startswith("=="):
            book = cur = None
        elif line.startswith("* ") and book:
            cur = {"book": book, "lines": [clean(line[2:])]}
            out.append(cur)
        elif line.startswith(":") and not line.startswith("::") and cur:
            cur["lines"].append(clean(line.lstrip(":")))
        elif line.startswith("**"):
            pass  # source/chapter note under a quote
        elif line.strip():
            cur = None


def candidates(pages):
    out = []
    parse(pages["Discworld"], out, stop="==Video Games==")
    for title, book in PAGES.items():
        if not book:
            continue
        body = re.split(r"==\s*(?:External links|See also|Dialogue)", pages[title])[0]
        body = "\n".join(l for l in body.splitlines() if not l.startswith("="))
        parse(f"=== {book} ===\n{body}", out)
    for q in out:
        q["text"] = " ".join(q["lines"]).strip()
    return out


def tidy(t):
    t = re.sub(r"\s*\((?:p|pp)\.[^)]*\)\s*$", "", t).strip()   # trailing page reference
    return re.sub(r"([.!?…—”’\"'])(“)", r"\1 \2", t)          # space between dialogue lines


def attribution(p):
    # The plugin splits "Speaker, Book" at the first ", ", so neither part may contain one
    for part in (p.get("speaker"), p["book"]):
        if part and ", " in part:
            sys.exit(f"', ' isn't allowed in a book or speaker name: {part!r}")
    return f"{p['speaker']}, {p['book']}" if p.get("speaker") else p["book"]


def main():
    update = "--update" in sys.argv[1:]
    revfile = TOOLS / "revisions.json"
    pinned = {} if update or not revfile.exists() else json.loads(revfile.read_text())

    pages, revisions = {}, {}
    for title in PAGES:
        revisions[title], pages[title] = fetch(title, pinned.get(title))
        print(f"  {title}: revision {revisions[title]}", file=sys.stderr)

    cands = candidates(pages)
    picks = json.loads((TOOLS / "picks.json").read_text())
    entries, problems = [], []
    for p in picks:
        if "page" in p:
            if p["text"] not in clean(pages[p["page"]]):
                problems.append(f"not found on {p['page']}: {p['text'][:60]}")
                continue
            entries.append((p["text"], attribution(p)))
            continue
        hits = [c for c in cands if c["book"] == p["book"] and c["text"].startswith(p["starts"])]
        if len(hits) != 1:
            problems.append(f"{len(hits)} matches in {p['book']}: {p['starts']}")
            continue
        t = hits[0]["text"]
        for old, new in p.get("replace", []):
            t = t.replace(old, new)
        t = tidy(t)
        if "from" in p:
            try:
                s = t.index(p["from"])
                t = t[s:t.index(p["to"], s) + len(p["to"])]
            except ValueError:
                problems.append(f"excerpt not found in {p['book']}: {p['from']}..{p['to']}")
                continue
        entries.append((t, attribution(p)))

    if problems:
        print("Some picks no longer match Wikiquote:", *problems, sep="\n  ", file=sys.stderr)
        sys.exit(1)

    OUT.write_text("\n%\n".join(f"{t}\n\n    — {b}" for t, b in entries) + "\n")
    revfile.write_text(json.dumps(revisions, indent=1) + "\n")
    print(f"Wrote {len(entries)} quotes to {OUT.relative_to(ROOT)}", file=sys.stderr)


if __name__ == "__main__":
    main()
