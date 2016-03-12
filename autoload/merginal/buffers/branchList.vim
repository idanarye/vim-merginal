
call merginal#modulelib#makeModule(s:, 'branchList', 'base')

function! s:f.generateBody()
    return self.gitLines('branch', '--all')
endfunction

function! s:f.branchDetails(lineNumber) dict
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

function! s:f.jumpToCurrentItem() dict
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

function! s:f.checkoutBranchUnderCursor() dict
    let l:branch = self.branchDetails('.')
    call self.gitEcho('--no-pager', 'checkout', l:branch.handle)
    call self.refresh()
    call self.jumpToCurrentItem()
endfunction
call s:f.setCommand('checkoutBranchUnderCursor', 'MerginalCheckout', ['cc', 'C'], 'Checkout the branch under the cursor')
