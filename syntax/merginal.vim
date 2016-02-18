if exists("b:current_syntax")
    finish
endif

syntax match marginalCurrent '^\*.*$'
highlight link marginalCurrent Statement

syntax match merginalRemote '->'
highlight link merginalRemote Operator

syntax match merginalTarget '\(-> \)\@<=.*'
highlight link merginalTarget Type

syntax keyword merginalKeyword HEAD master origin
highlight link merginalKeyword Keyword

" syntax match merginalremote '-> \@<=[a-z0-9/]\+$'
" highlight link marginalcurrent Special


let b:current_syntax = "merginalhelpfile"

