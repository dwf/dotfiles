" Rope seems to be more trouble than it's worth by default, but define a
" key combo to turn it on.
let g:pymode_rope=0

function! ToggleRope()
    if g:pymode_rope == 0
        let g:pymode_rope=1
        echom "Rope plugin enabled."
    else
        let g:pymode_rope=0
        echom "Rope plugin disabled."
    endif
endfunction

nnoremap <leader>o :call ToggleRope()<cr>

