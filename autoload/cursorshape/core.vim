" autoload/cursorshape/core.vim
" Core logic layer - Pure business logic without side effects
" Handles backend selection and shape conversion

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Select appropriate backend based on preferences and environment
" @param {string} backend_pref Backend preference ('auto', 'vim_termcap', 'nvim_guicursor', 'none')
" @param {dict} opts Options dict (e.g., {'allow_tmux': 0})
" @return {string} Actual backend name ('vim_termcap', 'nvim_guicursor', 'none')
function! cursorshape#core#select_backend(backend_pref, opts) abort
  " If explicitly specified, return as-is
  if a:backend_pref !=# 'auto'
    return a:backend_pref
  endif

  " Detect environment
  let l:env = cursorshape#deps#env#detect()

  " If in tmux/screen and allow_tmux is disabled, return 'none'
  if (l:env.is_tmux || l:env.is_screen) && !get(a:opts, 'allow_tmux', 0)
    return 'none'
  endif

  " Neovim with guicursor support
  if cursorshape#compat#is_nvim() && cursorshape#compat#has_guicursor()
    return 'nvim_guicursor'
  endif

  " Vim with t_SI/t_EI termcap support
  if !cursorshape#compat#is_nvim() && cursorshape#compat#has_termcap_si()
    return 'vim_termcap'
  endif

  " No supported backend available
  return 'none'
endfunction

" Convert abstract shape to Vim termcap escape sequence
" @param {string} shape Abstract shape name
"   ('block_blink', 'block_steady', 'bar_blink', 'bar_steady', 'underline_blink', 'underline_steady')
" @return {string} Escape sequence string (DECSCUSR format)
"
" DECSCUSR reference:
"   \e[0 q : default (usually blinking block)
"   \e[1 q : blinking block
"   \e[2 q : steady block
"   \e[3 q : blinking underline
"   \e[4 q : steady underline
"   \e[5 q : blinking bar (vertical)
"   \e[6 q : steady bar
function! cursorshape#core#shape_to_termcap(shape) abort
  let l:map = {
        \ 'block_blink': "\e[1 q",
        \ 'block_steady': "\e[2 q",
        \ 'underline_blink': "\e[3 q",
        \ 'underline_steady': "\e[4 q",
        \ 'bar_blink': "\e[5 q",
        \ 'bar_steady': "\e[6 q",
        \ }
  " Default to blinking block if shape is unknown
  return get(l:map, a:shape, "\e[1 q")
endfunction

" Convert abstract shape to Neovim guicursor representation
" @param {string} mode Mode name ('normal', 'visual', 'cmdline', 'insert', 'replace', 'operator', 'visual_exclusive')
" @param {string} shape Abstract shape name
" @return {string} guicursor partial string (e.g., 'n:block', 'v:block', 'i-ci:ver25-blinkon200')
"
" guicursor format: mode-list:shape-blink
"   mode: n, v, c, i, ci, r, cr, o, ve, sm
"   shape: block, ver{N}, hor{N}
"   blink: blinkon{N}, blinkoff{N}, blinkon0 (no blink)
"
" Note: Each mode is mapped individually to allow separate configuration
function! cursorshape#core#shape_to_guicursor(mode, shape) abort
  " Map mode to guicursor mode prefix (single mode mapping)
  let l:mode_map = {
        \ 'normal': 'n',
        \ 'visual': 'v',
        \ 'cmdline': 'c',
        \ 'insert': 'i-ci',
        \ 'replace': 'r-cr',
        \ 'operator': 'o',
        \ 'visual_exclusive': 've',
        \ }
  let l:mode_prefix = get(l:mode_map, a:mode, 'n')

  " Convert shape to guicursor shape
  let l:shape_part = ''
  if a:shape =~# '^block'
    let l:shape_part = 'block'
  elseif a:shape =~# '^bar'
    let l:shape_part = 'ver25'
  elseif a:shape =~# '^underline'
    let l:shape_part = 'hor20'
  else
    " Default to block
    let l:shape_part = 'block'
  endif

  " Determine blink settings
  let l:blink_part = ''
  if a:shape =~# '_blink$'
    let l:blink_part = '-blinkwait200-blinkon150-blinkoff150'
  else
    " No blink (steady)
    let l:blink_part = '-blinkon0'
  endif

  return l:mode_prefix . ':' . l:shape_part . l:blink_part
endfunction

" Build comprehensive information about current configuration and environment
" @param {dict} opts Current configuration dict
"   {
"     'enabled': 0/1,
"     'backend': 'auto',
"     'allow_tmux': 0/1,
"     'modes': {...},
"     'restore': 'default'/'none'
"   }
" @return {dict} Information dict for :CursorShapeInfo command
"   {
"     'enabled': 0/1,
"     'backend': 'nvim_guicursor',
"     'allow_tmux': 0/1,
"     'modes': {...},
"     'restore': 'default',
"     'env': {...}
"   }
function! cursorshape#core#build_info(opts) abort
  let l:info = {}

  " Copy configuration values
  let l:info.enabled = get(a:opts, 'enabled', 0)
  let l:info.allow_tmux = get(a:opts, 'allow_tmux', 0)
  let l:info.modes = get(a:opts, 'modes', {})
  let l:info.restore = get(a:opts, 'restore', 'default')

  " Resolve actual backend
  let l:backend_pref = get(a:opts, 'backend', 'auto')
  let l:info.backend = cursorshape#core#select_backend(l:backend_pref, a:opts)

  " Add environment information
  let l:info.env = cursorshape#deps#env#detect()

  " Add editor information
  let l:info.editor = cursorshape#compat#is_nvim() ? 'neovim' : 'vim'

  " Add capability information
  let l:info.capabilities = {
        \ 'has_guicursor': cursorshape#compat#has_guicursor(),
        \ 'has_termcap_si': cursorshape#compat#has_termcap_si(),
        \ 'supports_modechanged': cursorshape#compat#supports_modechanged(),
        \ }

  return l:info
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
