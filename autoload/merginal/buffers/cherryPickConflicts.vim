call merginal#modulelib#makeModule(s:, 'cherryPickConflicts', 'conflictsBase')

function! s:f.generateHeader() dict abort
        let l:currentCommit = readfile(self.fugitiveContext.git_dir . '/ORIG_HEAD')[0]
        let l:currentCommitMessageLines = self.gitLines('log', '--format=%s', '-n1', l:currentCommit, '--')
        call insert(l:currentCommitMessageLines, '=== Reapplying: ===')
        call add(l:currentCommitMessageLines, '===================')
        call add(l:currentCommitMessageLines, '')
        return l:currentCommitMessageLines
endfunction

function! s:f.lastFileAdded() dict abort
    let l:cherryPickConflictsBuffer = bufnr('')
    Gstatus
    let l:gitStatusBuffer = bufnr('')
    execute bufwinnr(l:cherryPickConflictsBuffer).'wincmd w'
    wincmd q
    execute bufwinnr(l:gitStatusBuffer).'wincmd w'
endfunction


function! s:f.cherryPickAction(action) dict abort
    call self.gitEcho('cherry-pick', '--'.a:action)
    call merginal#reloadBuffers()
    if self._getSpecialMode() == self.name
        call self.refresh()
    else
        ""If we finished cherry-picking - close the cherry-pick conflicts buffer
        wincmd q
    endif
endfunction
call s:f.addCommand('cherryPickAction', ['abort'], 'MerginalAbort', 'ca', 'Abort the cherry-pick.')
call s:f.addCommand('cherryPickAction', ['continue'], 'MerginalContinue', 'cc', 'Continue to the next patch.')
