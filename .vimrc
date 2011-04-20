" More readable on a black background than default

if !has('gui_running')
    set background=dark
    colorscheme desert
endif
set t_Co=256
syntax on
set autoindent

filetype plugin indent on

" Stolen from Paul Ivanov
set hlsearch     " highlight search terms
set incsearch    " incremental search
set confirm      " confirm dialog instead of 'use ! to override'
set showmatch    " show matching parens
set ruler        " show row/col positions
set ignorecase   " ignore case when searching
set smartcase    " ... except when there are caps in the pattern
set showmode     " show current mode in bottom left corner
set laststatus=2 " Always display status line

set cursorline   " Highlight the line the cursor is currently on
"set cursorcolumn " Highlight the current cursor column (gets annoying)

" Customize the cursorline stuff to make it better than the standard color
" terminal stuff.
highlight CursorLine cterm=bold ctermbg=darkgrey

set backspace=indent,eol,start  " Make backspace wrap lines

autocmd FileType mail set spell " Turn on spellcheck when writing email

" Stolen from @shazow
set wildchar=<TAB>        " This is default anyway
set wildmenu              " Display a menu on wildchar
set wildmode=list:longest " Complete unambiguous part only

" Some buffer management key bindings
map <Leader>] :bnext<CR>
map <Leader>[ :bprev<CR>

" Tell the enhanced ~/.vim/syntax/python.vim to 'be all it can be'
" (why can't I seem to put this in ftplugin/python.vim and have it work?)
let python_highlight_all = 1

" (Paul) got this one off stackoverflow
" Will allow you to use :w!! to write to a file using sudo if you
" forgot to 'sudo vim file' (it will prompt for sudo password)
cmap w!! %!sudo tee > /dev/null %

" Enable omnicompletion for programming syntax
set omnifunc=syntaxcomplete#Complete

" Masochistic anti-arrow-key settings.
"noremap  <Up> ""
"noremap! <Up> <Esc>
"noremap  <Down> ""
"noremap! <Down> <Esc>
"noremap  <Left> ""
"noremap! <Left> <Esc>
"noremap  <Right> ""
"noremap! <Right> <Esc>
" Less masochistic anti-PgUp/PgDown
noremap  <PageUp> ""
noremap! <PageUp> <Esc>
noremap <PageDown> ""
noremap! <PageDown> <Esc>

" Automatically strip trailing whitespace on save.
autocmd BufWritePre *.py,*.pyx,*.rst,*.txt :%s/\s\+$//e

" Function to activate a virtualenv in the embedded interpreter for
" omnicomplete and other things like that.
function! LoadVirtualEnv(path)
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

" Only attempt to load this virtualenv if the defaultvirtualenv
" actually exists, and we aren't running with a virtualenv active.
if has("python") 
    if empty($VIRTUAL_ENV) && getftype(defaultvirtualenv) == "dir"
        call LoadVirtualEnv(defaultvirtualenv)
    endif
endif
