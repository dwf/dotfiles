" More readable on a black background than default
:colorscheme desert
:syntax on

" Most python types like soft tabs in their python code. So this 
" makes sure I use it too and don't get the interpreter mad at me.

:autocmd Filetype python set expandtab
:autocmd Filetype python set softtabstop=4
:autocmd Filetype pyrex set expandtab
:autocmd Filetype pyrex set softtabstop=4
