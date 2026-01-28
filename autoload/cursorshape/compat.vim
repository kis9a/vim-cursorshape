" autoload/cursorshape/compat.vim
" Compatibility layer for Vim/Neovim differences
" Provides thin abstraction over editor-specific features

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Check if running on Neovim
" @return {number} 1 if Neovim, 0 if Vim
function! cursorshape#compat#is_nvim() abort
  return has('nvim')
endfunction

" Notify user with a message
" @param {string} msg Message to display
" @param {string} level Notification level ('info', 'warn', 'error')
function! cursorshape#compat#notify(msg, level) abort
  if a:level ==# 'error'
    " Use echoerr for errors
    echohl ErrorMsg
    echomsg 'cursorshape: ' . a:msg
    echohl None
  elseif a:level ==# 'warn'
    " Use WarningMsg highlight for warnings
    echohl WarningMsg
    echomsg 'cursorshape: ' . a:msg
    echohl None
  else
    " For info, just use echomsg
    echomsg 'cursorshape: ' . a:msg
  endif
endfunction

" Check if guicursor option is available
" @return {number} 1 if available, 0 otherwise
function! cursorshape#compat#has_guicursor() abort
  return exists('+guicursor')
endfunction

" Check if terminal escape codes for cursor shape are available
" @return {number} 1 if both t_SI and t_EI exist, 0 otherwise
function! cursorshape#compat#has_termcap_si() abort
  return exists('&t_SI') && exists('&t_EI')
endfunction

" Check if ModeChanged autocmd event is supported
" @return {number} 1 if supported, 0 otherwise
function! cursorshape#compat#supports_modechanged() abort
  return exists('##ModeChanged')
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
