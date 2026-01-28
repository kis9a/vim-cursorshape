" test/core.vim
" Tests for autoload/cursorshape/core.vim
" Core logic layer tests - backend selection and shape conversion

scriptencoding utf-8

let s:suite = themis#suite('core')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  " Load required modules
  runtime autoload/cursorshape/core.vim
  runtime autoload/cursorshape/compat.vim
  runtime autoload/cursorshape/deps/env.vim
endfunction

" ============================================================================
" Backend Selection Tests
" ============================================================================

" Test: select_backend with explicit 'none'
function! s:suite.test_select_backend_explicit_none() abort
  let l:result = cursorshape#core#select_backend('none', {})
  call s:assert.equals(l:result, 'none')
endfunction

" Test: select_backend with explicit 'vim_termcap'
function! s:suite.test_select_backend_explicit_vim_termcap() abort
  let l:result = cursorshape#core#select_backend('vim_termcap', {})
  call s:assert.equals(l:result, 'vim_termcap')
endfunction

" Test: select_backend with explicit 'nvim_guicursor'
function! s:suite.test_select_backend_explicit_nvim_guicursor() abort
  let l:result = cursorshape#core#select_backend('nvim_guicursor', {})
  call s:assert.equals(l:result, 'nvim_guicursor')
endfunction

" Test: select_backend 'auto' on Neovim with guicursor
function! s:suite.test_select_backend_auto_nvim_guicursor() abort
  " Only test if running on Neovim with guicursor support
  if cursorshape#compat#is_nvim() && cursorshape#compat#has_guicursor()
    let l:result = cursorshape#core#select_backend('auto', {'allow_tmux': 1})
    call s:assert.equals(l:result, 'nvim_guicursor')
  endif
endfunction

" Test: select_backend 'auto' on Vim with termcap
function! s:suite.test_select_backend_auto_vim_termcap() abort
  " Only test if running on Vim with t_SI/t_EI support
  if !cursorshape#compat#is_nvim() && cursorshape#compat#has_termcap_si()
    let l:result = cursorshape#core#select_backend('auto', {'allow_tmux': 1})
    call s:assert.equals(l:result, 'vim_termcap')
  endif
endfunction

" Test: select_backend returns 'none' when allow_tmux is disabled and TMUX is set
" Note: This test cannot easily mock environment variables, so we document the behavior
function! s:suite.test_select_backend_tmux_disabled() abort
  " If TMUX is set and allow_tmux is 0, backend should be 'none'
  " This test is skipped in non-tmux environments
  let l:env = cursorshape#deps#env#detect()
  if l:env.is_tmux || l:env.is_screen
    let l:result = cursorshape#core#select_backend('auto', {'allow_tmux': 0})
    call s:assert.equals(l:result, 'none')
  endif
endfunction

" ============================================================================
" Termcap Shape Conversion Tests
" ============================================================================

" Test: shape_to_termcap with block_blink
function! s:suite.test_shape_to_termcap_block_blink() abort
  let l:result = cursorshape#core#shape_to_termcap('block_blink')
  call s:assert.equals(l:result, "\e[1 q")
endfunction

" Test: shape_to_termcap with block_steady
function! s:suite.test_shape_to_termcap_block_steady() abort
  let l:result = cursorshape#core#shape_to_termcap('block_steady')
  call s:assert.equals(l:result, "\e[2 q")
endfunction

" Test: shape_to_termcap with underline_blink
function! s:suite.test_shape_to_termcap_underline_blink() abort
  let l:result = cursorshape#core#shape_to_termcap('underline_blink')
  call s:assert.equals(l:result, "\e[3 q")
endfunction

" Test: shape_to_termcap with underline_steady
function! s:suite.test_shape_to_termcap_underline_steady() abort
  let l:result = cursorshape#core#shape_to_termcap('underline_steady')
  call s:assert.equals(l:result, "\e[4 q")
endfunction

" Test: shape_to_termcap with bar_blink
function! s:suite.test_shape_to_termcap_bar_blink() abort
  let l:result = cursorshape#core#shape_to_termcap('bar_blink')
  call s:assert.equals(l:result, "\e[5 q")
endfunction

