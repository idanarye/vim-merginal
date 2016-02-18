if exists("b:current_syntax")
    finish
endif

syntax match marginalhelpkeyword '[A-Z][A-Z][A-Z]\+'
highlight link marginalhelpkeyword keyword

" syntax match marginalhelpcombo '/\v[A-Z] \zs[a-z]+'
syntax match marginalhelpcombo '[a-zA-Z]\+|\@='
syntax match marginalhelpcombo '|\@<=[a-zA-Z]\+'
syntax match marginalhelpcombo '[a-zA-Z]\+=\@='
syntax match marginalhelpcombo '\<[a-z][a-z]\>'
highlight link marginalhelpcombo Special
" highlight link marginalhelp2combo Special

let b:current_syntax = "merginalhelpfile"

