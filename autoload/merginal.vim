"Use vimproc if available under windows to prevent opening a console window
function! merginal#system(command,...)
    if has('win32') && exists(':VimProcBang') "We don't need vimproc when we use linux
        if empty(a:000)
            return vimproc#system(a:command)
        else
            return vimproc#system(a:command,a:000[0])
        endif
    else
        if empty(a:000)
            return system(a:command)
        else
            return system(a:command,a:000[0])
        endif
    endif
endfunction

function! merginal#bang(command)
    if exists(':terminal')
        redraw "Release 'Press ENTER or type command to continue'
        let l:oldWinView = winsaveview()
        botright new
        call winrestview(l:oldWinView)
        resize 5
        call termopen(a:command)
        autocmd BufWinLeave <buffer> execute winnr('#').'wincmd w'
        normal! A
    else
        execute '!'.a:command
    endif
endfunction

"Opens a file that belongs to a repo in a window that already belongs to that
"repo. Creates a new window if can't find suitable window.
function! merginal#openFileDecidedWindow(repo,fileName)
    "We have to check with bufexists, because bufnr also match prefixes of the
    "file name
    let l:fileBuffer=-1
    if bufexists(a:fileName)
        let l:fileBuffer=bufnr(a:fileName)
    endif

    "We have to check with bufloaded, because bufwinnr also matches closed
    "windows...
    let l:windowToOpenIn=-1
    if bufloaded(l:fileBuffer)
        let l:windowToOpenIn=bufwinnr(l:fileBuffer)
    endif

    "If we found an open window with the correct file, we jump to it
    if -1<l:windowToOpenIn
        execute l:windowToOpenIn.'wincmd w'
    else
        "Check if the previous window can be used
        let l:previousWindow=winnr('#')
        if s:isWindowADisposableWindowOfRepo(l:previousWindow,a:repo)
            execute winnr('#').'wincmd w'
        else
            "If the previous window can't be used, check if any open
            "window can be used
            let l:windowsToOpenTheFileIn=merginal#getListOfDisposableWindowsOfRepo(a:repo)
            if empty(l:windowsToOpenTheFileIn)
                "If no open window can be used, open a new Vim window
                new
            else
                execute l:windowsToOpenTheFileIn[0].'wincmd w'
            endif
        endif
        if -1<l:fileBuffer
            "If the buffer is already open, jump to it
            execute 'buffer '.l:fileBuffer
        else
            "Otherwise, load it
            execute 'edit '.fnameescape(a:fileName)
        endif
    endif
    diffoff "Just in case...
endfunction

"Check if the current window is modifiable, saved, and belongs to the repo
function! s:isCurrentWindowADisposableWindowOfRepo(repo)
    if !&modifiable
        return 0
    endif
    if &modified
        return 0
    endif
    try
        return a:repo==fugitive#repo()
    catch
        return 0
    endtry
endfunction

"Calls s:isCurrentWindowADisposableWindowOfRepo with a window number
function! s:isWindowADisposableWindowOfRepo(winnr,repo)
    let l:currentWindow=winnr()
    try
        execute a:winnr.'wincmd w'
        return s:isCurrentWindowADisposableWindowOfRepo(a:repo)
    finally
        execute l:currentWindow.'wincmd w'
    endtry
endfunction

"Get a list of windows that yield true with s:isWindowADisposableWindowOfRepo
function! merginal#getListOfDisposableWindowsOfRepo(repo)
    let l:result=[]
    let l:currentWindow=winnr()
    windo if s:isCurrentWindowADisposableWindowOfRepo(a:repo) | call add(l:result,winnr()) |  endif
    execute l:currentWindow.'wincmd w'
    return l:result
endfunction

"Get the repository that belongs to a window
function! s:getRepoOfWindow(winnr)
    "Ignore bad window numbers
    if a:winnr<=0
        return {}
    endif
    let l:currentWindow=winnr()
    try
        execute a:winnr.'wincmd w'
        return fugitive#repo()
    catch
        return {}
    finally
        execute l:currentWindow.'wincmd w'
    endtry
endfunction

"Reload the buffers
function! merginal#reloadBuffers()
    let l:currentWindow=winnr()
    try
        silent windo if ''==&buftype
                    \| edit
                    \| endif
    catch
        "do nothing
    endtry
    execute l:currentWindow.'wincmd w'
