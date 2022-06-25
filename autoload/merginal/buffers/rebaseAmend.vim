call merginal#modulelib#makeModule(s:, 'rebaseAmend', 'immutableBranchList')

function! s:f.generateHeader() dict abort
    let l:amendedCommit = readfile(self.fugitiveContext.git_dir . '/rebase-merge/amend')
    let l:amendedCommitShort = self.gitRun('rev-parse', '--short', l:amendedCommit[0], '--')
    let l:amendedCommitShort = substitute(l:amendedCommitShort,'\v[\r\n]','','g')
    let l:header = ['=== Amending '.l:amendedCommitShort.' ===']

    let l:amendedCommitMessage = readfile(self.fugitiveContext.git_dir . '/rebase-merge/message')
    let l:header += l:amendedCommitMessage

    call add(l:header,repeat('=', len(l:header[0])))
    call add(l:header, '')

    return l:header
endfunction


function! s:f.rebaseAction(action) dict abort
    call self.gitEcho('rebase', '--'.a:action)
    call merginal#reloadBuffers()
    let l:mode = self._getSpecialMode()
    if l:mode == self.name
        call self.refresh()
    elseif empty(l:mode)
        "If we finished rebasing - close the rebase amend buffer
        wincmd q
    else
        call self.gotoBuffer(l:mode)
    endif
endfunction
call s:f.addCommand('rebaseAction', ['abort'], 'MerginalAbort', 'ra', 'Abort the rebase.')
call s:f.addCommand('rebaseAction', ['skip'], 'MerginalSkip', 'rs', 'Skip the current patch')
call s:f.addCommand('rebaseAction', ['continue'], 'MerginalContinue', 'rc', 'Continue to the next patch.')
