call merginal#modulelib#makeModule(s:, 'conflictsBase', 'fileListBase')

function! s:f.generateBody() dict abort
    "Get the list of unmerged files:
    let l:conflicts = self.gitLines('ls-files', '--unmerged')

    "Split by tab - the first part is info, the second is the file name
    let l:conflicts = map(l:conflicts, 'split(v:val, "\t")')

    "Only take the stage 1 files - stage 2 and 3 are the same files with
    "different hash, and we don't care about the hash here
    let l:conflicts = filter(l:conflicts, 'v:val[0] =~ "\\v 1$"')

    "Take the file name - we no longer care about the info
    let l:conflicts = map(l:conflicts, 'v:val[1]')

    "If the working copy is not the current dir, we can get wrong paths.
    "We need to resolve that:
    let l:conflicts = map(l:conflicts, 'FugitiveFind(self.fugitiveContext, v:val)')

    "Make the paths as short as possible:
    let l:conflicts = map(l:conflicts, 'fnamemodify(v:val, ":~:.")')

    return l:conflicts
endfunction

function! s:f.fileDetails(lineNumber) dict abort
    call self.verifyLineInBody(a:lineNumber)

    let l:line = getline(a:lineNumber)
    let l:result = self.filePaths(l:line)

    return l:result
endfunction


function! s:f.openConflictedFileUnderCursor() dict abort
    echoerr 'openConflictedFileUnderCursor is deprecated - please use openFileUnderCursor instead'
    call self.openFileUnderCursor()
endfunction

function! s:f.addConflictedFileToStagingArea() dict abort
    let l:file = self.fileDetails('.')
    if empty(l:file.name)
        return
    endif

    call self.gitEcho('add', '--', fnamemodify(l:file.name, ':p'))
    call self.refresh()

    if empty(self.body) "This means that was the last file
        call self.lastFileAdded()
    endif
endfunction
call s:f.addCommand('addConflictedFileToStagingArea', [], 'MerginalAddConflictedFileToStagingArea', ['aa' ,'A'], 'Add the conflicted file under the cursor to the staging area.')
