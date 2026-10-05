# pratchett — random Terry Pratchett quotes for your terminal
# https://github.com/loudoncloud/pratchett
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -g PRATCHETT_DIR="${0:A:h}"
typeset -g PRATCHETT_VERSION="1.8.0"
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

# The book of a quote entry: its last line is "— Book" or "— Speaker, Book"
_pratchett_book() {
  REPLY=${${${1##*$'\n'}##[[:space:]]#}#— }
  [[ $REPLY == *", "* ]] && REPLY=${REPLY#*, }
}

# All books in collection order, in $reply; counts in $_pratchett_book_counts
typeset -gA _pratchett_book_counts
_pratchett_books() {
  local q
  reply=()
  _pratchett_book_counts=()
  for q in "${_pratchett_quotes[@]}"; do
    _pratchett_book "$q"
    (( _pratchett_book_counts[$REPLY]++ )) || reply+=("$REPLY")
  done
}

# Days since 1970-01-01 for a Y M D date, in $REPLY (Howard Hinnant's days_from_civil)
_pratchett_days() {
  integer y=$1 m=$2 d=$3 era yoe doy doe
  (( y -= m <= 2 ))
  (( era = (y >= 0 ? y : y - 399) / 400 ))
  (( yoe = y - era * 400 ))
  (( doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1 ))
  (( doe = yoe * 365 + yoe / 4 - yoe / 100 + doy ))
  REPLY=$(( era * 146097 + doe - 719468 ))
}

_pratchett_usage() {
  print -r -- "usage: pratchett [-s] [-t] [-d] [-p] [-r] [-n] [-b BOOK] [search words...]
       pratchett --books | -v | -h
  -s  short quotes only      -d  DEATH says it
  -p  plain, no frame        -r  rainbow
  -n  no colour (also: --no-color, NO_COLOR=1, or output that isn't a terminal)
  -t  quote of the day: the same quote all day (combines with -b, -s and search)
  -b  quotes from one book; part of the title is enough (-b jingo, -b \"wee free\")
  --books  list the books, with how many quotes each has
  -v  print version
  search words pick a random quote containing them (case-insensitive)"
}

pratchett() {
  emulate -L zsh
  setopt extendedglob typesetsilent
  # Widths and the frame need a UTF-8 locale; borrow one if the shell has none
  local _loc
  if (( ${#${:-─}} != 1 )); then
    for _loc in C.UTF-8 en_US.UTF-8; do
      local LC_ALL=$_loc
      (( ${#${:-─}} == 1 )) && break
    done
  fi
  local opt short= today= death= plain= rainbow= nocolor= book= listbooks= OPTIND
  # Long options, matched as whole words and only before "--"
  local -a args=()
  local a
  integer ended=0
  for a in "$@"; do
    if (( ! ended )); then
      case $a in
        --) ended=1 ;;
        --no-color|--no-colour) a=-n ;;
        --help) a=-h ;;
        --version) a=-v ;;
        --books) a=-L ;;
        --book) a=-b ;;
        --book=*) args+=(-b); a=${a#--book=} ;;
      esac
    fi
    args+=("$a")
  done
  set -- "${args[@]}"
  while getopts ":stdprnvhLb:" opt; do
    case $opt in
      t) today=1 ;;
      b) book=${${OPTARG##[[:space:]]#}%%[[:space:]]#} ;;
      L) listbooks=1 ;;
      :) print -u2 -r -- "pratchett: -$OPTARG needs a book title, e.g. -b \"Night Watch\" (see --books)"
         return 1 ;;
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

  if [[ -n $listbooks ]]; then
    _pratchett_books
    local b dim= reset=
    [[ -z $nocolor && -z $NO_COLOR && -t 1 ]] && dim=$'\e[2m' reset=$'\e[0m'
    for b in "${reply[@]}"; do
      print -r -- "$dim${(l:3:)_pratchett_book_counts[$b]}$reset  $b"
    done
    return
  fi

  local -a pool=("${_pratchett_quotes[@]}")
  local note= scope=
  if [[ -n $book ]]; then
    # An exact title (any case) wins; otherwise the one title containing it
    _pratchett_books
    local -a hits=(${(M)reply:#(#i)$book})
    (( $#hits )) || hits=(${(M)reply:#(#i)*$book*})
    if (( $#hits == 0 )); then
      print -u2 -r -- "pratchett: no book matches “$book” (see --books)"
      return 1
    elif (( $#hits > 1 )); then
      print -u2 -r -- "pratchett: “$book” matches ${#hits} books: ${(j:, :)hits}"
      return 1
    fi
    local q
    local -a inbook=()
    for q in "${pool[@]}"; do
      _pratchett_book "$q"
      [[ $REPLY == $hits[1] ]] && inbook+=("$q")
    done
    pool=("${inbook[@]}")
    scope=" from ${hits[1]}"
  fi
  (( short )) && pool=(${pool:#?(#c161,)})
  if (( $# )); then
    pool=(${(M)pool:#(#i)*$**})
  fi
  if (( ! $#pool )); then
    if (( $# )); then
      print -r -- "No quote${scope} mentions “$*”. Ook."
    else
      print -r -- "No short quotes${scope}. Ook."
    fi
    return 1
  fi
  if (( $#pool > 1 )); then
    if (( $# )); then
      note="(1 of $#pool matches$scope)"
    elif [[ -n $scope ]]; then
      note="(1 of $#pool quotes$scope)"
    fi
  fi
  if [[ -n $today ]]; then
    # Quote of the day: step through the pool a fixed stride per day, so every
    # quote comes round before any repeats.
    # PRATCHETT_TODAY=YYYY-MM-DD overrides the date (used by the tests).
    local date=$PRATCHETT_TODAY
    if [[ $date != <1900-9999>-<1-12>-<1-31> ]]; then
      zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS
      strftime -s date '%Y-%m-%d' $EPOCHSECONDS
    fi
    _pratchett_days ${(s:-:)date}
    # The step must share no factor with the pool size, or some quotes never come up
    integer step=73 gcd_x gcd_y gcd_r
    while :; do
      (( gcd_x = step, gcd_y = $#pool ))
      while (( gcd_y )); do (( gcd_r = gcd_x % gcd_y, gcd_x = gcd_y, gcd_y = gcd_r )); done
      (( gcd_x == 1 )) && break
      (( step++ ))
    done
    local raw=${pool[(REPLY * step) % $#pool + 1]}
    note="(quote of the day${scope:+$scope})"
  fi

  # No repeats: skip quotes shown recently (up to 50, or half of what's on offer),
  # unless that would leave nothing. PRATCHETT_NO_HISTORY=1 turns this off.
  local histfile=${PRATCHETT_HISTORY_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/pratchett/history}
  local -a recent=()
  [[ -z $PRATCHETT_NO_HISTORY && -r $histfile ]] && recent=("${(@f)$(<$histfile)}")
  integer window=$(( today ? 0 : $#pool / 2 ))
  (( window > 50 )) && window=50
  (( window > $#recent )) && window=$#recent
  if (( window > 0 )); then
    local -A seen=()
    local key entry
    for key in "${(@)recent[$#recent - window + 1, -1]}"; do seen[$key]=1; done
    local -a fresh=()
    for entry in "${pool[@]}"; do
      (( ${+seen[${${entry%%$'\n'*}[1,60]}]} )) || fresh+=("$entry")
    done
    (( $#fresh )) && pool=("${fresh[@]}")
  fi
  [[ -z $today ]] && local raw=${pool[RANDOM % $#pool + 1]}
  if [[ -z $PRATCHETT_NO_HISTORY && -z $today ]]; then
    # Remember it (keeping the last 100); never fail over this
    {
      mkdir -p "${histfile:h}" &&
        print -rl -- "${(@)recent[$(( $#recent > 99 ? $#recent - 98 : 1 )), -1]}" "${${raw%%$'\n'*}[1,60]}" > "$histfile"
    } 2>/dev/null
  fi

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
