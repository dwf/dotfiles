set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required!
Bundle 'gmarik/vundle'
Bundle 'klen/python-mode'


if !has('gui_running')
    set background=dark
    set t_Co=256
    colorscheme elflord
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

" (Paul) got this one off stackoverflow
" Will allow you to use :w!! to write to a file using sudo if you
" forgot to 'sudo vim file' (it will prompt for sudo password)
cmap w!! %!sudo tee > /dev/null %
