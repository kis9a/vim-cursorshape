" autoload/cursorshape/deps/env.vim
" Environment detection layer (deps layer)
" Handles external dependencies (environment variables, terminal type)

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Cache variable for environment information
let s:env_cache = {}

" Reset environment cache (useful for tests and forced refresh)
" @public
function! cursorshape#deps#env#reset_cache() abort
  let s:env_cache = {}
endfunction

" Detect and return environment information
" @param {dict} opts Optional options: {'force': 1} to bypass cache
" @return {dict} Environment information
"   {
"     'is_tmux': 0/1,
"     'is_screen': 0/1,
"     'term': 'xterm-256color',
"     'term_program': 'iTerm.app'
"   }
function! cursorshape#deps#env#detect(...) abort
  let l:opts = get(a:, 1, {})
  let l:force = get(l:opts, 'force', 0)

  " Return cached result if available and not forcing refresh
  if !empty(s:env_cache) && !l:force
    return s:env_cache
  endif

  " Collect environment information
  let l:info = {}

  " Detect tmux
  let l:info.is_tmux = exists('$TMUX') && !empty($TMUX) ? 1 : 0

  " Detect screen
  let l:info.is_screen = exists('$STY') && !empty($STY) ? 1 : 0

  " Terminal type
  let l:info.term = &term

  " Terminal program (if available)
  let l:info.term_program = exists('$TERM_PROGRAM') ? $TERM_PROGRAM : ''

  " Save to cache
  let s:env_cache = l:info
  return l:info
endfunction

" Check if running inside tmux
" @return {number} 1 if inside tmux, 0 otherwise
function! cursorshape#deps#env#is_tmux() abort
  let l:env = cursorshape#deps#env#detect()
  return l:env.is_tmux
endfunction

" Check if running inside screen
" @return {number} 1 if inside screen, 0 otherwise
function! cursorshape#deps#env#is_screen() abort
  let l:env = cursorshape#deps#env#detect()
  return l:env.is_screen
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
