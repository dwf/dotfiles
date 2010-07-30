" I like my terminals black but don't mind editors white. Override ~/.vimrc.
colorscheme default

set guioptions=egmrLt
set lines=500
set columns=80
highlight CursorLine gui=bold guibg=grey92

if has('gui_running') && has('mac')
    let $BROWSER='open' " Use the system default browser
endif
