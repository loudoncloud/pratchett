# pratchett — random Terry Pratchett quotes for your terminal
# https://github.com/loudoncloud/pratchett
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -g PRATCHETT_DIR="${0:A:h}"
typeset -g PRATCHETT_VERSION="1.0.0"
typeset -ga _pratchett_quotes

# Load the quotes once: entries are separated by lines containing only "%"
_pratchett_load() {
  (( $#_pratchett_quotes )) && return
  local content
  content=$(<"$PRATCHETT_DIR/quotes/pratchett") || return 1
  _pratchett_quotes=("${(@ps:\n%\n:)content}")
  _pratchett_quotes=(${_pratchett_quotes:#})
}

# Word-wrap $2 to width $1 (multibyte-aware); result in $reply
_pratchett_wrap() {
  local w=$1 line= word
  reply=()
  for word in ${=2}; do
    if [[ -z $line ]]; then line=$word
    elif (( ${(m)#line} + 1 + ${(m)#word} <= w )); then line+=" $word"
    else reply+=("$line"); line=$word
    fi
  done
  [[ -n $line ]] && reply+=("$line")
}

# Bold Death's SMALL CAPS words, italicise the rest
_pratchett_style() {
  local word out=
  for word in ${=1}; do
    if [[ $word == *[A-Z][A-Z]* && $word != *[a-z]* ]]; then
      out+=$'\e[1m'"$word"$'\e[22;3m '
    else
      out+="$word "
    fi
  done
  print -rn -- "${out% }"
}

typeset -ga _pratchett_rainbow_colors=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 21 57 93 129 165 201 199 198 197)

# Paint $1 one character at a time, starting the gradient at offset $2
_pratchett_rainbow() {
  local s=$1 out= c
  integer k=$2 n=$#_pratchett_rainbow_colors
  for c in ${(s::)s}; do
    out+=$'\e[38;5;'${_pratchett_rainbow_colors[(k / 2) % n + 1]}m$c
    (( k++ ))
  done
  print -rn -- "$out"
}

pratchett() {
  emulate -L zsh
  setopt extendedglob
  local opt short= death= plain= rainbow= OPTIND
  while getopts ":sdprvh" opt; do
    case $opt in
      s) short=1 ;;
      d) death=1 ;;
      p) plain=1 ;;
      r) rainbow=1 ;;
      v) print -r -- "pratchett $PRATCHETT_VERSION"; return ;;
      *) print -r -- "usage: pratchett [-s] [-d] [-p] [-r] [-v] [search words...]
  -s  short quotes only      -d  Death says it
  -p  plain, no frame        -r  rainbow
  -v  print version
  search words pick a random quote containing them (case-insensitive)"
         [[ $opt == h ]]; return ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if ! _pratchett_load; then
    print -u2 -r -- "pratchett: quotes file not found in $PRATCHETT_DIR/quotes"
    return 1
  fi

  local -a pool=("${_pratchett_quotes[@]}")
  (( short )) && pool=(${pool:#?(#c161,)})
  local note=
  if (( $# )); then
    pool=(${(M)pool:#(#i)*${(b)*}*})
    if (( ! $#pool )); then
      print -r -- "No quote mentions “$*”. Ook."
      return 1
    fi
    (( $#pool > 1 )) && note="(1 of $#pool matches)"
  fi
  local raw=${pool[RANDOM % $#pool + 1]}

  # Split into quote body and "— Book" attribution
  local -a lines=("${(@f)raw}")
  local source=${${lines[-1]}##[[:space:]]#}
  local body=${(j: :)${(@)lines[1,-2]}}
  body=${${body##[[:space:]]#}%%[[:space:]]#}

  local cols=${COLUMNS:-0}
  (( cols > 0 )) || cols=$(tput cols 2>/dev/null || print 80)
  local w=$(( cols - 8 ))
  (( w > 66 )) && w=66
  (( w < 20 )) && w=20
  _pratchett_wrap $w "$body"
  local -a text=("${reply[@]}")
  # Shrink the frame to fit short quotes
  local longest=${(m)#source} t
  for t in "${text[@]}"; do (( ${(m)#t} > longest )) && longest=${(m)#t}; done
  (( longest < w )) && w=$longest

  local reset=$'\e[0m' dim=$'\e[2m' ital=$'\e[3m'
  local -a palette=(173 109 139 108 179 67 175 144)
  local accent=$'\e[38;5;'${palette[RANDOM % $#palette + 1]}m

  # Death speaks for himself (in capitals), or when asked
  if [[ -z $plain && ( -n $death || $body =~ '[A-Z]{2,}[ ,.?!]+[A-Z]{2,}[ ,.?!]+[A-Z]{2,}' ) ]] \
      && (( $+commands[cowsay] )); then
    local art l
    integer i=0
    _pratchett_wrap 40 "$body"
    art=$(print -rl -- "${reply[@]}" | cowsay -f "$PRATCHETT_DIR/death.cow" -n)
    if [[ -n $rainbow ]]; then
      for l in "${(@f)art}"; do
        print -r -- "$(_pratchett_rainbow "$l" $(( i++ * 3 )))$reset"
      done
    else
      print -r -- "$accent$art$reset"
    fi
    print -r -- "${(l:46:)source} ${dim}${note}${reset}"
    return
  fi

  local line styled pad
  local -a out=()
  integer i
  for (( i = 1; i <= $#text; i++ )); do
    line=${text[i]}
    pad=$(( w - ${(m)#line} ))
    if [[ -n $rainbow ]]; then
      styled=$ital$(_pratchett_rainbow "$line" $(( (i - 1) * 4 )))$reset
    else
      styled=$ital$(_pratchett_style "$line")$reset
    fi
    out+=("$styled${(l:pad:)}")
  done
  local srcline="${(l:w - ${(m)#source}:)}${dim}${source}${reset}"

  if [[ -n $plain ]]; then
    print
    print -rl -- "  "${^out}
    print
    print -r -- "  $srcline"
    [[ -n $note ]] && print -r -- "  ${dim}${note}${reset}"
    print
    return
  fi

  local bar=${(pl:w + 4::─:)}
  print -r -- "$accent╭$bar╮$reset"
  print -r -- "$accent│$reset${(l:w+4:)}$accent│$reset"
  for line in "${out[@]}"; do
    print -r -- "$accent│$reset  $line  $accent│$reset"
  done
  print -r -- "$accent│$reset${(l:w+4:)}$accent│$reset"
  print -r -- "$accent│$reset  $srcline  $accent│$reset"
  print -r -- "$accent╰$bar╯$reset"
  [[ -n $note ]] && print -r -- "${(l:w + 6 - ${#note}:)}${dim}${note}${reset}"
}

# Short alias; set PRATCHETT_NO_ALIAS=1 before loading the plugin to skip it
if [[ -z $PRATCHETT_NO_ALIAS ]]; then
  alias tp=pratchett
fi
