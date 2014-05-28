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
        execute '!'.b:merginal_repoForBranchList.git_command('checkout').' '.shellescape(l:branchName)
        call s:reloadBuffers()
        call merginal#tryRefreshBranchListBuffer(0)
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
