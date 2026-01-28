" autoload/cursorshape/command.vim
" Command layer - Handles user command argument parsing and delegation to public API
" Provides implementations for :CursorShapeEnable, :CursorShapeDisable, etc.

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Enable cursor shape changes
" Implements :CursorShapeEnable command
" @param {string} args Command arguments (currently unused, reserved for future extensions)
" @note The command accepts -nargs=* for forward compatibility
function! cursorshape#command#enable(args) abort
  let _ = a:args  " Reserved for future extensions
  call cursorshape#enable()
  call cursorshape#compat#notify('cursorshape enabled', 'info')
endfunction

" Disable cursor shape changes
" Implements :CursorShapeDisable command
" @param {string} args Command arguments (currently unused, reserved for future extensions)
" @note The command accepts -nargs=* for forward compatibility
function! cursorshape#command#disable(args) abort
  let _ = a:args  " Reserved for future extensions
  call cursorshape#disable()
  call cursorshape#compat#notify('cursorshape disabled', 'info')
endfunction

" Toggle cursor shape changes on/off
" Implements :CursorShapeToggle command
" @param {string} args Command arguments (currently unused, reserved for future extensions)
" @note The command accepts -nargs=* for forward compatibility
function! cursorshape#command#toggle(args) abort
  let _ = a:args  " Reserved for future extensions
  call cursorshape#toggle()
  let l:status = exists('g:cursorshape_enabled') && g:cursorshape_enabled ? 'enabled' : 'disabled'
  call cursorshape#compat#notify('cursorshape ' . l:status, 'info')
endfunction

" Display comprehensive cursor shape configuration and environment information
" Implements :CursorShapeInfo command
" @param {string} args Command arguments (currently unused, reserved for future extensions)
" @note The command accepts -nargs=* for forward compatibility
function! cursorshape#command#info(args) abort
  let _ = a:args  " Reserved for future extensions

  " Force refresh environment info for accurate display
  call cursorshape#deps#env#reset_cache()

  let l:info = cursorshape#info()

  echo 'cursorshape Information'
  echo '======================='
  echo 'Enabled: ' . (l:info.enabled ? 'yes' : 'no')
  echo 'Backend: ' . l:info.backend
  echo 'Allow tmux: ' . (l:info.allow_tmux ? 'yes' : 'no')
  echo 'Restore: ' . l:info.restore
  echo ''
  echo 'Environment:'
  echo '  Editor: ' . l:info.editor
  echo '  Term: ' . l:info.env.term
  echo '  Is tmux: ' . (l:info.env.is_tmux ? 'yes' : 'no')
  echo '  Is screen: ' . (l:info.env.is_screen ? 'yes' : 'no')
  if !empty(l:info.env.term_program)
    echo '  Term program: ' . l:info.env.term_program
  endif
  echo ''
  echo 'Capabilities:'
  echo '  guicursor: ' . (l:info.capabilities.has_guicursor ? 'yes' : 'no')
  echo '  termcap_si: ' . (l:info.capabilities.has_termcap_si ? 'yes' : 'no')
  echo '  modechanged: ' . (l:info.capabilities.supports_modechanged ? 'yes' : 'no')
  echo ''
  echo 'Modes:'
  for l:mode in sort(keys(l:info.modes))
    echo '  ' . l:mode . ': ' . l:info.modes[l:mode]
  endfor
endfunction

" Test cursor shape changes with current backend
" Implements :CursorShapeTest command
" Provides user-friendly feedback about testing cursor shape functionality
" @param {string} args Command arguments (currently unused, reserved for future extensions)
" @note The command accepts -nargs=* for forward compatibility
function! cursorshape#command#test(args) abort
  let _ = a:args  " Reserved for future extensions
  let l:info = cursorshape#info()

  if l:info.backend ==# 'none'
    call cursorshape#compat#notify('Backend is "none" - nothing to test', 'warn')
    return
  endif

  call cursorshape#compat#notify('Testing cursor shape changes...', 'info')
  call cursorshape#compat#notify('Current backend: ' . l:info.backend, 'info')
  call cursorshape#compat#notify('Try entering Insert mode and returning to Normal mode', 'info')
  call cursorshape#compat#notify('The cursor shape should change accordingly', 'info')
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
