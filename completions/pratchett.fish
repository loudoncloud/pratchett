# Fish completion for pratchett: options, and book titles for -b/--book and
# search words. Book titles come from `pratchett --books`.

function __pratchett_books
    command pratchett --books 2>/dev/null | string replace -r '^ *[0-9]+ +' ''
end

# True until --help, --version or --books has been given
function __pratchett_more
    not __fish_seen_argument -s h -l help -s v -l version -l books
end

complete -c pratchett -f
complete -c pratchett -n __pratchett_more -s s -d 'Short quotes only'
complete -c pratchett -n __pratchett_more -s t -d 'Quote of the day'
complete -c pratchett -n __pratchett_more -s d -d 'DEATH says it'
complete -c pratchett -n __pratchett_more -s p -d 'Plain, no frame'
complete -c pratchett -n __pratchett_more -s r -d 'Rainbow'
complete -c pratchett -n __pratchett_more -s n -l no-color -d 'No colour'
complete -c pratchett -n __pratchett_more -s b -l book -x -a '(__pratchett_books)' -d 'Quotes from one book'
complete -c pratchett -n __pratchett_more -l books -d 'List the books'
complete -c pratchett -n __pratchett_more -s h -l help -d 'Show usage'
complete -c pratchett -n __pratchett_more -s v -l version -d 'Print version'
# Search words: offer book titles, since a search matches them too
complete -c pratchett -n __pratchett_more -a '(__pratchett_books)' -d 'Book'
