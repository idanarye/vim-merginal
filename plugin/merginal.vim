
function! s:impl_GMbranch(arg)
    if empty(a:arg) "Show branch list
        call merginal#openBranchListBuffer()
    endif
endfunction

command! -nargs=? GMbranch call s:impl_GMbranch(<q-args>)
