""""""""""""""""""""""" Vundle setup -- do not modify.""""""""""""""""""""""""""
set nocompatible
filetype off

" Set the runtime path to include Vundle.
set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()             " Initialize
Plugin 'gmarik/Vundle.vim'      " Let Vundle manage Vundle -- required.
Plugin 'klen/python-mode'       " The Python-mode plugin.
call vundle#end()               " Required by Vundle.
filetype plugin indent on       " Required by Vundle.

""""""""""""""""""""""" End of Vundle setup section.""""""""""""""""""""""""""""

syntax on                       " Syntax highlighting on by default.
set autoindent                  " Autoindent code by default.
set smartindent                 " Do something mildly smart with indentation.
set smarttab                    " Sane tab/backspace at line's beginning.
set tabstop=4                   " Narrower tabs, good god.
set textwidth=79                " Wrap just below 80 characters.
filetype plugin on              " Load filetype plugins on buffer load.
filetype indent on              " Load filetype-specific indents.
set hlsearch                    " Highlight search terms in buffer.
set incsearch                   " Incremental search while-you-type.
set confirm                     " Confirm dialog instead of 'use ! to override'.
set showmatch                   " Show matching parentheses for cursor char.
set ruler                       " Show row/column positions.
set ignorecase                  " Ignore case when searching.
set smartcase                   " ... except when there are caps in the pattern.
set showmode                    " Show current mode in the bottom left corner.
set laststatus=2                " Always display status line.
set cursorline                  " Highlight the line the cursor is currently on.
set backspace=indent,eol,start  " Make backspace wrap lines.
autocmd FileType mail set spell " Turn on spellcheck when writing email.
set wildchar=<TAB>              " Start wildcard expansion with tab (default).
set wildmenu                    " Display a menu on wildchar.
set wildmode=list:longest       " Tab-complete unambiguous part only.

" Next/previous buffer key bindings.
map <Leader>] :bnext<CR>
map <Leader>[ :bprev<CR>

" Custom color scheme in terminal Vim.
if !has('gui_running')
    set background=dark
    set t_Co=256
    colorscheme elflord
    " Customize the cursorline stuff to make it more readable.
    highlight CursorLine cterm=bold ctermbg=darkgrey
endif

" Will allow you to use :w!! to write to a file using sudo if you
" forgot to 'sudo vim file' (it will prompt for sudo password)
cmap w!! %!sudo tee > /dev/null %

" Frequently mistyped due to laggy shift-finger.
command Wq wq
command WQ wq
command Q q
