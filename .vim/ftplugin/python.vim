" Only do all this once for each buffer.
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Most python types like soft tabs in their python code. So this 
" makes sure I use it too and don't get the interpreter mad at me.

setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4
setlocal expandtab

" Make text wrap at just under 80 characters.
setlocal textwidth=79

" Smart tabbing/indenting
setlocal smarttab
setlocal smartindent

" Folding preferences
" setlocal foldmethod=indent " Works well enough for Python, but fold.vim++
setlocal foldminlines=4    " Folding 3 lines or less is kind of pointless.

" Spacebar to fold/unfold.
nnoremap <space> za
vnoremap <space> zf
