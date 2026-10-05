# Roadmap

Ideas for improving pratchett, roughly in priority order within each section.
Tick an item in the same commit that completes it.

## Robustness

- [x] Colour only when output is a terminal; honour `NO_COLOR`, `-n`, `--no-color` (1.1.0)
- [x] Fit any terminal width: plain below 30 columns, DEATH needs 48, overlong words wrap (1.1.0)
- [x] Tag DEATH's lines explicitly with a `speaker` instead of guessing from capitals (1.1.0)
- [x] Correct frame without a UTF-8 locale (1.2.0)
- [x] Searches containing `?`, `*` or `[` (1.2.0)
- [x] Clear error when zsh isn't installed (common on Linux), and a note in the README (1.3.0)

## Testing and releases

- [x] End-to-end tests for the command: colour, every quote at every width, DEATH, locale, flags (1.1.0, 1.2.0)
- [x] Tab-completion tests driven through a real zsh (1.2.0)
- [x] CI on macOS and Linux for every push (1.2.0)
- [x] Weekly check that every quote still matches Wikiquote (1.2.0)
- [x] Automate releases: on a version tag, create the GitHub release, compute the checksum and update the Homebrew tap (1.3.0)

## Features

- [x] Tab completion (zsh) for options and book titles (1.2.0)
- [x] `tp -b <book>`: quotes from one book only; `tp --books` to list the books (1.4.0)
- [x] No repeats: remember recently shown quotes so the startup quote doesn't come round again soon (1.5.0)
- [x] `tp -t`: quote of the day (the same quote all day, chosen by the date) (1.6.0)
- [ ] More characters drawn by cowsay for their own lines: the Librarian ("Ook."), the Luggage
- [ ] `tp -c <character>`: quotes by one character (needs the speaker field below)
- [x] Bash and fish completion, for people using the standalone command from other shells (1.8.0)

## Content

- [ ] Add `speaker` for more quotes (Granny Weatherwax, Vimes, Vetinari…) where the source makes it clear, shown as "— Granny Weatherwax, Carpe Jugulum"
  - 20 of 213 so far (1.7.0): the rest are narration, exchanges between two characters, or lines the source doesn't attribute. More will need new quotes that name their speaker.
- [x] More quotes, and a better balance across books: 213 quotes, every Discworld novel has at least 5 (1.7.0)
- [ ] Keep where each quote is in the book (Wikiquote has page numbers; chapters where available)
- [ ] Check quotes against the books themselves, a few at a time

## Reaching people

- [ ] List in [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins)
  - Pull request open: [unixorn/awesome-zsh-plugins#2288](https://github.com/unixorn/awesome-zsh-plugins/pull/2288) (2026-10-05); tick when merged.
- [ ] Propose to oh-my-zsh as a built-in plugin, as `hitchhiker` is (the quotes' CC BY-SA licence may need discussing)
- [ ] Get into homebrew/core, so `brew search pratchett` finds it without the tap. Needs, per Homebrew's
  [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy): a repo at least 30 days old
  (from 31 October 2026), and 75 stars, 30 forks or 30 watchers if someone else submits it
  (225 / 90 / 90 if we submit it ourselves).
