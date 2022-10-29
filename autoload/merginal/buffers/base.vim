call merginal#modulelib#makeModule(s:, 'base', '')

let s:f.helpVisible = 0
let s:f.remoteVisible = get(g:, 'merginal_remoteVisible', 1)
let s:f.filter = ''

function! s:flattenAppend(target, items) abort
    for l:item in a:items
        if type(l:item) == type([])
            call s:flattenAppend(a:target, l:item)
        elseif type(l:item) == type('')
            call add(a:target, l:item)
        else
            call add(a:target, string(l:item))
        endif
    endfor
    return a:target
endfunction

function! s:f.gitCommand(...) dict abort
    return FugitiveShellCommand(self.fugitiveContext, s:flattenAppend([], a:000))
endfunction

function! s:f.generateHelp() dict abort
    let l:result = []
    let l:columnWidths = [4, winwidth(0) - 5]
    for l:meta in self._meta
        if has_key(l:meta, 'doc')
            if !empty(l:meta.keymaps)
                let l:result += merginal#util#makeColumns(l:columnWidths, [l:meta.keymaps[0], l:meta.doc])
                for l:keymap in l:meta.keymaps[1:]
                    let l:result += merginal#util#makeColumns(l:columnWidths, [l:keymap, 'same as '.l:meta.keymaps[0]])
                endfor
            endif
        endif
    endfor
    return l:result
endfunction

function! s:f.generateHeader() dict abort
    return []
endfunction

function! s:f.generateBody() dict abort
    throw 'generateBody() Not implemented for '.self.name
endfunction

function! s:bufferNameFor(role) abort
    if !exists('t:merginal_tabpageUniqueIdentifier')
        let t:merginal_tabpageUniqueIdentifier = reltimestr(reltime())
    endif
    return printf('Merginal:%s:%s', a:role, t:merginal_tabpageUniqueIdentifier)
endfunction

function! s:f.bufferName() dict abort
    return s:bufferNameFor(self.name)
endfunction

function! s:f.existingWindowNumber() dict abort
    " return bufwinnr(bufnr(self.bufferName()))
    " return bufwinnr(bufnr(s:bufferNameFor('*')))
    return bufwinnr('Merginal:')
endfunction

function! s:f.gitRun(...) dict abort
    let l:dir = getcwd()
    execute 'cd '.fnameescape(self.fugitiveContext.work_tree)
    try
        let l:gitCommand = self.gitCommand('--no-pager', a:000)
        echo 'Running command' string(l:gitCommand)
        return merginal#system(l:gitCommand)
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction

function! s:f.gitLines(...) dict abort
    return split(call(self.gitRun, a:000, self), '\r\n\|\n\|\r')
endfunction

function! s:f.gitEcho(...) dict abort
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

function! s:f.gitBang(...) dict abort
    let l:dir = getcwd()
    execute 'cd '.fnameescape(self.fugitiveContext.work_tree)
    try
        let l:gitCommand = self.gitCommand('--no-pager', a:000)
        call merginal#bang(l:gitCommand)
    finally
        execute 'cd '.fnameescape(l:dir)
    endtry
endfunction

"Returns 1 if a new window was opened, 0 if it already existed
function! s:f.openTuiBuffer(targetWindow) dict abort
    let self.fugitiveContext = {
                \ 'git_dir': FugitiveGitDir(),
                \ 'work_tree': FugitiveWorkTree(),
                \ }

    if -1 < a:targetWindow
        let l:tuiBufferWindow = -1
    else
        let l:tuiBufferWindow = self.existingWindowNumber()
    endif

    if -1 < l:tuiBufferWindow "Jump to the already open buffer
        execute l:tuiBufferWindow.'wincmd w'
    else "Open a new buffer
        if -1 < a:targetWindow
            enew
        else
            let l:window_width = get(g:, 'merginal_windowWidth', 40)
            let l:size = get(g:, 'merginal_windowSize', l:window_width)
            execute l:size.get(g:, 'merginal_splitType', 'v').'new'
        endif
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal nomodifiable
        setlocal winfixwidth
        setlocal winfixheight
        setlocal nonumber
        setlocal norelativenumber
        setlocal filetype=merginal
        execute 'silent file '.self.bufferName()
        call FugitiveDetect(self.fugitiveContext.git_dir)

        for l:meta in self._meta
            for l:keymap in l:meta.keymaps
                execute 'nnoremap <buffer> <nowait> '.l:keymap.' :'.l:meta.execute.'<Cr>'
            endfor

            if has_key(l:meta, 'command')
                execute 'command! -buffer -nargs=0 '.l:meta.command.' '.l:meta.execute
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

