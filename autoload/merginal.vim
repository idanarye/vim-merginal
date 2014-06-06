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

"Returns 1 if a new buffer was opened, 0 if it already existed
function! merginal#openTuiBuffer(bufferName,inWindow)
    let l:repo=fugitive#repo()

    let l:tuiBufferWindow=bufwinnr(bufnr(a:bufferName))

    if -1<l:tuiBufferWindow "Jump to the already open buffer
        execute l:tuiBufferWindow.'wincmd w'
    else "Open a new buffer
        echo a:inWindow
        if merginal#isMerginalWindow(a:inWindow)
            execute a:inWindow.'wincmd w'
            enew
        else
            40vnew
        endif
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal nomodifiable
        execute 'silent file '.a:bufferName
        call fugitive#detect(l:repo.dir())
    endif

    "At any rate, reassign the active repository
    let b:merginal_repo=l:repo

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



"Check if the current buffer's repo is in merge mode
function! merginal#isMergeMode()
    "Use glob() to check for file existence
    return !empty(glob(fugitive#repo().dir('MERGE_MODE')))
endfunction

"Open the branch list buffer for controlling buffers
function! merginal#openBranchListBuffer(...)
    if merginal#openTuiBuffer('Merginal:Branches',get(a:000,1,bufwinnr('Merginal:')))
        doautocmd User Merginal_BranchList
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshBranchListBuffer(1)
endfunction

augroup merginal
    autocmd User Merginal_BranchList nnoremap <buffer> R :call merginal#tryRefreshBranchListBuffer(0)<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> C :call <SID>checkoutBranchUnderCursor()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> cc :call <SID>checkoutBranchUnderCursor()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> A :call <SID>promptToCreateNewBranch()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> aa :call <SID>promptToCreateNewBranch()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> D :call <SID>deleteBranchUnderCursor()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> dd :call <SID>deleteBranchUnderCursor()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> M :call <SID>mergeBranchUnderCursor()<Cr>
    autocmd User Merginal_BranchList nnoremap <buffer> mm :call <SID>mergeBranchUnderCursor()<Cr>
augroup END

"If the current buffer is a branch list buffer - refresh it!
function! merginal#tryRefreshBranchListBuffer(jumpToCurrentBranch)
    if exists('b:merginal_repo') "We can only do this if this is a branch list buffer
        let l:branchList=split(merginal#system(b:merginal_repo.git_command('branch','--all')),'\r\n\|\n\|\r')
        let l:currentLine=line('.')

        setlocal modifiable
        "Clear the buffer:
        normal ggdG
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

"Exactly what it says on tin
function! s:checkoutBranchUnderCursor()
    if exists('b:merginal_repo') "We can only do this if this is a branch list buffer
        let l:branchName=substitute(getline('.'),'\v^\*?\s*','','') "Remove leading characters:
        echo merginal#runGitCommandInTreeReturnResult(b:merginal_repo,'--no-pager checkout '.shellescape(l:branchName))
        call merginal#reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(0)
    endif
endfunction

"Uses the current branch as the source
function! s:promptToCreateNewBranch()
    if exists('b:merginal_repo') "We can only do this if this is a branch list buffer
        let l:newBranchName=input('Branch `'.b:merginal_repo.head().'` to: ')
        echo merginal#runGitCommandInTreeReturnResult(b:merginal_repo,'--no-pager checkout -b '.shellescape(l:newBranchName))
        call merginal#reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(1)
    endif
endfunction

"Verifies the decision
function! s:deleteBranchUnderCursor()
    if exists('b:merginal_repo') "We can only do this if this is a branch list buffer
        let l:branchName=substitute(getline('.'),'\v^\*?\s*','','') "Remove leading characters:
        if 'yes'==input('Delete branch `'.l:branchName.'`?(type "yes" to confirm) ')
            echo ' '
            echo merginal#runGitCommandInTreeReturnResult(b:merginal_repo,'--no-pager branch -D '.shellescape(l:branchName))
            call merginal#reloadBuffers()
            call merginal#tryRefreshBranchListBuffer(0)
        endif
    endif
endfunction

"If there are merge conflicts, opens the merge conflicts buffer
function! s:mergeBranchUnderCursor()
    if exists('b:merginal_repo') "We can only do this if this is a branch list buffer
        let l:branchName=substitute(getline('.'),'\v^\*?\s*','','') "Remove leading characters:
        echo ' '
        echo merginal#runGitCommandInTreeReturnResult(b:merginal_repo,'merge --no-commit '.shellescape(l:branchName))
        if v:shell_error
            call merginal#reloadBuffers()
            call merginal#openMergeConflictsBuffer(winnr())
        endif
    endif
endfunction



"Open the merge conflicts buffer for resolving merge conflicts
function! merginal#openMergeConflictsBuffer(...)
    let l:currentFile=expand('%:~:.')
    if merginal#openTuiBuffer('Merginal:Conflicts',get(a:000,1,bufwinnr('Merginal:')))
        doautocmd User Merginal_MergeConflicts
    endif

    "At any rate, refresh the buffer:
    call merginal#tryRefreshMergeConflictsBuffer(l:currentFile)
endfunction

augroup merginal
    autocmd User Merginal_MergeConflicts nnoremap <buffer> R :call merginal#tryRefreshMergeConflictsBuffer(0)<Cr>
    autocmd User Merginal_MergeConflicts nnoremap <buffer> <Cr> :call <SID>openMergeConflictUnderCursor()<Cr>
    autocmd User Merginal_MergeConflicts nnoremap <buffer> A :call <SID>addConflictedFileToStagingArea()<Cr>
    autocmd User Merginal_MergeConflicts nnoremap <buffer> aa :call <SID>addConflictedFileToStagingArea()<Cr>
augroup END

"Returns 1 if all merges are done
function! merginal#tryRefreshMergeConflictsBuffer(fileToJumpTo)
    if exists('b:merginal_repo') "We can only do this if this is a merge conflicts buffer
        "Get the list of unmerged files:
        let l:branchList=split(merginal#system(b:merginal_repo.git_command('ls-files','--unmerged')),'\r\n\|\n\|\r')
        "Split by tab - the first part is info, the second is the file name
        let l:branchList=map(l:branchList,'split(v:val,"\t")')
        "Only take the stage 1 files - stage 2 and 3 are the same files with
        "different hash, and we don't care about the hash here
        let l:branchList=filter(l:branchList,'v:val[0] =~ "\\v 1$"')
        "Take the file name - we no longer care about the info
        let l:branchList=map(l:branchList,'v:val[1]')
        "If the working copy is not the current dir, we can get wrong paths.
        "We need to resulve that:
        let l:branchList=map(l:branchList,'b:merginal_repo.tree(v:val)')
        "Make the paths as short as possible:
        let l:branchList=map(l:branchList,'fnamemodify(v:val,":~:.")')


        let l:currentLine=line('.')

        setlocal modifiable
        "Clear the buffer:
        normal ggdG
        "Write the branch list:
        call setline(1,l:branchList)
        setlocal nomodifiable
        if empty(l:branchList)
            return 1
        endif

        if empty(a:fileToJumpTo)
            execute l:currentLine
        else
            let l:lineNumber=search('\V\^'+escape(a:fileToJumpTo,'\')+'\$','cnw')
            if 0<l:lineNumber
                execute l:lineNumber
            else
                execute l:currentLine
            endif
        endif
    endif
    return 0
endfunction

"Exactly what it says on tin
function! s:openMergeConflictUnderCursor()
    if exists('b:merginal_repo') "We can only do this if this is a merge conflicts buffer
        let l:fileName=getline('.')
        if empty(l:fileName)
            return
        endif

        "We have to check with bufexists, because bufnr also match prefixes of
        "the file name
        let l:fileBuffer=-1
        if bufexists(l:fileName)
            let l:fileBuffer=bufnr(l:fileName)
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
            if s:isWindowADisposableWindowOfRepo(l:previousWindow,b:merginal_repo)
                execute winnr('#').'wincmd w'
            else
                "If the previous window can't be used, check if any open
                "window can be used
                let l:windowsToOpenTheFileIn=merginal#getListOfDisposableWindowsOfRepo(b:merginal_repo)
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
                execute 'edit '.fnameescape(l:fileName)
            endif
        endif
    endif
endfunction

"If that was the last merge conflict, automatically opens Fugitive's status
"buffer
function! s:addConflictedFileToStagingArea()
    if exists('b:merginal_repo') "We can only do this if this is a merge conflicts buffer
        let l:fileName=getline('.')
        if empty(l:fileName)
            return
        endif
        echo merginal#runGitCommandInTreeReturnResult(b:merginal_repo,'--no-pager add '.shellescape(fnamemodify(l:fileName,':p')))

        if merginal#tryRefreshMergeConflictsBuffer(0)
            "If this returns 1, that means this is the last branch, and we
            "should open gufitive's status window
            let l:mergeConflictsBuffer=bufnr('')
            Gstatus
            let l:gitStatusBuffer=bufnr('')
            execute bufwinnr(l:mergeConflictsBuffer).'wincmd w'
            wincmd q
            execute bufwinnr(l:gitStatusBuffer).'wincmd w'
        endif
    endif
endfunction
