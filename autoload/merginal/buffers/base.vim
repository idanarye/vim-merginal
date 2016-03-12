
call merginal#modulelib#makeModule(s:, 'base', '')

let s:f.helpVisible = 0

function! s:f.generateHelp() dict
    let l:result = []
    for l:meta in values(self._meta)
        if has_key(l:meta, 'doc')
            if !empty(l:meta.keymaps)
                call add(l:result, l:meta.keymaps[0]."\t".l:meta.doc)
                for l:keymap in l:meta.keymaps[1:]
                    call add(l:result, l:keymap."\tsame as ".l:meta.keymaps[0])
                endfor
            endif
        endif
    endfor
    return l:result
endfunction

function! s:f.generateHeader()
    return []
endfunction

function! s:f.generateBody()
    throw 'generateBody() Not implemented for '.self.name
endfunction

function! s:f.bufferName() dict
    return 'Merginal:'.self.name
endfunction

function! s:f.existingWindowNumber() dict
    return bufwinnr(bufnr(self.bufferName()))
endfunction

function! s:f.gitRunInTree(...) dict
    let l:dir = getcwd()
    execute 'cd '.fnameescape(self.repo.tree())
    try
        let l:gitCommand = call(self.repo.git_command, a:000, self.repo)
        return merginal#system(l:gitCommand)
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction

function! s:f.gitLines(...) dict
    return split(call(self.gitRunInTree, a:000, self), '\r\n\|\n\|\r')
endfunction

function! s:f.gitEcho(...) dict
    let l:lines = call(self.gitLines, a:000, self)
    if len(l:lines) == 1
        " Output a single/empty line to make Vim wait for Enter.
        echo ' '
    endif
    for l:line in l:lines
        let l:line = substitute(l:line, '\t', repeat(' ', &tabstop), 'g')
        " Remove terminal escape codes for colors (based on
        " www.commandlinefu.com/commands/view/3584/).
        let l:line = substitute(l:line, '\v\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]', '', 'g')
        echo "[output]" l:line
    endfor
endfunction

"Returns 1 if a new buffer was opened, 0 if it already existed
function! s:f.openTuiBuffer() dict
    let self.repo = fugitive#repo()

    let l:tuiBufferWindow = self.existingWindowNumber()

    if -1 < l:tuiBufferWindow "Jump to the already open buffer
        execute l:tuiBufferWindow.'wincmd w'
    else "Open a new buffer
        "if merginal#isMerginalWindow(a:inWindow)
            "execute a:inWindow.'wincmd w'
            "enew
        "else
            40vnew
        "endif
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal nomodifiable
        setlocal winfixwidth
        setlocal winfixheight
        setlocal nonumber
        setlocal norelativenumber
        execute 'silent file '.self.bufferName()
        call fugitive#detect(self.repo.dir())

        for [l:fn, l:meta] in items(self._meta)
            for l:keymap in l:meta.keymaps
                execute 'nnoremap <buffer> '.l:keymap.' :call b:merginal.'.l:fn.'()<Cr>'
            endfor

            if has_key(l:meta, 'command')
                execute 'command! -buffer -nargs=0 '.l:meta.command.' :call b:merginal.'.l:fn.'()'
            endif
        endfor

        call self.refresh()
        if has_key(self, 'jumpToCurrentItem')
            call self.jumpToCurrentItem()
        endif
    endif

    let b:merginal = self

    "Check and return if a new buffer was created
    return -1 == l:tuiBufferWindow
endfunction


function! s:f.verifyLineInBody(lineNumber) dict
    if line(a:lineNumber) <= len(self.header)
        throw 'In the header section of the merginal buffer'
    endif
endfunction

function! s:f.jumpToIndexInBody(index) dict
    execute a:index + len(self.header) + 1
endfunction




function! s:f.refresh() dict
    let self.header = []
    if self.helpVisible
        call extend(self.header, self.generateHelp())
    else
        call add(self.header, 'Press ? for help')
    endif
    call add(self.header, '')
    call extend(self.header, self.generateHeader())
    let self.body = self.generateBody()

    let l:currentLine = line('.') - len(self.header)
    let l:currentColumn = col('.')

    setlocal modifiable
    "Clear the buffer:
    silent normal! gg"_dG
    "Write the buffer
    call setline(1, self.header + self.body)
    let l:currentLine = l:currentLine + len(self.header)
    setlocal nomodifiable

    execute l:currentLine
    execute 'normal! '.l:currentColumn.'|'
endfunction
call s:f.setCommand('refresh', 'MerginalRefresh', 'R', 'Refresh the buffer')

function! s:f.quit()
    bdelete
endfunction
call s:f.setCommand('quit', 0, 'q', 'Close the buffer')

function! s:f.toggleHelp() dict
    let self.helpVisible = !self.helpVisible
    echo self.helpVisible
    call self.refresh()
endfunction
call s:f.setCommand('toggleHelp', 0, '?', 'Toggle this help message')
