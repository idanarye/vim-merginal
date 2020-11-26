call merginal#modulelib#makeModule(s:, 'immutableBranchList', 'base')

function! s:f.generateBody() dict abort
    if self.remoteVisible
        return self.gitLines('branch', '--all')
    else
        return self.gitLines('branch')
    endif
endfunction

function! s:f.branchDetails(lineNumber) dict abort
    call self.verifyLineInBody(a:lineNumber)

    let l:line = getline(a:lineNumber)
    let l:result = {}

    "Check if this branch is the currently selected one
    let l:result.isCurrent = ('*' == l:line[0])
    let l:line = l:line[2:]

    let l:detachedMatch = matchlist(l:line, '\v^\(detached from ([^/]+)%(/(.*))?\)$')
    if !empty(l:detachedMatch)
        let l:result.type = 'detached'
        let l:result.isLocal = 0
        let l:result.isRemote = 0
        let l:result.isDetached = 1
        let l:result.remote = l:detachedMatch[1]
        let l:result.name = l:detachedMatch[2]
        if empty(l:detachedMatch[2])
            let l:result.handle = l:detachedMatch[1]
        else
            let l:result.handle = l:detachedMatch[1].'/'.l:detachedMatch[2]
        endif
        return l:result
    endif

    let l:remoteMatch = matchlist(l:line,'\v^remotes/([^/]+)%(/(\S*))%( \-\> (\S+))?$')
    if !empty(l:remoteMatch)
        let l:result.type = 'remote'
        let l:result.isLocal = 0
        let l:result.isRemote = 1
        let l:result.isDetached = 0
        let l:result.remote = l:remoteMatch[1]
        let l:result.name = l:remoteMatch[2]
        if empty(l:remoteMatch[2])
            let l:result.handle = l:remoteMatch[1]
        else
            let l:result.handle = l:remoteMatch[1].'/'.l:remoteMatch[2]
        endif
        return l:result
    endif

    let l:result.type = 'local'
    let l:result.isLocal = 1
    let l:result.isRemote = 0
    let l:result.isDetached = 0
    let l:result.remote = ''
    let l:result.name = l:line
    let l:result.handle = l:line

    return l:result
endfunction

function! s:f.jumpToCurrentItem() dict abort
    "Find the current branch's index
    let l:currentBranchIndex = -1
    for l:i in range(len(self.body))
        if '*' == self.body[i][0]
            let l:currentBranchIndex = l:i
            break
        endif
    endfor
    if -1 < l:currentBranchIndex
        "Jump to the current branch's line
        call self.jumpToIndexInBody(l:currentBranchIndex)
    endif
endfunction

function! s:f.getRemoteBranchTrackedByLocalBranch(localBranchName) dict abort
    let l:result = self.gitLines('branch', '--list', a:localBranchName, '-vv', '--')
    return matchstr(l:result, '\v\[\zs[^\[\]:]*\ze[\]:]')
endfunction

function! s:f.getLocalBranchNamesThatTrackARemoteBranch(remoteBranchName) dict abort
    "Get verbose list of branches
    let l:branchList = self.gitLines('branch', '-vv')

    "Filter for branches that track our remote
    let l:checkIfTrackingRegex = '\V['.escape(a:remoteBranchName, '\').'\[\]:]'
    let l:branchList = filter(l:branchList, 'v:val =~ l:checkIfTrackingRegex')

    "Extract the branch name from the matching lines
    let l:extractBranchNameRegex = '\v^\*?\s*\zs\S+'
    let l:branchList = map(l:branchList, 'matchstr(v:val, l:extractBranchNameRegex)')

    return l:branchList
endfunction





function! s:f.diffWithBranchUnderCursor() dict abort
    let l:branch = self.branchDetails('.')
    call self.gotoBuffer('diffFiles', l:branch.handle)
endfunction
call s:f.addCommand('diffWithBranchUnderCursor', [], 'MerginalDiff', 'gd', 'Open diff files buffer to diff against the branch under the cursor.')

function! s:f.historyLogForBranchUnderCursor() dict abort
    let l:branch = self.branchDetails('.')
    call self.gotoBuffer('historyLog', l:branch.handle)
endfunction
call s:f.addCommand('historyLogForBranchUnderCursor', [], 'MerginalHistoryLog', 'gl', 'Open history log buffer to view the history of the branch under the cursor.')

