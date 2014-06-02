
function! merginal#openBranchListBuffer()
    let l:repo=fugitive#repo()

    let l:branchListWindow=bufwinnr(bufnr('Merginal:Branches'))

    if -1<l:branchListWindow "Jump to the already open buffer
        execute l:branchListWindow.'wincmd w'
    else "Open a new buffer
        40vnew
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal nomodifiable
        silent file Merginal:Branches
        nnoremap <buffer> R :call merginal#tryRefreshBranchListBuffer(0)<Cr>
        nnoremap <buffer> C :call <SID>checkoutBranchUnderCursor()<Cr>
        nnoremap <buffer> A :call <SID>promptToCreateNewBranch()<Cr>
        nnoremap <buffer> D :call <SID>deleteBranchUnderCursor()<Cr>
    endif

    "At any rate, reassign the active repository
    let b:merginal_repoForBranchList=l:repo
    "And refresh the buffer:
    call merginal#tryRefreshBranchListBuffer(1)
endfunction

function! merginal#tryRefreshBranchListBuffer(jumpToCurrentBranch)
    if exists('b:merginal_repoForBranchList') "We only have this if this is a branch list buffer
        let l:branchList=split(system(b:merginal_repoForBranchList.git_command('branch')),'\r\n\|\n\|\r')
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

function! s:checkoutBranchUnderCursor()
    if exists('b:merginal_repoForBranchList') "We only have this if this is a branch list buffer
        let l:branchName=substitute(getline('.'),'\v^\*?\s*','','') "Remove leading characters:
        echo s:runGitCommandInTreeReturnResult(b:merginal_repoForBranchList,'--no-pager checkout '.shellescape(l:branchName))
        call s:reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(0)
    endif
endfunction

function! s:promptToCreateNewBranch()
    if exists('b:merginal_repoForBranchList') "We only have this if this is a branch list buffer
        let l:newBranchName=input('Branch `'.fugitive#repo().head().'` to: ')
        echo s:runGitCommandInTreeReturnResult(b:merginal_repoForBranchList,'--no-pager checkout -b '.shellescape(l:newBranchName))
        call s:reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(1)
    endif
endfunction

function! s:deleteBranchUnderCursor()
    if exists('b:merginal_repoForBranchList') "We only have this if this is a branch list buffer
        let l:branchName=substitute(getline('.'),'\v^\*?\s*','','') "Remove leading characters:
        if 'yes'==input('Delete branch `'.l:branchName.'`?(type "yes" to confirm) ')
            echo ' '
            echo s:runGitCommandInTreeReturnResult(b:merginal_repoForBranchList,'--no-pager branch -d '.shellescape(l:branchName))
            call s:reloadBuffers()
            call merginal#tryRefreshBranchListBuffer(0)
        endif
    endif
endfunction

function! s:reloadBuffers()
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
function! s:runGitCommandInTree(repo,command)
    let l:dir=getcwd()
    execute 'cd '.fnameescape(a:repo.tree())
    try
        execute '!'.a:repo.git_command().' '.a:command
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction
function! s:runGitCommandInTreeReturnResult(repo,command)
    let l:dir=getcwd()
    execute 'cd '.fnameescape(a:repo.tree())
    try
        return system(a:repo.git_command().' '.a:command)
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction
