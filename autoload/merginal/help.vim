
let s:help_list = [
            \  "CHECKOUT cc|C"                 ,
            \  "  ct=tracked  cT=track+prompt" ,
            \  "MERGE mm|M"                    ,
            \  "  mf=Gmerge mn=with -no-ff"    ,
            \ "DELETE dd|d    NEW aa|A"        ,
            \  "PULL pl"                       ,
            \  "  pr=pull+rebase pf=fetch"     ,
            \  "PUSH ps"                       ,
            \  "  pS=force"                    ,
            \  "RENAME rn"                     ,
            \ "HISTORY gl     DIFF gd"         ,
            \ ]

function! merginal#help#print()
    "echo "this is a stub"
    pedit __Merginal_Help__
    let merginal_window = winnr()
    wincmd w
    setlocal buftype=nofile
    setlocal filetype=merginalhelp
    setlocal nonumber
    call append(0, s:help_list)
    call cursor(1, 1)
    execute merginal_window . "wincmd w"
    setlocal nomodifiable
endfunction
