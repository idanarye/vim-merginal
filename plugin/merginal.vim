function! s:openBasedOnMergeMode() abort
    if merginal#isRebaseMode()
        call merginal#openRebaseConflictsBuffer()
    elseif merginal#isMergeMode()
        call merginal#openMergeConflictsBuffer()
    else
        call merginal#openBranchListBuffer()
    endif
endfunction

autocmd User Fugitive command! -buffer -nargs=0 Merginal call s:openBasedOnMergeMode()
