
" Don't maintain vi compatibility
set nocompatible
set mouse=a
set wildmenu
set showcmd
set lazyredraw

" Highlighting
set cursorline
hi CursorLine term=none cterm=none ctermbg=105 " 7

set hlsearch
set incsearch

" No bells
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Keep some context on screen
set scrolloff=5

" Encoding
set encoding=utf8
set ffs=unix

" Functions
function DupesNext(...)
  " Options include 'b' (backwards) and 'W' (don't wrap)
  call search('^[x ] \/',  a:0 > 0 ? a:1 : '')
endfunction

function DupesNextGroup(...)
  if a:0 > 0 && a:1 ==# 'b'
    call search('^  \[',  'cb')
    call search('^  \[',  'b')
  else
    call search('^  \[')
  endif
  call DupesNext()
endfunction

function DupesToggleMark(...)
  " Toggle between x and <space> (suppressing errors)
  silent! s/^\([x ]\) \//\=tr(submatch(1), 'x ', ' x')." \/"
  if a:0 > 0
    call DupesNext(a:1)
  else
    call DupesNext()
  endif
endfunction

function DupesSetMark(...)
  " Changes x to <space> (suppressing errors)
  silent! s/^  \//x \/
  if a:0 > 0
    call DupesNext(a:1)
  else
    call DupesNext()
  endif
endfunction

function DupesClearMark(...)
  " Changes x to <space> (suppressing errors)
  silent! s/^x \//  \/
  if a:0 > 0
    call DupesNext(a:1)
  else
    call DupesNext()
  endif
endfunction

function DupesGetFilename(lnum)
  return substitute(getline(a:lnum), '^[x ] ', '', '')
endfunction

function DupesOpenFile(...)
  if a:0 > 0 && a:1 == '-R'
    execute 'silent !open -R' shellescape(DupesGetFilename('.'))
  else
    execute 'silent !open' shellescape(DupesGetFilename('.'))
  endif
  redraw!
  " echo DupesGetFilename('.')
endfunction

function DupesMaps()
  " Marking files
  nnoremap <special> <silent> x :call DupesSetMark('W')<CR>
  nnoremap <special> <silent> X :call DupesToggleMark('W')<CR>
  nnoremap <special> <silent> <space> :call DupesClearMark()<CR>
  nnoremap <special> <silent> Q :wq<CR>

  " Movement
  nnoremap <special> <silent> <buffer> <up> :call DupesNext('b')<CR>
  nnoremap <special> <silent> <buffer> <down> :call DupesNext()<CR>
  nnoremap <special> <silent> <buffer> <C-U> <C-U>:call DupesNext()<CR>
  nnoremap <special> <silent> <buffer> <C-D> <C-D>:call DupesNext('b')<CR>
  nnoremap <special> <silent> <buffer> <tab> :call DupesNextGroup()<CR>
  nnoremap <special> <silent> <buffer> <S-tab> :call DupesNextGroup('b')<CR>

  " Opening files
  nnoremap <special> <silent> <buffer> o :call DupesOpenFile()<CR>
  nnoremap <special> <silent> <buffer> O :call DupesOpenFile('-R')<CR>
endfunction

aug Dupes
  au!
  au BufRead *.dupes :call DupesMaps()
  au BufRead *.dupes :call DupesNext()
aug END

