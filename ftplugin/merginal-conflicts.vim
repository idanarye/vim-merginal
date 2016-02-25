
"Exactly what it says on tin
function! s:openMergeConflictUnderCursor()
    let l:file=merginal#fileDetails('.')
    if empty(l:file.name)
        return
    endif
    call merginal#openFileDecidedWindow(b:merginal_repo,l:file.name)
endfunction

"If that was the last merge conflict, automatically opens Fugitive's status
"buffer
function! s:addConflictedFileToStagingArea()
    let l:file=merginal#fileDetails('.')
    if empty(l:file.name)
        return
    endif
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager add '.shellescape(fnamemodify(l:file.name,':p')))

    if 'Merginal:Conflicts' == bufname('')
        if merginal#tryRefreshMergeConflictsBuffer(0)
            "If this returns 1, that means this is the last file, and we
            "should open gufitive's status window
            let l:mergeConflictsBuffer=bufnr('')
            Gstatus
            let l:gitStatusBuffer=bufnr('')
            execute bufwinnr(l:mergeConflictsBuffer).'wincmd w'
            wincmd q
            execute bufwinnr(l:gitStatusBuffer).'wincmd w'
        endif
    elseif 'Merginal:Rebase' == bufname('')
        if merginal#tryRefreshRebaseConflictsBuffer(0)
            echo 'Added the last file of this patch.'
            echo 'Continue to the next patch (y/N)?'
            let l:answer=getchar()
            if char2nr('y')==l:answer || char2nr('Y')==l:answer
                call s:rebaseAction('continue')
            endif
        endif
    elseif 'Merginal:CherryPick' == bufname('')
        if merginal#tryRefreshCherryPickConflictsBuffer(0)
            "If this returns 1, that means this is the last file, and we
            "should open gufitive's status window
            let l:cherryPickConflictsBuffer=bufnr('')
            Gstatus
            let l:gitStatusBuffer=bufnr('')
            execute bufwinnr(l:cherryPickConflictsBuffer).'wincmd w'
            wincmd q
            execute bufwinnr(l:gitStatusBuffer).'wincmd w'
        endif
    endif
endfunction

"Run various rebase actions
function! s:rebaseAction(remoteAction)
    if 'Merginal:Rebase'==bufname('')
                \|| 'Merginal:RebaseAmend'==bufname('')
        call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager rebase --'.a:remoteAction)
        call merginal#reloadBuffers()
        if merginal#isRebaseMode()
            call merginal#tryRefreshRebaseConflictsBuffer(0)
        elseif merginal#isRebaseAmendMode()
            call merginal#tryRefreshRebaseAmendBuffer()
        else
            "If we finished rebasing - close the rebase conflicts buffer
            wincmd q
        endif
    endif
endfunction

"Run various cherry-pick actions
function! s:cherryPickAction(remoteAction)
    if 'Merginal:CherryPick'==bufname('')
        call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager cherry-pick --'.a:remoteAction)
        call merginal#reloadBuffers()
        if merginal#isCherryPickMode()
            call merginal#tryRefreshCherryPickConflictsBuffer(0)
        else
            "If we finished cherry-picking - close the cherry-pick conflicts buffer
            wincmd q
        endif
    endif
endfunction

nnoremap <buffer> q <C-w>q
nnoremap <buffer> <Cr> :call <SID>openMergeConflictUnderCursor()<Cr>
nnoremap <buffer> A :call <SID>addConflictedFileToStagingArea()<Cr>
nnoremap <buffer> aa :call <SID>addConflictedFileToStagingArea()<Cr>

if 'Merginal:Conflicts' == bufname('')
    nnoremap <buffer> R :call merginal#tryRefreshMergeConflictsBuffer(0)<Cr>
elseif 'Merginal:Rebase' == bufname('')
    nnoremap <buffer> R :call merginal#tryRefreshRebaseConflictsBuffer(0)<Cr>
    nnoremap <buffer> ra :call <SID>rebaseAction('abort')<Cr>
    nnoremap <buffer> rs :call <SID>rebaseAction('skip')<Cr>
    nnoremap <buffer> rc :call <SID>rebaseAction('continue')<Cr>
elseif 'Merginal:CherryPick' == bufname('')
    noremap <buffer> R :call merginal#tryRefreshCherryPickConflictsBuffer(0)<Cr>
    nnoremap <buffer> ca :call <SID>cherryPickAction('abort')<Cr>
    nnoremap <buffer> cc :call <SID>cherryPickAction('continue')<Cr>
endif
