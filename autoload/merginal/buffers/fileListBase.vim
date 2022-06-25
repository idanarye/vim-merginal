call merginal#modulelib#makeModule(s:, 'fileListBase', 'base')

function! s:f.filePaths(filename) dict abort
    let l:result = {}
    let l:result.name = a:filename " For backwards compatibility
    let l:result.fileInTree = fnamemodify(a:filename, ':.')
    let l:result.fileFullPath = FugitiveFind(self.fugitiveContext, a:filename)
    return l:result
endfunction


function! s:f.openFileUnderCursor() dict abort
    let l:file = self.fileDetails('.')
    if empty(l:file.name)
        return
    endif
    call merginal#openFileDecidedWindow(self.fugitiveContext, l:file.fileFullPath)
endfunction
call s:f.addCommand('openFileUnderCursor', [], 'MerginalOpen', ['<Cr>', 'o'], 'Open the file under the cursor.')


function! s:f.previewFileUnderCursor() dict abort
    let l:currentWindowBuffer = winbufnr('.')
    try
        call self.openFileUnderCursor()
    finally
        execute bufwinnr(l:currentWindowBuffer).'wincmd w'
    endtry
endfunction
call s:f.addCommand('previewFileUnderCursor', [], 'MerginalPreview', 'go', 'Preview the file under the cursor.')


function! s:f.openFileUnderCursorInNewWindow(newCommand) dict abort
    let l:file = self.fileDetails('.')
    if empty(l:file.name)
        return
    endif
    if a:newCommand != 'tabnew'
        execute winnr('#').'wincmd w'
    endif
    execute a:newCommand
    if bufexists(l:file.fileFullPath)
        execute 'buffer '.bufnr(l:file.fileFullPath)
    else
        execute 'edit '.l:file.fileFullPath
    endif
endfunction
call s:f.addCommand('openFileUnderCursorInNewWindow', ['new'], 'MerginalOpenSplit', 'i', 'Open the file under the cursor in a split.')
call s:f.addCommand('openFileUnderCursorInNewWindow', ['vnew'], 'MerginalOpenVSplit', 's', 'Open the file under the cursor in a vsplit.')
call s:f.addCommand('openFileUnderCursorInNewWindow', ['tabnew'], 'MerginalOpenTab', 't', 'Open the file under the cursor in a new tab.')


function! s:f.previewFileUnderCursorInNewWindow(newCommand) dict abort
    let l:file = self.fileDetails('.')
    if empty(l:file.name)
        return
    endif
    let l:currentWindowBuffer = winbufnr('.')
    let l:currentTab = tabpagenr() " The new tab will be created AFTER this one, so this tab number will not change
    try
        if a:newCommand != 'tabnew'
            execute winnr('#').'wincmd w'
        endif
        execute a:newCommand
        if bufexists(l:file.fileFullPath)
            execute 'buffer '.bufnr(l:file.fileFullPath)
        else
            execute 'edit '.l:file.fileFullPath
        endif
    finally
        execute 'tabnext '.l:currentTab
        execute bufwinnr(l:currentWindowBuffer).'wincmd w'
    endtry
endfunction
call s:f.addCommand('previewFileUnderCursorInNewWindow', ['new'], 'MerginalPreviewSplit', 'gi', 'Preview the file under the cursor in a split.')
call s:f.addCommand('previewFileUnderCursorInNewWindow', ['vnew'], 'MerginalPreviewVSplit', 'gs', 'Preview the file under the cursor in a vsplit.')
call s:f.addCommand('previewFileUnderCursorInNewWindow', ['tabnew'], 'MerginalPreviewTab', 'T', 'Preview the file under the cursor in a new tab.')
