" Only do all this once for each buffer.
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal expandtab        " Never insert hard tabs.
setlocal softtabstop=4    " Unsure whether this is necessary.
setlocal shiftwidth=4     " Autoindent and > < use 4 spaces i.e. 1 soft tab.
setlocal textwidth=79     " Make text wrap at just under 80 characters.
setlocal smarttab         " Sensible Tab/backspace at the beginning of a line.
setlocal smartindent      " Do some mildly smart autoindenting.

" Set 'make' to run Cython annotation viewer in the browser.
if exists('$BROWSER')
    setlocal makeprg=cython\ -a\ %\ &&\ $BROWSER\ '%<.html'
endif