" Test: shape_to_termcap with bar_steady
function! s:suite.test_shape_to_termcap_bar_steady() abort
  let l:result = cursorshape#core#shape_to_termcap('bar_steady')
  call s:assert.equals(l:result, "\e[6 q")
endfunction

" Test: shape_to_termcap with unknown shape (should default to block_blink)
function! s:suite.test_shape_to_termcap_unknown() abort
  let l:result = cursorshape#core#shape_to_termcap('unknown_shape')
  call s:assert.equals(l:result, "\e[1 q")
endfunction

" ============================================================================
" Guicursor Shape Conversion Tests
" ============================================================================

" Test: shape_to_guicursor for normal mode with block_blink
function! s:suite.test_shape_to_guicursor_normal_block_blink() abort
  let l:result = cursorshape#core#shape_to_guicursor('normal', 'block_blink')
  call s:assert.match(l:result, '^n:block-blinkwait')
  call s:assert.match(l:result, 'blinkon150')
  call s:assert.match(l:result, 'blinkoff150')
endfunction

" Test: shape_to_guicursor for normal mode with block_steady
function! s:suite.test_shape_to_guicursor_normal_block_steady() abort
  let l:result = cursorshape#core#shape_to_guicursor('normal', 'block_steady')
  call s:assert.match(l:result, '^n:block')
  call s:assert.match(l:result, 'blinkon0')
endfunction

" Test: shape_to_guicursor for insert mode with bar_blink
function! s:suite.test_shape_to_guicursor_insert_bar_blink() abort
  let l:result = cursorshape#core#shape_to_guicursor('insert', 'bar_blink')
  call s:assert.match(l:result, '^i-ci:ver25')
  call s:assert.match(l:result, 'blinkwait')
endfunction

" Test: shape_to_guicursor for insert mode with bar_steady
function! s:suite.test_shape_to_guicursor_insert_bar_steady() abort
  let l:result = cursorshape#core#shape_to_guicursor('insert', 'bar_steady')
  call s:assert.match(l:result, '^i-ci:ver25')
  call s:assert.match(l:result, 'blinkon0')
endfunction

" Test: shape_to_guicursor for replace mode with underline_blink
function! s:suite.test_shape_to_guicursor_replace_underline_blink() abort
  let l:result = cursorshape#core#shape_to_guicursor('replace', 'underline_blink')
  call s:assert.match(l:result, '^r-cr:hor20')
  call s:assert.match(l:result, 'blinkwait')
endfunction

" Test: shape_to_guicursor for replace mode with underline_steady
function! s:suite.test_shape_to_guicursor_replace_underline_steady() abort
  let l:result = cursorshape#core#shape_to_guicursor('replace', 'underline_steady')
  call s:assert.match(l:result, '^r-cr:hor20')
  call s:assert.match(l:result, 'blinkon0')
endfunction

" Test: shape_to_guicursor for visual mode
function! s:suite.test_shape_to_guicursor_visual() abort
  let l:result = cursorshape#core#shape_to_guicursor('visual', 'block_blink')
  call s:assert.match(l:result, '^v:block')
endfunction

" Test: shape_to_guicursor for cmdline mode
function! s:suite.test_shape_to_guicursor_cmdline() abort
  let l:result = cursorshape#core#shape_to_guicursor('cmdline', 'block_blink')
  call s:assert.match(l:result, '^c:block')
endfunction

" Test: shape_to_guicursor for visual_exclusive mode
function! s:suite.test_shape_to_guicursor_visual_exclusive() abort
  let l:result = cursorshape#core#shape_to_guicursor('visual_exclusive', 'block_blink')
  call s:assert.match(l:result, '^ve:block')
endfunction

" Test: shape_to_guicursor for operator mode
function! s:suite.test_shape_to_guicursor_operator() abort
  let l:result = cursorshape#core#shape_to_guicursor('operator', 'block_blink')
  call s:assert.match(l:result, '^o:block')
endfunction

" Test: shape_to_guicursor with unknown mode (should default to n)
function! s:suite.test_shape_to_guicursor_unknown_mode() abort
  let l:result = cursorshape#core#shape_to_guicursor('unknown_mode', 'block_blink')
  call s:assert.match(l:result, '^n:block')
endfunction

