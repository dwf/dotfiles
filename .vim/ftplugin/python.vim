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

" Function to activate a virtualenv in the embedded interpreter for
" omnicomplete and other things like that.
function LoadVirtualEnv(path)
    let activate_this = a:path . '/bin/activate_this.py'
    if getftype(a:path) == "dir" && filereadable(activate_this)
        python << EOF
import vim
activate_this = vim.eval('l:activate_this')
execfile(activate_this, dict(__file__=activate_this))
EOF
    endif
endfunction

" Load up a 'stable' virtualenv if one exists in ~/.virtualenv
let defaultvirtualenv = $HOME . "/.virtualenvs/stable"
if getftype(defaultvirtualenv) == "dir"
    call LoadVirtualEnv(defaultvirtualenv)
endif
