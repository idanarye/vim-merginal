"Similar to Vim's inputlist, but adds numbers and a 'more' option for huge
"lists. If no options selected, returns -1(not 0 like inputlist!)
function! merginal#util#inputList(prompt, options, morePrompt) abort
    let l:takeFrom = 0
    while l:takeFrom < len(a:options)
        let l:takeThisTime = &lines - 2
        if l:takeFrom + l:takeThisTime < len(a:options)
            let l:more = l:takeThisTime
            let l:takeThisTime -= 1
        else
            let l:more = 0
        endif

        let l:options = [a:prompt]

        for l:i in range(min([l:takeThisTime, len(a:options) - l:takeFrom]))
            call add(l:options, printf('%i) %s', 1 + l:i, a:options[l:takeFrom + l:i]))
        endfor
        if l:more
            call add(l:options, printf('%i) %s', l:more, a:morePrompt))
        endif
        let l:selected = inputlist(l:options)
        if l:selected <= 0 || len(l:options) <= l:selected
            return -1
        elseif l:more && l:selected < l:more
            return l:takeFrom + l:selected - 1
        elseif !l:more && l:selected < len(l:options)
            return l:takeFrom + l:selected - 1
        endif

        "Create a new line for the next inputlist's prompt
        echo ' '

        let l:takeFrom += l:takeThisTime
    endwhile
endfunction

function! merginal#util#makeColumns(widths, texts) abort
    let l:brokenToLines = []
    for l:i in range(len(a:texts))
        let l:text = a:texts[l:i]
        let l:width = a:widths[l:i]
        let l:lines = []
        let l:line = ''
        let l:words = split(l:text, ' ')
        for l:word in l:words
            if l:width < len(l:line) + 1 + len(l:word)
                if !empty(l:line)
                    call add(l:lines, l:line)
                endif
                while l:width < len(l:word)
                    call add(l:lines, l:word[:l:width - 1])
                    let l:word = l:word[l:width :]
                endwhile
                let l:line = ''
            endif
            if !empty(l:line)
                let l:line .= ' '
            endif
            let l:line .= l:word
        endfor
        if !empty(l:line)
            call add(l:lines, l:line)
        endif
        call add(l:brokenToLines, l:lines)
    endfor

    let l:maxLength = max(map(copy(l:brokenToLines), 'len(v:val)'))
    for l:lines in l:brokenToLines
        while len(l:lines) < l:maxLength
            call add(l:lines, '')
        endwhile
    endfor

    let l:result = []
    for l:i in range(l:maxLength)
        let l:resultLine = ''
        for l:j in range(len(l:brokenToLines))
            let l:width = a:widths[l:j]
            let l:line = l:brokenToLines[l:j][l:i]
            let l:resultLine .= l:line.repeat(' ', l:width - len(l:line))
            let l:resultLine .= ' '
        endfor
        let l:resultLine = substitute(l:resultLine, '\v\s*$', '', '')
        call add(l:result, l:resultLine)
    endfor

    return l:result
endfunction

let s:RememberdCursorWindow = {}
function s:RememberdCursorWindow.restore() abort dict
    execute self.previousWindow.'wincmd w'
    execute self.currentWindow.'wincmd w'
endfunction

function! merginal#util#rememberCursorWindow() abort
    let l:rememberdCursorWindow = copy(s:RememberdCursorWindow)
    let l:rememberdCursorWindow.previousWindow = winnr('#')
    let l:rememberdCursorWindow.currentWindow = winnr()
    return l:rememberdCursorWindow
endfunction
