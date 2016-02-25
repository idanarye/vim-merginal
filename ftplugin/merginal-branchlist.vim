
"Exactly what it says on tin
function! s:checkoutBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager checkout '.shellescape(l:branch.handle))
    if !v:shell_error
        call merginal#reloadBuffers()
    endif
    call merginal#tryRefreshBranchListBuffer(1)
endfunction

"Track what it says on tin
function! s:trackBranchUnderCursor(promptForName)
    let l:branch=merginal#branchDetails('.')
    if !l:branch.isRemote
        throw 'Can not track - branch is not remote'
    endif
    let l:newBranchName=l:branch.name
    if a:promptForName
        let l:newBranchName=input('Track `'.l:branch.handle.'` as: ',l:newBranchName)
        if empty(l:newBranchName)
            echo ' '
            echom 'Branch tracking canceled by user.'
            return
        endif
    endif
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager checkout -b '.shellescape(l:newBranchName).' --track '.shellescape(l:branch.handle))
    if !v:shell_error
        call merginal#reloadBuffers()
    endif
    call merginal#tryRefreshBranchListBuffer(0)
endfunction

"Uses the current branch as the source
function! s:promptToCreateNewBranch()
    let l:newBranchName=input('Branch `'.b:merginal_repo.head().'` to: ')
    if empty(l:newBranchName)
        echo ' '
        echom 'Branch creation canceled by user.'
        return
    endif
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager checkout -b '.shellescape(l:newBranchName))
    call merginal#reloadBuffers()
    call merginal#tryRefreshBranchListBuffer(1)
endfunction

"Verifies the decision
function! s:deleteBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    let l:answer=0
    if l:branch.isLocal
        let l:answer='yes'==input('Delete branch `'.l:branch.handle.'`? (type "yes" to confirm) ')
    elseif l:branch.isRemote
        "Deleting remote branches needs a special warning
        let l:answer='yes-remote'==input('Delete remote(!) branch `'.l:branch.handle.'`? (type "yes-remote" to confirm) ')
    endif
    if l:answer
        if l:branch.isLocal
            call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager branch -D '.shellescape(l:branch.handle))
        else
            call merginal#bang(b:merginal_repo.git_command('push').' '.shellescape(l:branch.remote).' --delete '.shellescape(l:branch.name))
        endif
        call merginal#reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(0)
    else
        echo ' '
        echom 'Branch deletion canceled by user.'
    endif
endfunction

"If there are merge conflicts, opens the merge conflicts buffer
function! s:mergeBranchUnderCursor(flags)
    let l:branch = merginal#branchDetails('.')
    let l:gitCommand = 'merge --no-commit '.shellescape(l:branch.handle)
    for l:flag in a:flags
        let l:gitCommand .= ' '.shellescape(l:flag)
    endfor
    call merginal#runGitCommandInTreeEcho(b:merginal_repo, l:gitCommand)
    if merginal#isMergeMode()
        call merginal#reloadBuffers()
        if v:shell_error
            call merginal#openMergeConflictsBuffer(winnr())
        else
            "If we are in merge mode without a shell error, that means there
            "are not conflicts and the user can be prompted to enter a merge
            "message.
            Gstatus
            call merginal#closeMerginalBuffer()
        endif
    else
        if !v:shell_error
            call merginal#reloadBuffers()
        end
    endif
endfunction

"Use Fugitive's :Gmerge. It was added to Fugitive after I implemented
"Merginal's merge, and I don't want to remove it since it can still more
"comfortable for some.
function! s:mergeBranchUnderCursorUsingFugitive()
    let l:branch=merginal#branchDetails('.')
    execute ':Gmerge '.l:branchName.handle
endfunction

"If there are rebase conflicts, opens the rebase conflicts buffer
function! s:rebaseBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#runGitCommandInTreeEcho(b:merginal_repo,'rebase '.shellescape(l:branch.handle))
    if v:shell_error
        if merginal#isRebaseMode()
            call merginal#reloadBuffers()
            call merginal#openRebaseConflictsBuffer(winnr())
        endif
    else
        call merginal#reloadBuffers()
    endif
