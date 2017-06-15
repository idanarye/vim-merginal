call merginal#modulelib#makeModule(s:, 'mergeConflicts', 'conflictsBase')

function! s:f.lastFileAdded() dict abort
    let l:mergeConflictsBuffer = bufnr('')
    Gstatus
    let l:gitStatusBuffer = bufnr('')
    execute bufwinnr(l:mergeConflictsBuffer).'wincmd w'
    wincmd q
    execute bufwinnr(l:gitStatusBuffer).'wincmd w'
endfunction

function! s:f.mergeAction(action) dict abort
    call self.gitEcho('merge', '--'.a:action)
    call merginal#reloadBuffers()
    let l:mode = self._getSpecialMode()
    if l:mode == self.name
        call self.refresh()
    elseif empty(l:mode)
        "If we finished merging - close the merge conflicts buffer
        wincmd q
    else
        call self.gotoBuffer(l:mode)
    endif
endfunction
call s:f.addCommand('mergeAction', ['abort'], 'MerginalAbort', 'ma', 'Abort the merge.')
call s:f.addCommand('mergeAction', ['continue'], 'MerginalContinue', 'mc', 'Conclude the merge')
