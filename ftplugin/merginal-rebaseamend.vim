
"Run various rebase actions
function! s:rebaseAction(remoteAction)
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
endfunction

"Opens the diff files buffer
function! s:diffWithBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#openDiffFilesBuffer(l:branch.handle)
endfunction

"Opens the history log buffer
function! s:historyLogForBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#openHistoryLogBuffer(l:branch)
endfunction


nnoremap <buffer> q <C-w>q
nnoremap <buffer> R :call merginal#tryRefreshRebaseAmendBuffer()<Cr>
nnoremap <buffer> ra :call <SID>rebaseAction('abort')<Cr>
nnoremap <buffer> rs :call <SID>rebaseAction('skip')<Cr>
nnoremap <buffer> rc :call <SID>rebaseAction('continue')<Cr>
nnoremap <buffer> gd :call <SID>diffWithBranchUnderCursor()<Cr>
nnoremap <buffer> gl :call <SID>historyLogForBranchUnderCursor()<Cr>
