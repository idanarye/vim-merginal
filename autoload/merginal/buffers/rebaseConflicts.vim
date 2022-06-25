call merginal#modulelib#makeModule(s:, 'rebaseConflicts', 'conflictsBase')

function! s:f.generateHeader() dict abort
        let l:currentCommit = readfile(self.fugitiveContext.git_dir . '/ORIG_HEAD')[0]
        let l:currentCommitMessageLines = self.gitLines('log', '--format=%s', '-n1', l:currentCommit, '--')
        call insert(l:currentCommitMessageLines, '=== Reapplying: ===')
        call add(l:currentCommitMessageLines,    '===================')
        call add(l:currentCommitMessageLines, '')
        return l:currentCommitMessageLines
endfunction

function! s:f.lastFileAdded() dict abort
    echo 'Added the last file of this patch.'
    echo 'Continue to the next patch (y/N)?'
    let l:answer = getchar()
    if char2nr('y') == l:answer || char2nr('Y') == l:answer
        call self.rebaseAction('continue')
    endif
endfunction


function! s:f.rebaseAction(action) dict abort
    call self.gitEcho('rebase', '--'.a:action)
    call merginal#reloadBuffers()
    let l:mode = self._getSpecialMode()
    if l:mode == self.name
        call self.refresh()
    elseif empty(l:mode)
        "If we finished rebasing - close the rebase conflicts buffer
        wincmd q
    else
        call self.gotoBuffer(l:mode)
    endif
endfunction
call s:f.addCommand('rebaseAction', ['abort'], 'MerginalAbort', 'ra', 'Abort the rebase.')
call s:f.addCommand('rebaseAction', ['skip'], 'MerginalSkip', 'rs', 'Skip the current patch')
call s:f.addCommand('rebaseAction', ['continue'], 'MerginalContinue', 'rc', 'Continue to the next patch.')
