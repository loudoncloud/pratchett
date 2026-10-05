# Bash completion for pratchett: options, and book titles for -b/--book and
# search words. Works with bash 3.2 (macOS's /bin/bash) and newer; doesn't
# need the bash-completion package. Book titles come from `pratchett --books`.

_pratchett_books() {
  command pratchett --books 2>/dev/null | sed 's/^ *[0-9]* *//'
}

# Add the titles starting with $1 to COMPREPLY, escaped for the command line
_pratchett_add_books() {
  local book
  while IFS= read -r book; do
    [[ $book == "$1"* ]] && COMPREPLY+=("$(printf '%q' "$book")")
  done < <(_pratchett_books)
}

_pratchett() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  COMPREPLY=()

  # What's typed so far, without the backslashes or quotes the shell needs
  local word=${cur//\\/}
  word=${word#[\"\']}

  # Nothing to complete after --help, --version or --books
  local w
  for w in "${COMP_WORDS[@]:1:COMP_CWORD-1}"; do
    case $w in -h|--help|-v|--version|--books) return ;; esac
  done

  # A book title after -b / --book, or after "--book=". Bash 4+ splits that into
  # "--book" "=" "Thie"; bash 3.2 keeps "--book=Thie" as one word. Either way
  # readline replaces only the part after "=", so reply with titles alone.
  if [[ $prev == -b || $prev == --book ]] ||
     [[ $prev == = && ${COMP_WORDS[COMP_CWORD-2]} == --book ]]; then
    _pratchett_add_books "$word"
    return
  fi
  if [[ $word == --book=* ]]; then
    _pratchett_add_books "${word#--book=}"
    return
  fi

  if [[ $cur == -* ]]; then
    COMPREPLY=($(compgen -W "-s -t -d -p -r -n -b -h -v --book --books --no-color --help --version" -- "$cur"))
    return
  fi

  # Search words: offer book titles, since a search matches them too
  _pratchett_add_books "$word"
}

complete -F _pratchett pratchett