" Test: shape_to_guicursor with unknown shape (should default to block)
function! s:suite.test_shape_to_guicursor_unknown_shape() abort
  let l:result = cursorshape#core#shape_to_guicursor('normal', 'unknown_shape')
  call s:assert.match(l:result, '^n:block')
endfunction

" ============================================================================
" Build Info Tests
" ============================================================================

" Test: build_info returns valid dict structure
function! s:suite.test_build_info_structure() abort
  let l:opts = {
        \ 'enabled': 1,
        \ 'backend': 'auto',
        \ 'allow_tmux': 1,
        \ 'restore': 'default',
        \ 'modes': {'normal': 'block_blink', 'insert': 'bar_blink'},
        \ }
  let l:info = cursorshape#core#build_info(l:opts)

  " Verify structure
  call s:assert.is_dict(l:info)
  call s:assert.has_key(l:info, 'enabled')
  call s:assert.has_key(l:info, 'backend')
  call s:assert.has_key(l:info, 'allow_tmux')
  call s:assert.has_key(l:info, 'modes')
  call s:assert.has_key(l:info, 'restore')
  call s:assert.has_key(l:info, 'env')
  call s:assert.has_key(l:info, 'editor')
  call s:assert.has_key(l:info, 'capabilities')
endfunction

" Test: build_info preserves configuration values
function! s:suite.test_build_info_preserves_config() abort
  let l:opts = {
        \ 'enabled': 1,
        \ 'backend': 'vim_termcap',
        \ 'allow_tmux': 0,
        \ 'restore': 'startup',
        \ 'modes': {'normal': 'block_steady'},
        \ }
  let l:info = cursorshape#core#build_info(l:opts)

  call s:assert.equals(l:info.enabled, 1)
  call s:assert.equals(l:info.allow_tmux, 0)
  call s:assert.equals(l:info.restore, 'startup')
  call s:assert.is_dict(l:info.modes)
endfunction

" Test: build_info resolves backend correctly
function! s:suite.test_build_info_resolves_backend() abort
  let l:opts = {
        \ 'enabled': 1,
        \ 'backend': 'auto',
        \ 'allow_tmux': 1,
        \ 'modes': {},
        \ }
  let l:info = cursorshape#core#build_info(l:opts)

  " Backend should be resolved to one of the valid backends
  call s:assert.true(
        \ l:info.backend ==# 'nvim_guicursor' ||
        \ l:info.backend ==# 'vim_termcap' ||
        \ l:info.backend ==# 'none')
endfunction

" Test: build_info includes environment information
function! s:suite.test_build_info_env() abort
  let l:opts = {'enabled': 1, 'backend': 'auto', 'modes': {}}
  let l:info = cursorshape#core#build_info(l:opts)

  call s:assert.is_dict(l:info.env)
  call s:assert.has_key(l:info.env, 'is_tmux')
  call s:assert.has_key(l:info.env, 'is_screen')
  call s:assert.has_key(l:info.env, 'term')
  call s:assert.has_key(l:info.env, 'term_program')
endfunction

" Test: build_info includes editor information
function! s:suite.test_build_info_editor() abort
  let l:opts = {'enabled': 1, 'backend': 'auto', 'modes': {}}
  let l:info = cursorshape#core#build_info(l:opts)

  call s:assert.is_string(l:info.editor)
  call s:assert.true(l:info.editor ==# 'vim' || l:info.editor ==# 'neovim')
endfunction

" Test: build_info includes capability information
function! s:suite.test_build_info_capabilities() abort
  let l:opts = {'enabled': 1, 'backend': 'auto', 'modes': {}}
  let l:info = cursorshape#core#build_info(l:opts)

  call s:assert.is_dict(l:info.capabilities)
  call s:assert.has_key(l:info.capabilities, 'has_guicursor')
  call s:assert.has_key(l:info.capabilities, 'has_termcap_si')
  call s:assert.has_key(l:info.capabilities, 'supports_modechanged')
endfunction

" Test: build_info with empty opts dict
function! s:suite.test_build_info_empty_opts() abort
  let l:info = cursorshape#core#build_info({})

  " Should have defaults
  call s:assert.is_dict(l:info)
  call s:assert.has_key(l:info, 'enabled')
  call s:assert.has_key(l:info, 'backend')
endfunction
