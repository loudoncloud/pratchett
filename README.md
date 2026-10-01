# pratchett

[![test](https://github.com/loudoncloud/pratchett/actions/workflows/test.yml/badge.svg)](https://github.com/loudoncloud/pratchett/actions/workflows/test.yml)

Random Terry Pratchett quotes for your terminal: 152 lines from across the
Discworld, each one copied verbatim from [Wikiquote](https://en.wikiquote.org/wiki/Discworld)
with the book it came from.

```
╭──────────────────────────────────────────────────────────────────╮
│                                                                  │
│  The rain was coming down so fast that the drops were having to  │
│  queue.                                                          │
│                                                                  │
│                                             — Interesting Times  │
╰──────────────────────────────────────────────────────────────────╯
```

DEATH delivers his own lines:

```
 __________________________________________
/ THERE IS NO HOPE BUT US. THERE IS NO     \
| MERCY BUT US. THERE IS NO JUSTICE. THERE |
\ IS JUST US.                              /
 ------------------------------------------
    \
     \                        ____________
      \      _______        .'            `.
           .'       `.     /                \
          /  .-----.  \   /
         |  / () () \  |  |
         |  |   ^   |  |  |
         |  \ ||||| /  |  |
          \  `-----'  /   |
          /`.       .'\   |
         /   `-._.-'   \  |
        /   /|     |\   \=|
       (___/ |     | \___)|
             |     |      |
             |     |      |
            /       \     |
           /_________\    |
                           — Death, Reaper Man
```

## Usage

```
pratchett              a random quote, framed (alias: tp)
pratchett -s           short quotes only
pratchett -r           rainbow
pratchett -p           plain, no frame
pratchett -d           DEATH says it
pratchett -n           no colour (also --no-color, or NO_COLOR=1)
pratchett vimes        a random quote containing "vimes"
pratchett -v           version
```

Options combine: `tp -r -d -s` is a short rainbow quote from DEATH.

Tab completion (zsh) covers the options, and book titles for searching:
`pratchett Nigh<Tab>` completes to `Night\ Watch`. It works with every install
method below, for both `pratchett` and `tp`.

Colour is only used on a terminal, so `pratchett | pbcopy` or `pratchett > quote.txt`
gives clean text. It also follows the [NO_COLOR](https://no-color.org) convention. On
terminals narrower than 30 columns the frame is dropped, and DEATH needs 48.

For a quote in every new terminal, add this to the end of `~/.zshrc`:

```zsh
[[ -o interactive ]] && pratchett -s
```

## Install

Needs zsh (the default shell on macOS). [cowsay](https://github.com/cowsay-org/cowsay)
is optional; without it, DEATH's lines appear in a frame like the rest.

**Homebrew**

```sh
brew install loudoncloud/tap/pratchett
```

This gives you a `pratchett` command that works from any shell. In zsh, add
`source $(brew --prefix)/opt/pratchett/libexec/pratchett.plugin.zsh` to `~/.zshrc`
for the `tp` alias.

**oh-my-zsh**

```sh
git clone https://github.com/loudoncloud/pratchett ~/.oh-my-zsh/custom/plugins/pratchett
```

Then add `pratchett` to `plugins=(...)` in `~/.zshrc`.

**zinit / antidote / antigen**

```sh
zinit light loudoncloud/pratchett       # zinit
loudoncloud/pratchett                   # antidote: add to .zsh_plugins.txt
antigen bundle loudoncloud/pratchett    # antigen
```

**Manually**

```sh
git clone https://github.com/loudoncloud/pratchett ~/.pratchett
echo 'source ~/.pratchett/pratchett.plugin.zsh' >> ~/.zshrc
```

Set `PRATCHETT_NO_ALIAS=1` before the plugin loads if you don't want the `tp` alias.

## The quotes

Every quote is taken word-for-word from English Wikiquote, which cites the book
(and usually the page) for each one. Nothing is typed from memory, and a few
famous lines that Wikiquote doesn't have are deliberately left out.

The collection is built by `tools/build_quotes.py` from the picks in
`tools/picks.json`, against the Wikiquote revisions pinned in
`tools/revisions.json`:

```sh
tools/build_quotes.py            # rebuild from the pinned revisions
tools/build_quotes.py --update   # use the latest revisions (fails loudly if a pick no longer matches)
```

To add a quote, add `{"book": "…", "starts": "<its first words>"}` to
`tools/picks.json` and rebuild. Add `"speaker": "Death"` for DEATH's own lines so
he delivers them. See the script's docstring for excerpts and the
other options.

## Tests

```sh
python3 tests/test_pratchett.py    # the command: colour, widths, DEATH, locale, flags
python3 tests/test_completion.py   # tab completion, driven through a real zsh
```

Both run in a pseudo-terminal. The width checks render every quote at widths from
12 to 200 columns. CI runs both on macOS and Linux for every push, and a weekly job
checks that every quote still matches Wikiquote.

## License

The code is MIT licensed (see [LICENSE](LICENSE)). The quotes collection in
`quotes/` comes from Wikiquote and is shared under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); see
[quotes/NOTICE.md](quotes/NOTICE.md). The quotes themselves are, of course,
Terry Pratchett's.

GNU Terry Pratchett.
