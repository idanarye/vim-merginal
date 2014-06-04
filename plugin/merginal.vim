function! s:openBasedOnMergeMode() abort
    if merginal#isMergeMode()
        call merginal#openMergeConflictsBuffer()
    else
        call merginal#openBranchListBuffer()
    endif
endfunction

command! -nargs=0 Merginal call s:openBasedOnMergeMode()
