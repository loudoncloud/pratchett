# Roadmap

Ideas for improving pratchett, roughly in priority order within each section.
Tick an item in the same commit that completes it.

## Robustness

- [x] Colour only when output is a terminal; honour `NO_COLOR`, `-n`, `--no-color` (1.1.0)
- [x] Fit any terminal width: plain below 30 columns, DEATH needs 48, overlong words wrap (1.1.0)
- [x] Tag DEATH's lines explicitly with a `speaker` instead of guessing from capitals (1.1.0)
- [x] Correct frame without a UTF-8 locale (1.2.0)
- [x] Searches containing `?`, `*` or `[` (1.2.0)
- [ ] Clear error when zsh isn't installed (common on Linux), and a note in the README

## Testing and releases

- [x] End-to-end tests for the command: colour, every quote at every width, DEATH, locale, flags (1.1.0, 1.2.0)
- [x] Tab-completion tests driven through a real zsh (1.2.0)
- [x] CI on macOS and Linux for every push (1.2.0)
- [x] Weekly check that every quote still matches Wikiquote (1.2.0)
- [ ] Automate releases: on a version tag, create the GitHub release, compute the checksum and update the Homebrew tap

## Features

- [x] Tab completion (zsh) for options and book titles (1.2.0)
- [ ] `tp -b <book>`: quotes from one book only; `tp --books` to list the books
- [ ] No repeats: remember recently shown quotes so the startup quote doesn't come round again soon
- [ ] `tp -t`: quote of the day (the same quote all day, chosen by the date)
- [ ] More characters drawn by cowsay for their own lines: the Librarian ("Ook."), the Luggage
- [ ] `tp -c <character>`: quotes by one character (needs the speaker field below)
- [ ] Bash and fish completion, for people using the standalone command from other shells

## Content

- [ ] Add `speaker` for more quotes (Granny Weatherwax, Vimes, Vetinari…) where the source makes it clear, shown as "— Granny Weatherwax, Carpe Jugulum"
- [ ] More quotes, and a better balance across books (some have seven, some one)
- [ ] Keep where each quote is in the book (Wikiquote has page numbers; chapters where available)
- [ ] Check quotes against the books themselves, a few at a time

## Reaching people

- [ ] List in [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [ ] Propose to oh-my-zsh as a built-in plugin, as `hitchhiker` is (the quotes' CC BY-SA licence may need discussing)
