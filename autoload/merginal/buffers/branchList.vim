
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

function! s:f.checkoutBranch() dict
    let l:branch = self.branchDetails('.')
    call self.gitEcho('checkout', l:branch.handle)
    call self.refresh()
    call self.jumpToCurrentItem()
    call merginal#reloadBuffers()
endfunction
call s:f.addCommand('checkoutBranch', [], 'MerginalCheckout', ['cc', 'C'], 'Checkout the branch under the cursor')


function! s:f.trackBranch(promptForName) dict
    let l:branch = self.branchDetails('.')
    if !l:branch.isRemote
        throw 'Can not track - branch is not remote'
    endif
    let l:newBranchName = l:branch.name
    if a:promptForName
        let l:newBranchName = input('Track `'.l:branch.handle.'` as: ', l:newBranchName)
        if empty(l:newBranchName)
            echo ' '
            echom 'Branch tracking canceled by user.'
            return
        endif
    endif
    call self.gitEcho('checkout', '-b', l:newBranchName, '--track', l:branch.handle)
    if !v:shell_error
        call merginal#reloadBuffers()
    endif
    call self.refresh()
    call self.jumpToCurrentItem()
endfunction
call s:f.addCommand('trackBranch', [0], 'MerginalTrack', 'ct', 'Track the remote branch under the cursor')
call s:f.addCommand('trackBranch', [1], 'MerginalTrackPrompt', 'cT', 'Track the remote branch under the cursor, prompting for a name')

function! s:f.promptToCreateNewBranch() dict
    let l:newBranchName = input('Branch `'.self.repo.head().'` to: ')
    if empty(l:newBranchName)
        echo ' '
        echom 'Branch creation canceled by user.'
        return
    endif
    call self.gitEcho('checkout', '-b', l:newBranchName)
    call merginal#reloadBuffers()

    call self.refresh()
    call self.jumpToCurrentItem()
endfunction
call s:f.addCommand('promptToCreateNewBranch', [], 'MerginalNewBranch', ['aa', 'A'], 'Create a new branch')

function! s:f.deleteBranchUnderCursor() dict
    let l:branch = self.branchDetails('.')
    let l:answer = 0
    if l:branch.isLocal
        let l:answer = 'yes' == input('Delete branch `'.l:branch.handle.'`? (type "yes" to confirm) ')
    elseif l:branch.isRemote
        "Deleting remote branches needs a special warning
        let l:answer = 'yes-remote' == input('Delete remote(!) branch `'.l:branch.handle.'`? (type "yes-remote" to confirm) ')
    endif
    if l:answer
        if l:branch.isLocal
            call self.gitEcho('branch', '-D', l:branch.handle)
        else
            call self.gitBang('push', l:branch.remote, '--delete', l:branch.name)
        endif
        call self.refresh()
    else
        echo ' '
        echom 'Branch deletion canceled by user.'
    endif
endfunction
call s:f.addCommand('deleteBranchUnderCursor', [], 'MerginalDelete', ['dd', 'D'], 'Delete the branch under the cursor')

function! s:f.mergeBranchUnderCursor(...) dict
    let l:branch = self.branchDetails('.')
    let l:gitArgs = ['merge', '--no-commit', l:branch.handle]
    call extend(l:gitArgs, a:000)
    call call(self.gitEcho, l:gitArgs, self)
    if merginal#isMergeMode()
        throw 'Not yet implemented'
        "call merginal#reloadBuffers()
        "if v:shell_error
            "call merginal#openMergeConflictsBuffer(winnr())
        "else
            ""If we are in merge mode without a shell error, that means there
            ""are not conflicts and the user can be prompted to enter a merge
            ""message.
            "Gstatus
            "call merginal#closeMerginalBuffer()
        "endif
    else
        if !v:shell_error
            call merginal#reloadBuffers()
        end
    endif
endfunction
call s:f.addCommand('mergeBranchUnderCursor', [], 'MerginalMerge', ['mm', 'M'], 'Merge the branch under the cursor')
call s:f.addCommand('mergeBranchUnderCursor', ['--no-ff'], 'MerginalMergeNoFF', ['mn'], 'Merge the branch under the cursor using --no-ff')

function! s:f.mergeBranchUnderCursorUsingFugitive() dict
    let l:branch = self.branchDetails('.')
    execute ':Gmerge '.l:branchName.handle
endfunction
call s:f.addCommand('mergeBranchUnderCursorUsingFugitive', [], 'MerginalMerge', ['mf'], 'Merge the branch under the cursor using fugitive')

function! s:f.rebaseBranchUnderCursor() dict
    let l:branch = self.branchDetails('.')
    call self.gitEcho('rebase', l:branch.handle)
    if v:shell_error
        if merginal#isRebaseMode()
            throw 'Not yet implemented'
            "call merginal#reloadBuffers()
            "call merginal#openRebaseConflictsBuffer(winnr())
        endif
    else
        call merginal#reloadBuffers()
    endif
endfunction
call s:f.addCommand('rebaseBranchUnderCursor', [], 'MerginalRebase', 'rb', 'Rebase the branch under the cursor')

"ps :call <SID>remoteActionForBranchUnderCursor('push',[])<Cr>
"pS :call <SID>remoteActionForBranchUnderCursor('push',['--force'])<Cr>
"pl :call <SID>remoteActionForBranchUnderCursor('pull',[])<Cr>
"pr :call <SID>remoteActionForBranchUnderCursor('pull',['--rebase'])<Cr>
"pf :call <SID>remoteActionForBranchUnderCursor('fetch',[])<Cr>
"gd :call <SID>diffWithBranchUnderCursor()<Cr>
"rn :call <SID>renameBranchUnderCursor()<Cr>
"gl :call <SID>historyLogForBranchUnderCursor()<Cr>
