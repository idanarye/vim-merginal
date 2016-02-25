

"Exactly what it says on tin
function! s:printCommitUnderCurosr(format)
    let l:commitHash = merginal#commitHash('.')
    "Not using merginal#runGitCommandInTreeEcho because we are insterested
    "in the result as more than just git command output. Also - using
    "git-log with -1 instead of git-show because for some reason git-show
    "ignores the --format flag...
    echo merginal#system(b:merginal_repo.git_command('--no-pager', 'log', '-1', '--format='.a:format, l:commitHash))
endfunction

"Exactly what it says on tin
function! s:checkoutCommitUnderCurosr()
    let l:commitHash = merginal#commitHash('.')
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager checkout '.shellescape(l:commitHash))
    call merginal#reloadBuffers()
    call merginal#tryRefreshBranchListBuffer(0)
endfunction

"Opens the diff files buffer
function! s:diffWithCommitUnderCursor()
    let l:commitHash = merginal#commitHash('.')
    call merginal#openDiffFilesBuffer(l:commitHash)
endfunction

"Exactly what it says on tin
function! s:cherryPickCommitUnderCursor()
    let l:commitHash = merginal#commitHash('.')
    let l:gitCommand = 'cherry-pick '.shellescape(l:commitHash)
    call merginal#runGitCommandInTreeEcho(b:merginal_repo, l:gitCommand)
    if v:shell_error
        if merginal#isCherryPickMode()
            call merginal#reloadBuffers()
            call merginal#openCherryPickConflictsBuffer(winnr())
        endif
    else
        call merginal#reloadBuffers()
    endif
endfunction

function! s:moveToNextOrPreviousCommit(direction)
    let l:line = line('.')

    "Find the first line of the current commit
    while !empty(getline(l:line - 1))
        let l:line -= 1
    endwhile

    "Find the first line of the next/prev commit
    let l:line += a:direction
    while !empty(getline(l:line - 1))
        let l:line += a:direction
    endwhile

    if l:line <= 0 || line('$') <= l:line
        "We reached past the first/last commit - go back!
        let l:line -= a:direction
        while !empty(getline(l:line - 1))
            let l:line -= a:direction
        endwhile
    endif
    execute l:line
endfunction


nnoremap <buffer> q <C-w>q
nnoremap <buffer> R :call merginal#tryRefreshHistoryLogBuffer()<Cr>
nnoremap <buffer> <C-p> :call <SID>moveToNextOrPreviousCommit(-1)<Cr>
nnoremap <buffer> <C-n> :call <SID>moveToNextOrPreviousCommit(1)<Cr>
nnoremap <buffer> S :call <SID>printCommitUnderCurosr('fuller')<Cr>
nnoremap <buffer> ss :call <SID>printCommitUnderCurosr('fuller')<Cr>
nnoremap <buffer> C :call <SID>checkoutCommitUnderCurosr()<Cr>
nnoremap <buffer> cc :call <SID>checkoutCommitUnderCurosr()<Cr>
nnoremap <buffer> gd :call <SID>diffWithCommitUnderCursor()<Cr>
nnoremap <buffer> cp :call <SID>cherryPickCommitUnderCursor()<Cr>
