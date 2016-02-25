
"Exactly what it says on tin
function! s:openDiffFileUnderCursor()
    let l:diffFile=merginal#diffFileDetails('.')

    if l:diffFile.isDeleted
        throw 'File does not exist in current buffer'
    endif

    call merginal#openFileDecidedWindow(b:merginal_repo,l:diffFile.fileFullPath)
endfunction

"Exactly what it says on tin
function! s:openDiffFileUnderCursorAndDiff(diffType)
    if a:diffType!='s' && a:diffType!='v'
        throw 'Bad diff type'
    endif
    let l:diffFile=merginal#diffFileDetails('.')

    if l:diffFile.isAdded
        throw 'File does not exist in other buffer'
    endif

    let l:repo=b:merginal_repo
    let l:diffTarget=b:merginal_diffTarget

    "Close currently open git diffs
    let l:currentWindowBuffer=winbufnr('.')
    try
        windo if 'blob'==get(b:,'fugitive_type','') && exists('w:fugitive_diff_restore')
                    \| bdelete
                    \| endif
    catch
        "do nothing
    finally
        execute bufwinnr(l:currentWindowBuffer).'wincmd w'
    endtry

    call merginal#openFileDecidedWindow(l:repo,l:diffFile.fileFullPath)

    execute ':G'.a:diffType.'diff '.fnameescape(l:diffTarget)
endfunction

"Checks out the file from the diff target to the current branch
function! s:checkoutDiffFileUnderCursor()
    let l:diffFile=merginal#diffFileDetails('.')

    if l:diffFile.isAdded
        throw 'File does not exist in diffed buffer'
    endif

    let l:answer=1
    if !empty(glob(l:diffFile.fileFullPath))
        let l:answer='yes'==input('Override `'.l:diffFile.fileInTree.'`? (type "yes" to confirm) ')
    endif
    if l:answer
        call merginal#runGitCommandInTreeEcho(b:merginal_repo,'--no-pager checkout '.shellescape(b:merginal_diffTarget)
                    \.' -- '.shellescape(l:diffFile.fileFullPath))
        call merginal#reloadBuffers()
        call merginal#tryRefreshDiffFilesBuffer()
    else
        echo
        echom 'File checkout canceled by user.'
    endif
endfunction

nnoremap <buffer> q <C-w>q
nnoremap <buffer> R :call merginal#tryRefreshDiffFilesBuffer()<Cr>
nnoremap <buffer> <Cr> :call <SID>openDiffFileUnderCursor()<Cr>
nnoremap <buffer> ds :call <SID>openDiffFileUnderCursorAndDiff('s')<Cr>
nnoremap <buffer> dv :call <SID>openDiffFileUnderCursorAndDiff('v')<Cr>
nnoremap <buffer> co :call <SID>checkoutDiffFileUnderCursor()<Cr>
