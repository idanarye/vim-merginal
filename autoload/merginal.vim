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
    if exists('*termopen')
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


function! merginal#getSpecialMode(repo) abort
    if !empty(glob(a:repo.dir('MERGE_MODE')))
        return 'mergeConflicts'
    elseif isdirectory(a:repo.dir('rebase-merge'))
        return 'rebaseAmend'
    elseif isdirectory(a:repo.dir('rebase-apply'))
        return 'rebaseConflicts'
    elseif !empty(glob(a:repo.dir('CHERRY_PICK_HEAD')))
        return 'cherryPickConflicts'
    endif
    return ''
endfunction

function! merginal#openMerginalBuffer() abort
    let l:mode = merginal#getSpecialMode(fugitive#repo())
    if empty(l:mode)
        let l:mode = 'branchList'
    endif
    if exists('b:merginal')
        let l:targetWindow = winnr()
    else
        let l:targetWindow = -1
    endif
    call merginal#modulelib#createObject(l:mode).openTuiBuffer(l:targetWindow)
endfunction