endfunction

"Exactly what it says on tin
function! merginal#runGitCommandInTreeReturnResult(repo,command)
    let l:dir=getcwd()
    execute 'cd '.fnameescape(a:repo.tree())
    try
        return merginal#system(a:repo.git_command().' '.a:command)
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction

"Like merginal#runGitCommandInTreeReturnResult but split result to lines
function! merginal#runGitCommandInTreeReturnResultLines(repo,command)
    return split(merginal#runGitCommandInTreeReturnResult(a:repo, a:command),
                \ '\r\n\|\n\|\r')
endfunction

function! s:cleanup_term_codes(s)
    let s = substitute(a:s, '\t', '        ', 'g')
    " Remove terminal escape codes for colors (based on
    " www.commandlinefu.com/commands/view/3584/).
    let s = substitute(s, '\v\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]', '', 'g')
    return s
endfunction

function! merginal#runGitCommandInTreeEcho(repo,command)
    let l:lines = merginal#runGitCommandInTreeReturnResultLines(a:repo, a:command)
    if len(l:lines) == 1
        " Output a single/empty line to make Vim wait for Enter.
        echo ' '
    endif
    for l:line in l:lines
        echo "[output]" s:cleanup_term_codes(l:line)
    endfor
endfunction


"Returns 1 if there was a merginal bufffer to close
function! merginal#closeMerginalBuffer()
    let l:merginalWindowNumber=bufwinnr('Merginal:')
    if 0<=l:merginalWindowNumber
        let l:currentWindow=winnr()
        try
            execute l:merginalWindowNumber.'wincmd w'
            wincmd q
            "If the current window is after the merginal window, closing the
            "merginal window will decrease the current window's nubmer.
            if l:merginalWindowNumber<l:currentWindow
                let l:currentWindow=l:currentWindow-1
            endif
            return 1
        finally
            "If it's the merginal window that we close, there is no window to
            "return to...
            if l:merginalWindowNumber != l:currentWindow
                execute l:currentWindow.'wincmd w'
            endif
        endtry
    end
    return 0
endfunction

"Returns 1 if a new buffer was opened, 0 if it already existed
function! merginal#openTuiBuffer(bufferName,inWindow)
    let l:repo=fugitive#repo()

    let l:tuiBufferWindow=bufwinnr(bufnr(a:bufferName))

    if -1<l:tuiBufferWindow "Jump to the already open buffer
        execute l:tuiBufferWindow.'wincmd w'
    else "Open a new buffer
        if merginal#isMerginalWindow(a:inWindow)
            execute a:inWindow.'wincmd w'
            enew
        else
            40vnew
        endif
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal nomodifiable
        setlocal winfixwidth
        setlocal winfixheight
        setlocal nonumber
        setlocal norelativenumber
        execute 'silent file '.a:bufferName
        call fugitive#detect(l:repo.dir())
    endif

    "At any rate, reassign the active repository
    let b:merginal_repo=l:repo
    let b:headerLinesCount=0

    "Check and return if a new buffer was created
    return -1==l:tuiBufferWindow
endfunction


"Check if a window belongs to Merginal
function! merginal#isMerginalWindow(winnr)
    if a:winnr<=0
        return 0
    endif
    let l:buffer=winbufnr(a:winnr)
    if l:buffer<=0
        return 0
    endif
    "check for the merginal repo buffer variable
    return !empty(getbufvar(l:buffer,'merginal_repo'))
endfunction


