# pratchett — random Terry Pratchett quotes for your terminal
# https://github.com/loudoncloud/pratchett
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -g PRATCHETT_DIR="${0:A:h}"
typeset -g PRATCHETT_VERSION="1.3.0"
typeset -ga _pratchett_quotes

# Load the quotes once: entries are separated by lines containing only "%"
_pratchett_load() {
  (( $#_pratchett_quotes )) && return
  local content
  content=$(<"$PRATCHETT_DIR/quotes/pratchett") || return 1
  _pratchett_quotes=("${(@ps:\n%\n:)content}")
  _pratchett_quotes=(${_pratchett_quotes:#})
}

# Word-wrap $2 to width $1 (multibyte-aware), hard-breaking words longer
# than a line; result in $reply
_pratchett_wrap() {
  local w=$1 line= word
  reply=()
  for word in ${=2}; do
    while (( ${(m)#word} > w )); do
      [[ -n $line ]] && reply+=("$line") && line=
      reply+=("${word[1,w]}")
      word=${word[w+1,-1]}
    done
    if [[ -z $line ]]; then line=$word
    elif (( ${(m)#line} + 1 + ${(m)#word} <= w )); then line+=" $word"
    else reply+=("$line"); line=$word
    fi
  done
  [[ -n $line ]] && reply+=("$line")
}

# Bold DEATH's SMALL CAPS words, italicise the rest
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

_pratchett_usage() {
  print -r -- "usage: pratchett [-s] [-d] [-p] [-r] [-n] [-v] [search words...]
  -s  short quotes only      -d  DEATH says it
  -p  plain, no frame        -r  rainbow
  -n  no colour (also: --no-color, NO_COLOR=1, or output that isn't a terminal)
  -v  print version
  search words pick a random quote containing them (case-insensitive)"
}

pratchett() {
  emulate -L zsh
  setopt extendedglob
  # Widths and the frame need a UTF-8 locale; borrow one if the shell has none
  local _loc
  if (( ${#${:-─}} != 1 )); then
    for _loc in C.UTF-8 en_US.UTF-8; do
      local LC_ALL=$_loc
      (( ${#${:-─}} == 1 )) && break
    done
  fi
  local opt short= death= plain= rainbow= nocolor= OPTIND
  local -a args=("$@")
  args=("${(@)args/#--no-colo(u|)r/-n}")
  args=("${(@)args/#--help/-h}")
  args=("${(@)args/#--version/-v}")
  set -- "${args[@]}"
  while getopts ":sdprnvh" opt; do
    case $opt in
      s) short=1 ;;
      d) death=1 ;;
      p) plain=1 ;;
      r) rainbow=1 ;;
      n) nocolor=1 ;;
      v) print -r -- "pratchett $PRATCHETT_VERSION"; return ;;
      h) _pratchett_usage; return ;;
      *) _pratchett_usage >&2; return 1 ;;
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
    pool=(${(M)pool:#(#i)*$**})
    if (( ! $#pool )); then
      print -r -- "No quote mentions “$*”. Ook."
      return 1
    fi
    (( $#pool > 1 )) && note="(1 of $#pool matches)"
  fi
  local raw=${pool[RANDOM % $#pool + 1]}

  # Split into quote body and "— [Speaker, ]Book" attribution
  local -a lines=("${(@f)raw}")
  local source=${${lines[-1]}##[[:space:]]#}
  local body=${(j: :)${(@)lines[1,-2]}}
  body=${${body##[[:space:]]#}%%[[:space:]]#}

  # Colour only for a terminal, and never when asked not to (https://no-color.org)
  [[ -n $NO_COLOR || ! -t 1 ]] && nocolor=1
  local reset= dim= ital= accent=
  if [[ -z $nocolor ]]; then
    local -a palette=(173 109 139 108 179 67 175 144)
    reset=$'\e[0m' dim=$'\e[2m' ital=$'\e[3m'
    accent=$'\e[38;5;'${palette[RANDOM % $#palette + 1]}m
  else
    rainbow=
  fi

  local cols=${COLUMNS:-0}
  (( cols > 0 )) || cols=$(tput cols 2>/dev/null || print 80)
  (( cols > 0 )) || cols=80
  # A frame needs room; on narrow terminals print plain text instead
  (( cols < 30 )) && plain=1

  # DEATH delivers his own lines (and any line with -d), given room and cowsay
  if [[ -z $plain && ( -n $death || $source == "— Death,"* ) ]] \
      && (( cols >= 48 && $+commands[cowsay] )); then
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
    # Attribution right-aligned under the drawing, wrapped if it's long
    _pratchett_wrap 46 "$source"
    for l in "${reply[@]}"; do
      print -r -- "${(l:46 - ${(m)#l}:)}$l"
    done
    [[ -n $note ]] && print -r -- "${(l:46 - ${#note}:)}$dim$note$reset"
    return
  fi

  # Text width: inside a frame (2 border + 4 padding) or indented by 2 when plain
  local w=$(( cols - (plain ? 4 : 8) ))
  (( w > 66 )) && w=66
  (( w < 10 )) && w=10
  _pratchett_wrap $w "$body"
  local -a text=("${reply[@]}")
  _pratchett_wrap $w "$source"
  local -a srctext=("${reply[@]}")
  # Shrink to fit short quotes
  local longest=0 t
  for t in "${text[@]}" "${srctext[@]}"; do (( ${(m)#t} > longest )) && longest=${(m)#t}; done
  (( longest < w )) && w=$longest

  local line styled
  local -a out=() srcout=()
  integer i
  for (( i = 1; i <= $#text; i++ )); do
    line=${text[i]}
    if [[ -n $rainbow ]]; then
      styled=$ital$(_pratchett_rainbow "$line" $(( (i - 1) * 4 )))$reset
    elif [[ -n $nocolor ]]; then
      styled=$line
    else
      styled=$ital$(_pratchett_style "$line")$reset
    fi
    out+=("$styled${(l:w - ${(m)#line}:)}")
  done
  # Right-align the attribution
  for line in "${srctext[@]}"; do
    srcout+=("${(l:w - ${(m)#line}:)}$dim$line$reset")
  done

  if [[ -n $plain ]]; then
    print
    print -rl -- "  "${^out}
    print
    print -rl -- "  "${^srcout}
    [[ -n $note ]] && print -r -- "  $dim$note$reset"
    print
    return
  fi

  local bar=${(pl:w + 4::─:)} blank="$accent│$reset${(l:w + 4:)}$accent│$reset"
  print -r -- "$accent╭$bar╮$reset"
  print -r -- "$blank"
  for line in "${out[@]}"; do
    print -r -- "$accent│$reset  $line  $accent│$reset"
  done
  print -r -- "$blank"
  for line in "${srcout[@]}"; do
    print -r -- "$accent│$reset  $line  $accent│$reset"
  done
  print -r -- "$accent╰$bar╯$reset"
  [[ -n $note ]] && print -r -- "${(l:w + 6 - ${#note}:)}$dim$note$reset"
}

# Tab completion: make _pratchett findable, and register it now if compinit
# has already run (oh-my-zsh and most plugin managers load plugins before it)
if [[ -r $PRATCHETT_DIR/_pratchett ]]; then
  fpath=("$PRATCHETT_DIR" ${fpath:#$PRATCHETT_DIR})
fi
if [[ -r $PRATCHETT_DIR/_pratchett ]] && (( $+functions[compdef] )); then
  autoload -Uz _pratchett
  compdef _pratchett pratchett
fi

# Short alias; set PRATCHETT_NO_ALIAS=1 before loading the plugin to skip it
if [[ -z $PRATCHETT_NO_ALIAS ]]; then
  alias tp=pratchett
fi
