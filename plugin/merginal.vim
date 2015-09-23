function! s:openBasedOnMergeMode() abort
    if merginal#isRebaseMode()
        call merginal#openRebaseConflictsBuffer()
    elseif merginal#isRebaseAmendMode()
        call merginal#openRebaseAmendBuffer()
    elseif merginal#isMergeMode()
        call merginal#openMergeConflictsBuffer()
    elseif merginal#isCherryPickMode()
        call merginal#openCherryPickConflictsBuffer()
    else
        call merginal#openBranchListBuffer()
    endif
endfunction

function! s:toggleBasedOnMergeMode() abort
    let l:repo=fugitive#repo()
    let l:merginalWindowNumber=bufwinnr('Merginal:')
    if 0<=l:merginalWindowNumber
        let l:merginalBufferNumber=winbufnr(l:merginalWindowNumber)
        let l:merginalBufferName=bufname(l:merginalBufferNumber)

        "If we are not on the same dir we need to reload the merginal buffer
        "anyways:
        if getbufvar(l:merginalBufferNumber,'merginal_repo').dir()==l:repo.dir()
            if merginal#isRebaseMode()
                if 'Merginal:Rebase'==l:merginalBufferName
                    call merginal#closeMerginalBuffer()
                    return
                endif
            elseif merginal#isRebaseAmendMode()
                if 'Merginal:RebaseAmend'==l:merginalBufferName
                    call merginal#closeMerginalBuffer()
                    return
                endif
            elseif merginal#isMergeMode()
                if 'Merginal:Conflicts'==l:merginalBufferName
                    call merginal#closeMerginalBuffer()
                    return
                endif
            else
                if 'Merginal:Branches'==l:merginalBufferName
                    call merginal#closeMerginalBuffer()
                    return
                endif
            end
        endif
    endif
    call s:openBasedOnMergeMode()
endfunction

autocmd User Fugitive command! -buffer -nargs=0 Merginal call s:openBasedOnMergeMode()
autocmd User Fugitive command! -buffer -nargs=0 MerginalToggle call s:toggleBasedOnMergeMode()
autocmd User Fugitive command! -buffer -nargs=0 MerginalClose call merginal#closeMerginalBuffer()
