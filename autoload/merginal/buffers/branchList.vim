call merginal#modulelib#makeModule(s:, 'branchList', 'immutableBranchList')



function! s:f.checkoutBranch() dict abort
    let l:branch = self.branchDetails('.')
    call self.gitEcho('checkout', l:branch.handle, '--')
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
    call self.gitEcho('checkout', '-b', l:newBranchName, '--track', l:branch.handle, '--')
    if !v:shell_error
        call merginal#reloadBuffers()
    endif
    call self.refresh()
    call self.jumpToCurrentItem()
endfunction
call s:f.addCommand('trackBranch', [0], 'MerginalTrack', 'ct', 'Track the remote branch under the cursor')
call s:f.addCommand('trackBranch', [1], 'MerginalTrackPrompt', 'cT', 'Track the remote branch under the cursor, prompting for a name')

function! s:f.promptToCreateNewBranch() dict abort
    let l:newBranchName = input('Branch `'.FugitiveHead(b:merginal.fugitiveContext).'` to: ')
    if empty(l:newBranchName)
        echo ' '
        echom 'Branch creation canceled by user.'
        return
    endif
    call self.gitEcho('checkout', '-b', l:newBranchName, '--')
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
            call self.gitEcho('branch', '-D', l:branch.handle, '--')
        else
            call self.gitBang('push', l:branch.remote, '--delete', l:branch.name, '--')
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
    let l:gitArgs = ['merge', '--no-commit'] 
    call extend(l:gitArgs, a:000)
    call extend(l:gitArgs, [l:branch.handle, '--'])
    call call(self.gitEcho, l:gitArgs, self)
    let l:confilctsBuffer = self.gotoSpecialModeBuffer()
    if empty(l:confilctsBuffer)
        call self.refresh()
    else
        if empty(l:confilctsBuffer.body)
            "If we are in merge mode without actual conflicts, this means
            "there are not conflicts and the user can be prompted to enter a
            "merge message.
            Gstatus
            call merginal#closeMerginalBuffer()
        endif
    endif
    call merginal#reloadBuffers()
endfunction
call s:f.addCommand('mergeBranchUnderCursor', [], 'MerginalMerge', ['mm', 'M'], 'Merge the branch under the cursor')
call s:f.addCommand('mergeBranchUnderCursor', ['--no-ff'], 'MerginalMergeNoFF', ['mn'], 'Merge the branch under the cursor using --no-ff')

function! s:f.mergeBranchUnderCursorUsingFugitive() dict abort
    let l:branch = self.branchDetails('.')
    execute ':Git merge '.l:branch.handle
endfunction
call s:f.addCommand('mergeBranchUnderCursorUsingFugitive', [], 'MerginalMergeUsingFugitive', ['mf'], 'Merge the branch under the cursor using fugitive')

function! s:f.rebaseBranchUnderCursor() dict abort
    let l:branch = self.branchDetails('.')
    call self.gitEcho('rebase', l:branch.handle, '--')
    call merginal#reloadBuffers()
    call self.gotoSpecialModeBuffer()
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
            if l:chosenRemoteIndex < 0
                echom ' '
                echom string(l:chosenRemoteIndex)
                echom ' '
                echom string(l:remotes)
                echom ' '
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
                if l:chosenLocalIndex < 0
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

    call add(l:gitCommandWithArgs, '--')

    call call(self.gitBang, l:gitCommandWithArgs, self)
    "if l:reloadBuffers
        "call merginal#reloadBuffers()
    "endif
    "call self.refresh()
endfunction
call s:f.addCommand('remoteActionForBranchUnderCursor', ['push'], 'MerginalPush', ['ps'], 'Prompt to choose a remote to push the branch under the cursor.')
call s:f.addCommand('remoteActionForBranchUnderCursor', ['push', '--force-with-lease'], 'MerginalPushForce', ['pS'], 'Prompt to choose a remote to force (with lease) push the branch under the cursor.')
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

    call self.gitEcho('branch', '-m', l:branch.name, l:newName, '--')
    call self.refresh()
endfunction
call s:f.addCommand('renameBranchUnderCursor', [], 'MerginalRenameBranch', 'rn', 'Prompt to rename the branch under the cursor.')

