" plugin/cursorshape.vim
scriptencoding utf-8

" Load guard
if exists('g:loaded_cursorshape')
  finish
endif
let g:loaded_cursorshape = 1

" cpoptions guard
let s:save_cpo = &cpoptions
set cpoptions&vim

" Default options
if !exists('g:cursorshape_enabled')
  let g:cursorshape_enabled = 1
endif

if !exists('g:cursorshape_backend')
  let g:cursorshape_backend = 'auto'
endif

if !exists('g:cursorshape_modes')
  let g:cursorshape_modes = {
    \ 'normal': 'block_blink',
    \ 'visual': 'block_blink',
    \ 'cmdline': 'block_blink',
    \ 'insert': 'bar_blink',
    \ 'replace': 'underline_blink',
    \ }
endif

if !exists('g:cursorshape_restore')
  let g:cursorshape_restore = 'default'
endif

if !exists('g:cursorshape_allow_tmux')
  let g:cursorshape_allow_tmux = 0
endif

if !exists('g:cursorshape_debug')
  let g:cursorshape_debug = 0
endif

" Commands
command! -nargs=* CursorShapeEnable call cursorshape#command#enable(<q-args>)
command! -nargs=* CursorShapeDisable call cursorshape#command#disable(<q-args>)
command! -nargs=* CursorShapeToggle call cursorshape#command#toggle(<q-args>)
command! -nargs=* CursorShapeInfo call cursorshape#command#info(<q-args>)
command! -nargs=* CursorShapeTest call cursorshape#command#test(<q-args>)

" Autocommands
augroup cursorshape
  autocmd!
  autocmd VimEnter * if get(g:, 'cursorshape_enabled', 1) | call cursorshape#enable() | endif
augroup END

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo
