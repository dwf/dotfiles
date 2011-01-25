" I like my terminals black but don't mind editors white. Override ~/.vimrc.
set guioptions-=T
if has('gui_running')
    colorscheme default
    set background=light
endif

if match(hostname(), "iro.umontreal.ca") > 0
    set lines=500
    set columns=200
endif

highlight Folded gui=italic guifg=Black guibg=grey95
highlight CursorLine gui=bold guibg=grey90

if has('gui_running') && has('mac')
    let $BROWSER='open' " Use the system default browser
endif