"For the branch in the specified line, retrieve:
" - type: 'local', 'remote' or 'detached'
" - isCurrent, isLocal, isRemote, isDetached
" - remote: the name of the remote or '' for local branches
" - name: the name of the branch, without the remote
" - handle: the named used for referring the branch in git commands
function! merginal#branchDetails(lineNumber)
    if !exists('b:merginal_repo')
        throw 'Unable to get branch details outside the merginal window'
    endif
    if line(a:lineNumber)<=b:headerLinesCount
        throw 'Unable to get branch details for the header of the merginal window'
    endif
    let l:line=getline(a:lineNumber)
    let l:result={}


    "Check if this branch is the currently selected one
    let l:result.isCurrent=('*'==l:line[0])
    let l:line=l:line[2:]

    let l:detachedMatch=matchlist(l:line,'\v^\(detached from ([^/]+)%(/(.*))?\)$')
    if !empty(l:detachedMatch)
        let l:result.type='detached'
        let l:result.isLocal=0
        let l:result.isRemote=0
        let l:result.isDetached=1
        let l:result.remote=l:detachedMatch[1]
        let l:result.name=l:detachedMatch[2]
        if empty(l:detachedMatch[2])
            let l:result.handle=l:detachedMatch[1]
        else
            let l:result.handle=l:detachedMatch[1].'/'.l:detachedMatch[2]
        endif
        return l:result
    endif

    let l:remoteMatch=matchlist(l:line,'\v^remotes/([^/]+)%(/(\S*))%( \-\> (\S+))?$')
    if !empty(l:remoteMatch)
        let l:result.type='remote'
        let l:result.isLocal=0
        let l:result.isRemote=1
        let l:result.isDetached=0
        let l:result.remote=l:remoteMatch[1]
        let l:result.name=l:remoteMatch[2]
        if empty(l:remoteMatch[2])
            let l:result.handle=l:remoteMatch[1]
        else
            let l:result.handle=l:remoteMatch[1].'/'.l:remoteMatch[2]
        endif
        return l:result
    endif

    let l:result.type='local'
    let l:result.isLocal=1
    let l:result.isRemote=0
    let l:result.isDetached=0
    let l:result.remote=''
    let l:result.name=l:line
    let l:result.handle=l:line

    return l:result
endfunction

"For the file in the specified line, retrieve:
" - name: the name of the file
function! merginal#fileDetails(lineNumber)
    if !exists('b:merginal_repo')
        throw 'Unable to get file details outside the merginal window'
    endif
    if line(a:lineNumber)<=b:headerLinesCount
        throw 'Unable to get branch details for the header of the merginal window'
    endif
    let l:line=getline(a:lineNumber)
    let l:result={}

    let l:result.name=l:line

    return l:result
endfunction

"For the commit in the specified line, retrieve it's hash
function! merginal#commitHash(lineNumber)
    if !exists('b:merginal_repo')
        throw 'Unable to get commit details outside the merginal window'
    endif
    if line(a:lineNumber)<=b:headerLinesCount
        throw 'Unable to get commit details for the header of the merginal window'
    endif
    "echo a:lineNumber
    if type(0) == type(a:lineNumber)
        let l:lineNumber = a:lineNumber
    else
        let l:lineNumber = line(a:lineNumber)
    endif
    while b:headerLinesCount < l:lineNumber && !empty(getline(l:lineNumber))
        let l:lineNumber -= 1
    endwhile
    let l:lineNumber += 1
    return split(getline(l:lineNumber))[0]
endfunction

"For the commit in the specified line, retrieve:
" - fullHash
" - authorName
" - timestamp
" - subject
" - body
function! merginal#commitDetails(lineNumber)
    let l:commitHash = merginal#commitHash(a:lineNumber)
    let l:entryFormat = join(['%H', '%aN', '%aE', '%ai', '%B'], '%x01')
    let l:commitLines = split(
                \ merginal#system(b:merginal_repo.git_command('--no-pager', 'log', '-1', '--format='.l:entryFormat, l:commitHash)),
                \ '\%x01')
    let l:result = {}

    let l:result.fullHash    = l:commitLines[0]
    let l:result.authorName  = l:commitLines[1]
    let l:result.authorEmail = l:commitLines[2]
    let l:result.timestamp   = l:commitLines[3]

    let l:commitMessage = split(l:commitLines[4], '\r\n\|\n\|\r')
    let l:result.subject = l:commitMessage[0]
    let l:result.body    = join(l:commitMessage[2 :], "\n")

    return l:result
endfunction

