" Basic Vim settings ported from previous configurations.

set confirm                     " Confirm dialog on quit.
set cursorline                  " Highlight cursor line.
set hlsearch                    " Highlight search results.
set ignorecase                  " Case-insensitive search.
set incsearch                   " Search-as-you-type.
set laststatus=2                " Always show status line.
set ruler                       " Show row/column positions.
set showmatch                   " Show matching parens.
set showmode                    " Show current mode in the bottom left corner.
set smartcase                   " ... except if you use caps.
set wildchar=<TAB>              " Tab-expansion in command mode.
set wildmenu                    " Display a menu on wildchar.
set wildmode=list:longest       " Tab-complete only if unambiguous.

" TODO(dwf): Maybe remove these.
set autoindent                  " Autoindent code by default.
set backspace=indent,eol,start  " Make backspace wrap lines.
set smartindent                 " Do something mildly smart with indentation.
set smarttab                    " Sane tab/backspace at line's beginning.

" Enable line numbering and define a toggle command.
set number
set relativenumber
noremap <silent> <C-l> :set invnumber<CR>

" Correct some typos.
command Wq wq
command WQ wq
command Q q

" Trailing whitespace detection. Keep regardless of colorscheme.
highlight ExtraWhitespace ctermbg=red
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhitespace /\s\+$/

" Fix the highlighting for menu expansions.
highlight Pmenu ctermfg=0 ctermbg=15
highlight CursorLine ctermbg=black cterm=bold
