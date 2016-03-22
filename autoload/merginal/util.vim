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
