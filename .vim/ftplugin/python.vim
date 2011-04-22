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
setlocal foldmethod=syntax " Use my fixed-up syntax-folding
setlocal foldminlines=3    " Folding 2 lines or less is kind of pointless.

" Spacebar to fold/unfold.
nnoremap <space> za
vnoremap <space> zf

setlocal foldtext=PythonFoldText()
function! PythonFoldText() "{{{
  let line = getline(v:foldstart)
  " return line.' ['.(v:foldend - v:foldstart).'] '
  " Add a +, replacing the first character if it's a space.
  if strpart(line, 0, 1) == ' '
     let line = strpart(line, 1)
  endif
  return '+'. line.' ['.(v:foldend - v:foldstart).'] '
endfunction "}}}
