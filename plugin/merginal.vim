function! s:toggleBasedOnMergeMode() abort
    let l:merginalWindowNumber = bufwinnr('Merginal:')
    if 0 <= l:merginalWindowNumber
        let l:merginalBufferNumber = winbufnr(l:merginalWindowNumber)
        let l:bufferObject = getbufvar(l:merginalBufferNumber, 'merginal')
        let l:mode = l:bufferObject._getSpecialMode()
        if l:mode == ''
            let l:mode = 'branchList'
        endif
        if l:bufferObject.name == l:mode
            call merginal#closeMerginalBuffer()
            return
        elseif l:merginalWindowNumber == winnr()
            call l:bufferObject.gotoBuffer(l:mode)
        else
            execute l:merginalWindowNumber.'wincmd w'
        endif
    else
        call merginal#openMerginalBuffer()
    endif
endfunction

command! -nargs=0 Merginal call merginal#openMerginalBuffer()
command! -nargs=0 MerginalToggle call s:toggleBasedOnMergeMode()
command! -nargs=0 MerginalClose call merginal#closeMerginalBuffer()
