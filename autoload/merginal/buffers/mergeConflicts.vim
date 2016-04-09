call merginal#modulelib#makeModule(s:, 'mergeConflicts', 'conflictsBase')

function! s:f.lastFileAdded() dict abort
    let l:mergeConflictsBuffer = bufnr('')
    Gstatus
    let l:gitStatusBuffer = bufnr('')
    execute bufwinnr(l:mergeConflictsBuffer).'wincmd w'
    wincmd q
    execute bufwinnr(l:gitStatusBuffer).'wincmd w'
endfunction
