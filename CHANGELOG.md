# Changelog

Each release's notes are taken from its section here, so add a `## x.y.z` section
before tagging `vx.y.z`.

## 1.4.0

- `-b BOOK` (or `--book BOOK`): quotes from one book. Any case, and part of the
  title is enough (`-b jingo`, `-b "wee free"`); combines with `-s` and search words.
- `--books`: list the books, with how many quotes each has.
- Tab completion offers book titles after `-b`, and the new options.
- Long options are now matched as whole words, so a search like `-- --helpful`
  is no longer mistaken for `--help`.

## 1.3.0 (2026-10-02)

- The `pratchett` command now explains how to install zsh when it's missing,
  instead of failing with `env: zsh: No such file or directory`.
- Releases are automated: pushing a version tag runs the tests, publishes the
  GitHub release and updates the Homebrew tap.

## 1.2.0 (2026-10-02)

- Tab completion (zsh) for options and book titles, for both `pratchett` and `tp`.
  Installed by the plugin and by Homebrew.
- Fixed: searches containing `?`, `*` or `[` matched nothing.
- Fixed: the frame was misdrawn without a UTF-8 locale (cron jobs, minimal containers).
- Fixed: long attributions under DEATH ran past 48-column terminals.
- CI on macOS and Linux, and a weekly check that every quote still matches Wikiquote.

## 1.1.0 (2026-10-01)

- Colour only when output is a terminal; honours `NO_COLOR`, `-n` and `--no-color`,
  so piped output is clean text.
- Fits any terminal width: plain below 30 columns, DEATH needs 48, overlong words wrap.
- DEATH's lines are tagged explicitly and attributed ("— Death, Reaper Man").
- Fixed: long attributions under DEATH were cut off.
- Added `--help` and `--version`; usage errors go to stderr.
- Added an end-to-end test suite (`tests/test_pratchett.py`).

## 1.0.0 (2026-10-01)

- First release: 152 Discworld quotes sourced from Wikiquote, framed, rainbow and
  plain styles, search, short mode, and DEATH via cowsay.
