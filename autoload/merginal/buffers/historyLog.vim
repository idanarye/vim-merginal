call merginal#modulelib#makeModule(s:, 'historyLog', 'base')

function! s:f.init(branch) dict abort
    let self.branch = a:branch
endfunction

function! s:f.generateHeader() dict abort
    return [
                \ '=== Showing History For: ===',
                \ self.branch,
                \ '============================',
                \ '']
endfunction

function! s:f.generateBody() dict abort
    let l:logLines = self.gitLines('log', '--max-count', get(g:, 'merginal_logCommitCount', -1), '--format=%h %aN%n%ci%n%s%n', self.branch)
    if empty(l:logLines[len(l:logLines) - 1])
        call remove(l:logLines, len(l:logLines) - 1)
    endif
    return l:logLines
endfunction

function! s:f.getFilteredBody() dict abort
    if empty(self.filter)
        return copy(self.body)
    endif
    let l:result = []
    let l:lastBunch = []
    for l:line in self.body
        if empty(l:line)
            if 0 <= match(l:lastBunch, self.filter)
                call extend(l:result, l:lastBunch)
            endif
            let l:lastBunch = []
        endif
        call add(l:lastBunch, l:line)
    endfor
    if 0 <= match(l:lastBunch, self.filter)
        call extend(l:result, l:lastBunch)
    endif
    if !empty(l:result) && l:result[0] == ''
        call remove(l:result, 0)
    endif
    return l:result
endfunction

function! s:f.commitHash(lineNumber) dict abort
    call self.verifyLineInBody(a:lineNumber)
    if type(0) == type(a:lineNumber)
        let l:lineNumber = a:lineNumber
    else
        let l:lineNumber = line(a:lineNumber)
    endif
    while self.isLineInBody(l:lineNumber) && !empty(getline(l:lineNumber))
        let l:lineNumber -= 1
    endwhile
    let l:lineNumber += 1
    return split(getline(l:lineNumber))[0]
endfunction


function! s:f.moveToNextOrPreviousCommit(direction) dict abort
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
    if self.isLineInBody(l:line)
        execute l:line
    endif
endfunction
call s:f.addCommand('moveToNextOrPreviousCommit', [-1], '', '<C-p>', 'Move the cursor to the previous commit.')
call s:f.addCommand('moveToNextOrPreviousCommit', [1], '', '<C-n>', 'Move the cursor to the next commit.')

function! s:f.printCommitUnderCurosr(format) dict abort
    let l:commitHash = self.commitHash('.')
    "Not using self.gitEcho() because we are insterested in the result as more
    "than just git command output. Also - using git-log with -1 instead of
    "git-show because for some reason git-show ignores the --format flag...
    echo join(self.gitLines('log', '-1', '--format='.a:format, l:commitHash, '--'), "\n")
endfunction
call s:f.addCommand('printCommitUnderCurosr', ['fuller'], 'MerginalShow', ['ss', 'S'], "Echo the commit details(using git's --format=fuller)")

function! s:f.checkoutCommitUnderCurosr() dict abort
    let l:commitHash = self.commitHash('.')
    call self.gitEcho('checkout', l:commitHash, '--')
    call merginal#reloadBuffers()
endfunction
call s:f.addCommand('checkoutCommitUnderCurosr', [], 'MerginalCheckout', ['cc', 'C'], 'Checkout the commit under the cursor.')

function! s:f.diffWithCommitUnderCursor() dict abort
    let l:commitHash = self.commitHash('.')
    call self.gotoBuffer('diffFiles', l:commitHash)
endfunction
call s:f.addCommand('diffWithCommitUnderCursor', [], 'MerginalDiff', 'gd', 'Open diff files buffer to diff against the commit under the cursor.')

function! s:f.cherryPickCommitUnderCursor() dict abort
    let l:commitHash = self.commitHash('.')
    call self.gitEcho('cherry-pick', l:commitHash, '--')
    let l:confilctsBuffer = self.gotoSpecialModeBuffer()
    if empty(l:confilctsBuffer)
        call self.refresh()
    else
        if empty(l:confilctsBuffer.body)
            "If we are in cherry-pick mode without actual conflicts, this
            "means there are not conflicts and the user can be prompted to
            "enter a cherry-pick message.
            Gstatus
            call merginal#closeMerginalBuffer()
        endif
    endif
endfunction
call s:f.addCommand('cherryPickCommitUnderCursor', [], 'MerginalCherryPick', 'cp', 'Cherry-pick the commit under the cursor')