endfunction

"Run various remote actions
function! s:remoteActionForBranchUnderCursor(remoteAction,flags)
    let l:branch=merginal#branchDetails('.')
    if l:branch.isLocal
        let l:remotes=merginal#runGitCommandInTreeReturnResultLines(b:merginal_repo,'remote')
        if empty(l:remotes)
            throw 'Can not '.a:remoteAction.' - no remotes defined'
        endif

        let l:chosenRemoteIndex=0
        if 1<len(l:remotes)
            let l:listForInputlist=map(copy(l:remotes),'v:key+1.") ".v:val')
            "Choose the correct text accoring to the action:
            if 'push'==a:remoteAction
                call insert(l:listForInputlist,'Choose remote to '.a:remoteAction.' `'.l:branch.handle.'` to:')
            else
                call insert(l:listForInputlist,'Choose remote to '.a:remoteAction.' `'.l:branch.handle.'` from:')
            endif
            let l:chosenRemoteIndex=inputlist(l:listForInputlist)

            "Check that the chosen index is in range
            if l:chosenRemoteIndex<=0 || len(l:remotes)<l:chosenRemoteIndex
                return
            endif

            let l:chosenRemoteIndex=l:chosenRemoteIndex-1
        endif

        let l:localBranchName=l:branch.name
        let l:chosenRemote=l:remotes[l:chosenRemoteIndex]

        let l:remoteBranchNameCanadidate=merginal#getRemoteBranchTrackedByLocalBranch(l:branch.name)
        echo ' '
        if !empty(l:remoteBranchNameCanadidate)
            "Check that this is the same remote:
            if l:remoteBranchNameCanadidate=~'\V\^'.escape(l:chosenRemote,'\').'/'
                "Remote the remote repository name
                let l:remoteBranchName=l:remoteBranchNameCanadidate[len(l:chosenRemote)+1:(-1)]
            endif
        endif
    elseif l:branch.isRemote
        let l:chosenRemote=l:branch.remote
        if 'push'==a:remoteAction
            "For push, we want to specify the remote branch name
            let l:remoteBranchName=l:branch.name

            let l:locals=merginal#getLocalBranchNamesThatTrackARemoteBranch(l:branch.handle)
            if empty(l:locals)
                let l:localBranchName=l:branch.name
            elseif 1==len(l:locals)
                let l:localBranchName=l:locals[0]
            else
                let l:listForInputlist=map(copy(l:locals),'v:key+1.") ".v:val')
                call insert(l:listForInputlist,'Choose local branch to push `'.l:branch.handle.'` from:')
                let l:chosenLocalIndex=inputlist(l:listForInputlist)

                "Check that the chosen index is in range
                if l:chosenLocalIndex<=0 || len(l:locals)<l:chosenLocalIndex
                    return
                endif

                let l:localBranchName=l:locals[l:chosenLocalIndex-1]
            endif
        else
            "For pull and fetch, git automatically resolves the tracking
            "branch based on the remote branch.
            let l:localBranchName=l:branch.name
        endif
    endif

    if exists('l:remoteBranchName') && empty(l:remoteBranchName)
        unlet l:remoteBranchName
    endif

    let l:gitCommandWithArgs=[a:remoteAction]
    for l:flag in a:flags
        call add(l:gitCommandWithArgs,l:flag)
    endfor

    let l:reloadBuffers=0

    "Pulling requires the --no-commit flag
    if 'pull'==a:remoteAction
        if exists('l:remoteBranchName')
            let l:remoteBranchNameAsPrefix=shellescape(l:remoteBranchName).':'
        else
            let l:remoteBranchNameAsPrefix=''
        endif
        let l:remoteBranchEscapedName=l:remoteBranchNameAsPrefix.shellescape(l:localBranchName)
        call add(l:gitCommandWithArgs,'--no-commit')
        let l:reloadBuffers=1

    elseif 'push'==a:remoteAction
        if exists('l:remoteBranchName')
            let l:remoteBranchNameAsSuffix=':'.shellescape(l:remoteBranchName)
        else
            let l:remoteBranchNameAsSuffix=''
        endif
        let l:remoteBranchEscapedName=shellescape(l:localBranchName).l:remoteBranchNameAsSuffix

    elseif 'fetch'==a:remoteAction
        if exists('l:remoteBranchName')
            let l:targetBranchName=l:remoteBranchName
        else
            let l:targetBranchName=l:localBranchName
        endif
        let l:remoteBranchEscapedName=shellescape(l:targetBranchName)
    endif
    call merginal#bang(call(b:merginal_repo.git_command,l:gitCommandWithArgs,b:merginal_repo).' '.shellescape(l:chosenRemote).' '.l:remoteBranchEscapedName)
    if l:reloadBuffers
        call merginal#reloadBuffers()
    endif
    call merginal#tryRefreshBranchListBuffer(0)
endfunction

"Prompts for a new name to the branch and renames it
function! s:renameBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    if !l:branch.isLocal
        throw 'Can not rename - not a local branch'
    endif
    let l:newName=input('Rename `'.l:branch.handle.'` to: ',l:branch.name)
    echo ' '
    if empty(l:newName)
        echom 'Branch rename canceled by user.'
        return
    elseif l:newName==l:branch.name
        echom 'Branch name was not modified.'
        return
    endif

    let l:gitCommand=b:merginal_repo.git_command('branch','-m',l:branch.name,l:newName)
    let l:result=merginal#system(l:gitCommand)
    echo l:result
    call merginal#tryRefreshBranchListBuffer(0)
endfunction

"Opens the diff files buffer
function! s:diffWithBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#openDiffFilesBuffer(l:branch.handle)
endfunction

"Opens the history log buffer
function! s:historyLogForBranchUnderCursor()
    let l:branch=merginal#branchDetails('.')
    call merginal#openHistoryLogBuffer(l:branch)
endfunction

noremap <buffer> q <C-w>q
noremap <buffer> R :call merginal#tryRefreshBranchListBuffer(0)<Cr>
noremap <buffer> C :call <SID>checkoutBranchUnderCursor()<Cr>
noremap <buffer> cc :call <SID>checkoutBranchUnderCursor()<Cr>
noremap <buffer> ct :call <SID>trackBranchUnderCursor(0)<Cr>
noremap <buffer> cT :call <SID>trackBranchUnderCursor(1)<Cr>
nnoremap <buffer> A :call <SID>promptToCreateNewBranch()<Cr>
nnoremap <buffer> aa :call <SID>promptToCreateNewBranch()<Cr>
nnoremap <buffer> D :call <SID>deleteBranchUnderCursor()<Cr>
nnoremap <buffer> dd :call <SID>deleteBranchUnderCursor()<Cr>
nnoremap <buffer> M :call <SID>mergeBranchUnderCursor([])<Cr>
nnoremap <buffer> mm :call <SID>mergeBranchUnderCursor([])<Cr>
nnoremap <buffer> mf :call <SID>mergeBranchUnderCursorUsingFugitive()<Cr>
nnoremap <buffer> mn :call <SID>mergeBranchUnderCursor(['--no-ff'])<Cr>
nnoremap <buffer> rb :call <SID>rebaseBranchUnderCursor()<Cr>
nnoremap <buffer> ps :call <SID>remoteActionForBranchUnderCursor('push',[])<Cr>
nnoremap <buffer> pS :call <SID>remoteActionForBranchUnderCursor('push',['--force'])<Cr>
nnoremap <buffer> pl :call <SID>remoteActionForBranchUnderCursor('pull',[])<Cr>
nnoremap <buffer> pr :call <SID>remoteActionForBranchUnderCursor('pull',['--rebase'])<Cr>
nnoremap <buffer> pf :call <SID>remoteActionForBranchUnderCursor('fetch',[])<Cr>
nnoremap <buffer> rn :call <SID>renameBranchUnderCursor()<Cr>
nnoremap <buffer> gd :call <SID>diffWithBranchUnderCursor()<Cr>
nnoremap <buffer> gl :call <SID>historyLogForBranchUnderCursor()<Cr>
