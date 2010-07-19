" More readable on a black background than default
colorscheme desert
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

set backspace=indent,eol,start  " Make backspace wrap lines

autocmd FileType mail set spell " Turn on spellcheck when writing email

" (Paul) got this one off stackoverflow
" Will allow you to use :w!! to write to a file using sudo if you
" forgot to 'sudo vim file' (it will prompt for sudo password)
cmap w!! %!sudo tee > /dev/null %



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