function! merginal#getLocalBranchNamesThatTrackARemoteBranch(remoteBranchName)
    "Get verbose list of branches
    let l:branchList=split(merginal#system(b:merginal_repo.git_command('branch','-vv')),'\r\n\|\n\|\r')

    "Filter for branches that track our remote
    let l:checkIfTrackingRegex='\V['.escape(a:remoteBranchName,'\').'\[\]:]'
    let l:branchList=filter(l:branchList,'v:val=~l:checkIfTrackingRegex')

    "Extract the branch name from the matching lines
    "let l:extractBranchNameRegex='\v^\*?\s*(\S+)'
    "let l:branchList=map(l:branchList,'matchlist(v:val,l:extractBranchNameRegex)[1]')
    let l:extractBranchNameRegex='\v^\*?\s*\zs\S+'
    let l:branchList=map(l:branchList,'matchstr(v:val,l:extractBranchNameRegex)')

    return l:branchList
endfunction

function! merginal#getRemoteBranchTrackedByLocalBranch(localBranchName)
    let l:result=merginal#system(b:merginal_repo.git_command('branch','--list',a:localBranchName,'-vv'))
    echo l:result
    return matchstr(l:result,'\v\[\zs[^\[\]:]*\ze[\]:]')
endfunction


"Check if the current buffer's repo is in rebase mode
function! merginal#isRebaseMode()
    return isdirectory(fugitive#repo().dir('rebase-apply'))
endfunction

"Check if the current buffer's repo is in rebase amend mode
function! merginal#isRebaseAmendMode()
    return isdirectory(fugitive#repo().dir('rebase-merge'))
endfunction

"Check if the current buffer's repo is in merge mode
function! merginal#isMergeMode()
    "Use glob() to check for file existence
    return !empty(glob(fugitive#repo().dir('MERGE_MODE')))
endfunction

"Check if the current buffer's repo is in cherry-pick mode
function! merginal#isCherryPickMode()
    "Use glob() to check for file existence
    return !empty(glob(fugitive#repo().dir('CHERRY_PICK_HEAD')))
endfunction

"Open the branch list buffer for controlling buffers
function! merginal#openBranchListBuffer(...)
    if merginal#openTuiBuffer('Merginal:Branches',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-branchlist
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshBranchListBuffer(1)
endfunction

"If the current buffer is a branch list buffer - refresh it!
function! merginal#tryRefreshBranchListBuffer(jumpToCurrentBranch)
    if 'Merginal:Branches'==bufname('')
        let l:branchList=split(merginal#system(b:merginal_repo.git_command('branch','--all')),'\r\n\|\n\|\r')
        let l:currentLine=line('.')

        setlocal modifiable
        "Clear the buffer:
        silent normal! gg"_dG
        "Write the branch list:
        call setline(1,l:branchList)
        setlocal nomodifiable

        if a:jumpToCurrentBranch
            "Find the current branch's index
            let l:currentBranchIndex=-1
            for i in range(len(l:branchList))
                if '*'==l:branchList[i][0]
                    let l:currentBranchIndex=i
                    break
                endif
            endfor
            if -1<l:currentBranchIndex
                "Jump to the current branch's line
                execute l:currentBranchIndex+1
            endif
        else
            execute l:currentLine
        endif
    endif
endfunction






"Open the merge conflicts buffer for resolving merge conflicts
function! merginal#openMergeConflictsBuffer(...)
    let l:currentFile=expand('%:~:.')
    if merginal#openTuiBuffer('Merginal:Conflicts',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-conflicts
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshMergeConflictsBuffer(l:currentFile)
endfunction

"Returns 1 if all merges are done
function! s:refreshConflictsBuffer(fileToJumpTo,headerLines)
    "Get the list of unmerged files:
    let l:conflicts=split(merginal#system(b:merginal_repo.git_command('ls-files','--unmerged')),'\r\n\|\n\|\r')
    "Split by tab - the first part is info, the second is the file name
    let l:conflicts=map(l:conflicts,'split(v:val,"\t")')
    "Only take the stage 1 files - stage 2 and 3 are the same files with
    "different hash, and we don't care about the hash here
    let l:conflicts=filter(l:conflicts,'v:val[0] =~ "\\v 1$"')
    "Take the file name - we no longer care about the info
    let l:conflicts=map(l:conflicts,'v:val[1]')
    "If the working copy is not the current dir, we can get wrong paths.
    "We need to resulve that:
    let l:conflicts=map(l:conflicts,'b:merginal_repo.tree(v:val)')
    "Make the paths as short as possible:
    let l:conflicts=map(l:conflicts,'fnamemodify(v:val,":~:.")')


    let l:currentLine=line('.')-b:headerLinesCount

    setlocal modifiable
    "Clear the buffer:
    silent normal! gg"_dG
    "Write the branch list:
    call setline(1,a:headerLines+l:conflicts)
    let b:headerLinesCount=len(a:headerLines)
    let l:currentLine=l:currentLine+b:headerLinesCount
    setlocal nomodifiable
    if empty(l:conflicts)
        return 1
    endif

    if empty(a:fileToJumpTo)
        if 0<l:currentLine
            execute l:currentLine
        endif
    else
        let l:lineNumber=search('\V\^'+escape(a:fileToJumpTo,'\')+'\$','cnw')
        if 0<l:lineNumber
            execute l:lineNumber
        else
            execute l:currentLine
        endif
    endif
    return 0
endfunction

"Returns 1 if all merges are done
function! merginal#tryRefreshMergeConflictsBuffer(fileToJumpTo)
    if 'Merginal:Conflicts'==bufname('')
        return s:refreshConflictsBuffer(a:fileToJumpTo,[])
    endif
    return 0
endfunction

"Open the diff files buffer for diffing agains another branch/commit
function! merginal#openDiffFilesBuffer(diffTarget,...)
    if merginal#openTuiBuffer('Merginal:Diff',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-difffiles
    endif

    let b:merginal_diffTarget=a:diffTarget

    "At any rate, refresh the buffer:
    call merginal#tryRefreshDiffFilesBuffer()
endfunction


"For the diff file in the specified line, retrieve:
" - type: 'added', 'deleted' or 'modified'
" - isAdded, isDeleted, isModified
" - fileInTree: the path of the file relative to the repo
" - fileFullPath: the full path to the file
function! merginal#diffFileDetails(lineNumber)
    if !exists('b:merginal_repo')
        throw 'Unable to get diff file details outside the merginal window'
    endif
    let l:line=getline(a:lineNumber)
    let l:result={}

    let l:matches=matchlist(l:line,'\v([ADM])\t(.*)$')

    if empty(l:matches)
        throw 'Unable to get diff files details for `'.l:line.'`'
    endif

    let l:result.isAdded=0
    let l:result.isDeleted=0
    let l:result.isModified=0
    if 'A'==l:matches[1]
        let l:result.type='added'
        let l:result.isAdded=1
    elseif 'D'==l:matches[1]
        let l:result.type='deleted'
        let l:result.isDeleted=1
    else
        let l:result.type='modified'
        let l:result.isModified=1
    endif

    let l:result.fileInTree=l:matches[2]
    let l:result.fileFullPath=b:merginal_repo.tree(l:matches[2])

    return l:result
endfunction

"If the current buffer is a diff files buffer - refresh it!
function! merginal#tryRefreshDiffFilesBuffer()
    if 'Merginal:Diff'==bufname('')
        let l:diffTarget=b:merginal_diffTarget
        let l:diffFiles=merginal#runGitCommandInTreeReturnResultLines(b:merginal_repo,'diff --name-status '.shellescape(l:diffTarget))
        let l:currentLine=line('.')

        setlocal modifiable
        "Clear the buffer:
        silent normal! gg"_dG
        "Write the diff files list:
        call setline(1,l:diffFiles)
        setlocal nomodifiable

        execute l:currentLine
    endif
endfunction


"Open the rebase conflicts buffer for resolving rebase conflicts
function! merginal#openRebaseConflictsBuffer(...)
    let l:currentFile=expand('%:~:.')
    if merginal#openTuiBuffer('Merginal:Rebase',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-conflicts
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshRebaseConflictsBuffer(l:currentFile)
endfunction

"Returns 1 if all rebase conflicts are done
function! merginal#tryRefreshRebaseConflictsBuffer(fileToJumpTo)
    if 'Merginal:Rebase'==bufname('')
        let l:currentCommitMessageLines=readfile(b:merginal_repo.dir('rebase-apply','msg-clean'))
        call insert(l:currentCommitMessageLines,'=== Reapplying: ===')
        call add(l:currentCommitMessageLines,'===================')
        call add(l:currentCommitMessageLines,'')
        return s:refreshConflictsBuffer(a:fileToJumpTo,l:currentCommitMessageLines)
    endif
    return 0
endfunction

"Open the rebase amend buffer
function! merginal#openRebaseAmendBuffer(...)
    let l:currentFile=expand('%:~:.')
    if merginal#openTuiBuffer('Merginal:RebaseAmend',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-rebaseamend
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshRebaseAmendBuffer()
endfunction

function! merginal#tryRefreshRebaseAmendBuffer()
    if 'Merginal:RebaseAmend'==bufname('')
        let l:currentLine=line('.')
        let l:newBufferLines=[]
        let l:amendedCommit=readfile(b:merginal_repo.dir('rebase-merge','amend'))
        let l:amendedCommitShort=merginal#system(b:merginal_repo.git_command('rev-parse','--short',l:amendedCommit[0]))
        let l:amendedCommitShort=substitute(l:amendedCommitShort,'\v[\r\n]','','g')
        let l:amendedCommitMessage=readfile(b:merginal_repo.dir('rebase-merge','message'))
        call add(l:newBufferLines,'=== Amending '.l:amendedCommitShort.' ===')
        let l:newBufferLines+=l:amendedCommitMessage
        call add(l:newBufferLines,repeat('=',len(l:newBufferLines[0])))
        call add(l:newBufferLines,'')

        let b:headerLinesCount=len(l:newBufferLines)+1

        let l:branchList=split(merginal#system(b:merginal_repo.git_command('branch','--all')),'\r\n\|\n\|\r')
        "The first line is a reminder that we are rebasing
        "call remove(l:branchList,0)
        let l:newBufferLines+=l:branchList


        setlocal modifiable
        "Clear the buffer:
        silent normal! gg"_dG
        "Write the new buffer lines:
        call setline(1,l:newBufferLines)
        "call setline(1,l:branchList)
        setlocal nomodifiable
    endif
    return 0
endfunction





"Open the history log buffer
function! merginal#openHistoryLogBuffer(logBranch,...)
    let l:currentFile=expand('%:~:.')
    if merginal#openTuiBuffer('Merginal:HistoryLog',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-historylog
    endif

    let b:merginal_branch=a:logBranch

    "At any rate, refresh the buffer:
    call merginal#tryRefreshHistoryLogBuffer()
endfunction

function! merginal#tryRefreshHistoryLogBuffer()
    if 'Merginal:HistoryLog'==bufname('')
        let l:entryFormat = '%h %aN%n%ai%n%s%n'
        let l:logLines = split(
                    \ merginal#system(b:merginal_repo.git_command(
                    \                '--no-pager', 'log', '--format='.l:entryFormat, b:merginal_branch.handle)),
                    \ '\r\n\|\n\|\r')
        if empty(l:logLines[len(l:logLines) - 1])
            call remove(l:logLines, len(l:logLines) - 1)
        endif
        let l:currentLine=line('.')

        setlocal modifiable
        "Clear the buffer:
        silent normal! gg"_dG
        "Write the log lines:
        call setline(1,l:logLines)
        setlocal nomodifiable

        execute l:currentLine
    endif
    return 0
endfunction



"Open the cherry-pick conflicts buffer for resolving cherry-pick conflicts
function! merginal#openCherryPickConflictsBuffer(...)
    let l:currentFile = expand('%:~:.')

    if merginal#openTuiBuffer('Merginal:CherryPick',get(a:000,1,bufwinnr('Merginal:')))
        set filetype=merginal-conflicts
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshCherryPickConflictsBuffer(l:currentFile)
endfunction

"Returns 1 if all cherry-pick conflicts are done
function! merginal#tryRefreshCherryPickConflictsBuffer(fileToJumpTo)
    if 'Merginal:CherryPick'==bufname('')
        let l:cherryPickHead = readfile(b:merginal_repo.dir('CHERRY_PICK_HEAD'))[0]
        let l:cherryPickCommitMessageLines = merginal#runGitCommandInTreeReturnResultLines(b:merginal_repo, 'show --no-patch --format=%B '.l:cherryPickHead)
        if empty(l:cherryPickCommitMessageLines[-1])
            call remove(l:cherryPickCommitMessageLines, -1)
        endif
        call insert(l:cherryPickCommitMessageLines, '=== Cherry Picking: ===')
        call add(l:cherryPickCommitMessageLines,    '=======================')
        call add(l:cherryPickCommitMessageLines, '')
        return s:refreshConflictsBuffer(a:fileToJumpTo, l:cherryPickCommitMessageLines)
    endif
    return 0
endfunction