function! s:f.gotoBuffer(bufferModuleName, ...) dict abort
    let l:newBufferObject = merginal#modulelib#createObject(a:bufferModuleName)
    if has_key(l:newBufferObject, 'init')
        call call(l:newBufferObject.init, a:000, l:newBufferObject)
    elseif 0 < a:0
        throw 'gotoBuffer called with arguments but '.a:bufferModuleName.' has no "init" method'
    endif
    call l:newBufferObject.openTuiBuffer(winnr())
    return l:newBufferObject
endfunction

function! s:f._getSpecialMode() dict abort
    return merginal#getSpecialMode(self.fugitiveContext.git_dir)
endfunction

"Returns the buffer moved to
function! s:f.gotoSpecialModeBuffer() dict abort
    let l:mode = self._getSpecialMode()
    if empty(l:mode) || l:mode == self.name
        return 0
    endif
    let l:newBufferObject = self.gotoBuffer(l:mode)
    return l:newBufferObject
endfunction

function! s:f.isLineInBody(lineNumber) dict abort
    if type(a:lineNumber) == type(0)
        let l:line = a:lineNumber
    else
        let l:line = line(a:lineNumber)
    endif
    return len(self.header) < l:line
endfunction

function! s:f.verifyLineInBody(lineNumber) dict abort
    if !self.isLineInBody(a:lineNumber)
        throw 'In the header section of the merginal buffer'
    endif
endfunction

function! s:f.jumpToIndexInBody(index) dict abort
    execute a:index + len(self.header) + 1
endfunction

function! s:f.isStillInSpecialMode() dict abort
    let l:mode = self._getSpecialMode()
    return l:mode == self.name
endfunction


function! s:f.getFilteredBody() dict abort
    return filter(copy(self.body), '0 <= match(v:val, self.filter)')
endfunction

function! s:f.refresh() dict abort
    let self.header = []
    if self.helpVisible
        call extend(self.header, self.generateHelp())
    else
        call add(self.header, 'Press ? for help')
    endif
    call add(self.header, '')
    call extend(self.header, self.generateHeader())
    let self.body = self.generateBody()

    let l:tuiBufferWindow = self.existingWindowNumber()
    if -1 < l:tuiBufferWindow
        let l:remember = merginal#util#rememberCursorWindow()
        try
            execute l:tuiBufferWindow.'wincmd w'
            let l:currentLine = line('.') - len(self.header)
            let l:currentColumn = col('.')

            setlocal modifiable
            "Clear the buffer:
            silent normal! gg"_dG
            "Write the buffer
            call setline(1, self.header + self.getFilteredBody())
            let l:currentLine = l:currentLine + len(self.header)
            setlocal nomodifiable

            execute l:currentLine
            execute 'normal! '.l:currentColumn.'|'
        finally
            call l:remember.restore()
        endtry
    endif
endfunction
call s:f.addCommand('refresh', [], 'MerginalRefresh', 'R', 'Refresh the buffer')

function! s:f.quit()
    bdelete
endfunction
call s:f.addCommand('quit', [], 0, 'q', 'Close the buffer')

function! s:f.toggleHelp() dict abort
    let self.helpVisible = !self.helpVisible
    call self.refresh()
endfunction
call s:f.addCommand('toggleHelp', [], 0, '?', 'Toggle this help message')

function! s:f.toggleRemote() dict abort
    let self.remoteVisible = !self.remoteVisible
    call self.refresh()
endfunction
call s:f.addCommand('toggleRemote', [], 0, 'tr', 'Toggle remote branches')

function! s:f.promptForFilter() dict abort
    let l:newFilter = input('&/')
    let self.filter = l:newFilter
    call self.refresh()
endfunction
call s:f.addCommand('promptForFilter', [], 0, '&', 'Set filter')

