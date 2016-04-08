call merginal#modulelib#makeModule(s:, 'branchList', 'base')

function! s:f.generateBody() dict abort
    return self.gitLines('branch', '--all')
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
    let l:result = self.gitLines('branch','--list',a:localBranchName,'-vv')
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





function! s:f.checkoutBranch() dict abort
    let l:branch = self.branchDetails('.')
    call self.gitEcho('checkout', l:branch.handle)
    call self.refresh()
    call self.jumpToCurrentItem()
    call merginal#reloadBuffers()
endfunction
call s:f.addCommand('checkoutBranch', [], 'MerginalCheckout', ['cc', 'C'], 'Checkout the branch under the cursor')


function! s:f.trackBranch(promptForName) dict abort
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

function! s:f.promptToCreateNewBranch() dict abort
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

function! s:f.deleteBranchUnderCursor() dict abort
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

function! s:f.mergeBranchUnderCursor(...) dict abort
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

function! s:f.mergeBranchUnderCursorUsingFugitive() dict abort
    let l:branch = self.branchDetails('.')
    execute ':Gmerge '.l:branchName.handle
endfunction
call s:f.addCommand('mergeBranchUnderCursorUsingFugitive', [], 'MerginalMerge', ['mf'], 'Merge the branch under the cursor using fugitive')

function! s:f.rebaseBranchUnderCursor() dict abort
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

function! s:f.remoteActionForBranchUnderCursor(action, ...) dict abort
    let l:branch = self.branchDetails('.')
    if l:branch.isLocal
        let l:remotes = self.gitLines('remote')
        if empty(l:remotes)
            throw 'Can not '.a:action.' - no remotes defined'
        endif

        let l:chosenRemoteIndex=0
        if 1 < len(l:remotes)
            ""Choose the correct text accoring to the action:
            let l:prompt = 'Choose remote to '.a:action.' `'.l:branch.handle.'`'
            if 'push' == a:action
                let l:prompt .= ' to:'
            else
                let l:prompt .= ' from:'
            endif
            let l:chosenRemoteIndex = merginal#util#inputList(l:prompt, l:remotes, 'MORE')
            "Check that the chosen index is in range
            if l:chosenRemoteIndex <= 0 || len(l:remotes) < l:chosenRemoteIndex
                return
            endif
        endif

        let l:localBranchName = l:branch.name
        let l:chosenRemote = l:remotes[l:chosenRemoteIndex]

        let l:remoteBranchNameCanadidate = self.getRemoteBranchTrackedByLocalBranch(l:branch.name)
        if !empty(l:remoteBranchNameCanadidate)
            "Check that this is the same remote:
            if l:remoteBranchNameCanadidate =~ '\V\^'.escape(l:chosenRemote, '\').'/'
                "Remove the remote repository name
                let l:remoteBranchName = l:remoteBranchNameCanadidate[len(l:chosenRemote) + 1:(-1)]
            endif
        endif
    elseif l:branch.isRemote
        let l:chosenRemote = l:branch.remote
        if 'push' == a:action
            "For push, we want to specify the remote branch name
            let l:remoteBranchName = l:branch.name

            let l:locals = self.getLocalBranchNamesThatTrackARemoteBranch(l:branch.handle)

            if empty(l:locals)
                let l:localBranchName = l:branch.name
            elseif 1 == len(l:locals)
                let l:localBranchName = l:locals[0]
            else
                let l:chosenLocalIndex = merginal#util#inputList('Choose local branch to push `'.l:branch.handle.'` from:', l:locals, 'MORE')

                "Check that the chosen index is in range
                if l:chosenLocalIndex <= 0 || len(l:locals) < l:chosenLocalIndex
                    return
                endif

                let l:localBranchName = l:locals[l:chosenLocalIndex]
            endif
        else
            "For pull and fetch, git automatically resolves the tracking
            "branch based on the remote branch.
            let l:localBranchName = l:branch.name
        endif
    endif

    if exists('l:remoteBranchName') && empty(l:remoteBranchName)
        unlet l:remoteBranchName
    endif

    let l:gitCommandWithArgs = [a:action]
    for l:flag in a:000
        call add(l:gitCommandWithArgs, l:flag)
    endfor

    let l:reloadBuffers = 0

    "Pulling requires the --no-commit flag
    if 'pull' == a:action
        if exists('l:remoteBranchName')
            let l:remoteBranchNameAsPrefix = l:remoteBranchName
        else
            let l:remoteBranchNameAsPrefix = ''
        endif
        let l:remoteBranchEscapedName = l:remoteBranchNameAsPrefix.l:localBranchName
        call add(l:gitCommandWithArgs, '--no-commit')
        let l:reloadBuffers = 1

    elseif 'push' == a:action
        if exists('l:remoteBranchName')
            let l:remoteBranchNameAsSuffix = ':'.l:remoteBranchName
        else
            let l:remoteBranchNameAsSuffix = ''
        endif
        let l:remoteBranchEscapedName = l:localBranchName.l:remoteBranchNameAsSuffix

    elseif 'fetch' == a:action
        if exists('l:remoteBranchName')
            let l:targetBranchName = l:remoteBranchName
        else
            let l:targetBranchName = l:localBranchName
        endif
        let l:remoteBranchEscapedName = l:targetBranchName
    endif

    call add(l:gitCommandWithArgs, l:chosenRemote)
    call add(l:gitCommandWithArgs, l:remoteBranchEscapedName)

    call call(self.gitBang, l:gitCommandWithArgs, self)
    "if l:reloadBuffers
        "call merginal#reloadBuffers()
    "endif
    "call self.refresh()
endfunction
call s:f.addCommand('remoteActionForBranchUnderCursor', ['push'], 'MerginalPush', ['ps'], 'Prompt to choose a remote to push the branch under the cursor.')
call s:f.addCommand('remoteActionForBranchUnderCursor', ['push', '--force'], 'MerginalPushForce', ['pS'], 'Prompt to choose a remote to force push the branch under the cursor.')
call s:f.addCommand('remoteActionForBranchUnderCursor', ['pull'], 'MerginalPull', ['pl'], 'Prompt to choose a remote to pull the branch under the cursor.')
call s:f.addCommand('remoteActionForBranchUnderCursor', ['pull', '--rebase'], 'MerginalPullRebase', ['pr'], 'Prompt to choose a remote to pull-rebase the branch under the cursor.')
call s:f.addCommand('remoteActionForBranchUnderCursor', ['fetch'], 'MerginalFetch', ['pf'], 'Prompt to choose a remote to fetch the branch under the cursor.')

function! s:f.renameBranchUnderCursor() dict abort
    let l:branch = self.branchDetails('.')
    if !l:branch.isLocal
        throw 'Can not rename - not a local branch'
    endif
    let l:newName = input('Rename `'.l:branch.handle.'` to: ', l:branch.name)
    echo ' '
    if empty(l:newName)
        echom 'Branch rename canceled by user.'
        return
    elseif l:newName==l:branch.name
        echom 'Branch name was not modified.'
        return
    endif

    call self.gitEcho('branch', '-m', l:branch.name, l:newName)
    call self.refresh()
endfunction
call s:f.addCommand('renameBranchUnderCursor', [], 'MerginalRenameBranch', 'rn', 'Prompt to rename the branch under the cursor.')

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

