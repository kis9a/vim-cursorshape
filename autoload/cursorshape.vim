" autoload/cursorshape.vim
" Public API layer - User-facing functions for cursor shape control
" Aggregates core and internal implementations to provide unified interface

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" ============================================================================
" Internal Helpers
" ============================================================================

" Get mode configuration with default values
" @return {dict} Mode-to-shape mapping with defaults
"   {
"     'normal': 'block_blink',
"     'insert': 'bar_blink',
"     'replace': 'underline_blink'
"   }
function! s:get_modes_config() abort
  let l:default_modes = {
        \ 'normal': 'block_blink',
        \ 'visual': 'block_blink',
        \ 'cmdline': 'block_blink',
        \ 'insert': 'bar_blink',
        \ 'replace': 'underline_blink',
        \ }

  if exists('g:cursorshape_modes')
    return extend(copy(l:default_modes), g:cursorshape_modes)
  else
    return l:default_modes
  endif
endfunction

" ============================================================================
" Public API Functions
" ============================================================================

" Enable cursor shape control
" Reads configuration from global variables and applies cursor shapes
" using the appropriate backend.
"
" @usage
"   :call cursorshape#enable()
"
" Global variables read:
"   g:cursorshape_enabled       - Set to 1 on success
"   g:cursorshape_modes         - Mode-to-shape mapping (optional)
"   g:cursorshape_restore       - Restore policy ('default', 'startup', 'none')
"   g:cursorshape_allow_tmux    - Allow operation in tmux/screen (0 or 1)
"   g:cursorshape_backend       - Backend preference ('auto', 'vim_termcap', 'nvim_guicursor', 'none')
function! cursorshape#enable() abort
  " Set enabled flag
  let g:cursorshape_enabled = 1

  " Collect configuration settings
  let l:modes = s:get_modes_config()
  let l:restore = get(g:, 'cursorshape_restore', 'default')
  let l:allow_tmux = get(g:, 'cursorshape_allow_tmux', 0)
  let l:backend_pref = get(g:, 'cursorshape_backend', 'auto')

  " Select appropriate backend
  let l:opts = {'allow_tmux': l:allow_tmux}
  let l:backend = cursorshape#core#select_backend(l:backend_pref, l:opts)

  " Apply cursor shapes based on backend
  if l:backend ==# 'nvim_guicursor'
    call cursorshape#internal#guicursor#apply(l:modes, l:restore)
  elseif l:backend ==# 'vim_termcap'
    call cursorshape#internal#termcap#apply(l:modes, l:restore)
  elseif l:backend ==# 'none'
    " Backend is 'none' - likely due to unsupported environment (tmux/screen)
    " or no available backend
    call cursorshape#compat#notify('Cursor shape control is not available in this environment', 'warn')
  endif
endfunction

" Disable cursor shape control
" Attempts to restore cursor shapes to their original state based on
" the restore policy. Note that vim_termcap backend cannot be fully
" disabled without restarting Vim.
"
" @usage
"   :call cursorshape#disable()
"
" Global variables read:
"   g:cursorshape_enabled       - Set to 0
"   g:cursorshape_restore       - Restore policy
"   g:cursorshape_allow_tmux    - Allow operation in tmux/screen
"   g:cursorshape_backend       - Backend preference
function! cursorshape#disable() abort
  " Set enabled flag to disabled
  let g:cursorshape_enabled = 0

  " Get configuration for backend selection
  let l:restore = get(g:, 'cursorshape_restore', 'default')
  let l:backend_pref = get(g:, 'cursorshape_backend', 'auto')
  let l:allow_tmux = get(g:, 'cursorshape_allow_tmux', 0)

  " Select backend to determine restore behavior
  let l:opts = {'allow_tmux': l:allow_tmux}
  let l:backend = cursorshape#core#select_backend(l:backend_pref, l:opts)

  " Restore cursor shapes based on backend
  if l:backend ==# 'nvim_guicursor'
    call cursorshape#internal#guicursor#restore(l:restore)
  elseif l:backend ==# 'vim_termcap'
    " vim_termcap backend cannot be fully disabled after t_SI/t_EI are set
    " A Vim restart is required to fully reset the termcap state
    call cursorshape#compat#notify('vim_termcap backend cannot be fully disabled (restart Vim)', 'warn')
  endif
  " For 'none' backend, do nothing
endfunction

" Toggle cursor shape control on/off
" Enables if currently disabled, disables if currently enabled.
"
" @usage
"   :call cursorshape#toggle()
"   nnoremap <Leader>ct :call cursorshape#toggle()<CR>
function! cursorshape#toggle() abort
  if get(g:, 'cursorshape_enabled', 1)
    call cursorshape#disable()
  else
    call cursorshape#enable()
  endif
endfunction

" Get comprehensive information about current configuration and environment
" Returns a dictionary containing all relevant settings and capabilities.
" Useful for debugging and for the :CursorShapeInfo command.
"
" @return {dict} Information dictionary
"   {
"     'enabled': 0/1,
"     'backend': 'nvim_guicursor',
"     'allow_tmux': 0/1,
"     'modes': {...},
"     'restore': 'default',
"     'env': {...},
"     'editor': 'neovim' or 'vim',
"     'capabilities': {...}
"   }
"
" @usage
"   :echo cursorshape#info()
"   :CursorShapeInfo
function! cursorshape#info() abort
  " Collect current configuration
  let l:modes = s:get_modes_config()
  let l:opts = {
        \ 'enabled': get(g:, 'cursorshape_enabled', 1),
        \ 'backend': get(g:, 'cursorshape_backend', 'auto'),
        \ 'allow_tmux': get(g:, 'cursorshape_allow_tmux', 0),
        \ 'restore': get(g:, 'cursorshape_restore', 'default'),
        \ 'modes': l:modes,
        \ }

  " Build comprehensive information using core layer
  return cursorshape#core#build_info(l:opts)
endfunction

" Force re-apply current cursor shape settings
" Useful for manually refreshing cursor shapes if they become incorrect,
" or after changing configuration variables at runtime.
"
" @usage
"   :call cursorshape#apply()
"
" Note: This is equivalent to calling cursorshape#enable() when already enabled
function! cursorshape#apply() abort
  if get(g:, 'cursorshape_enabled', 1)
    call cursorshape#enable()
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
