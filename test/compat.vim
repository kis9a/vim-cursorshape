" test/compat.vim
" Tests for autoload/cursorshape/compat.vim
" Compatibility layer tests - Vim/Neovim feature detection

scriptencoding utf-8

let s:suite = themis#suite('compat')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/compat.vim
endfunction

" ============================================================================
" Editor Detection Tests
" ============================================================================

" Test: is_nvim returns boolean
function! s:suite.test_is_nvim_returns_boolean() abort
  let l:result = cursorshape#compat#is_nvim()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: is_nvim matches has('nvim')
function! s:suite.test_is_nvim_matches_has_nvim() abort
  let l:result = cursorshape#compat#is_nvim()
  let l:expected = has('nvim')
  call s:assert.equals(l:result, l:expected)
endfunction

" ============================================================================
" Capability Detection Tests
" ============================================================================

" Test: has_guicursor returns boolean
function! s:suite.test_has_guicursor_returns_boolean() abort
  let l:result = cursorshape#compat#has_guicursor()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: has_guicursor matches exists('+guicursor')
function! s:suite.test_has_guicursor_matches_exists() abort
  let l:result = cursorshape#compat#has_guicursor()
  let l:expected = exists('+guicursor')
  call s:assert.equals(l:result, l:expected)
endfunction

" Test: has_termcap_si returns boolean
function! s:suite.test_has_termcap_si_returns_boolean() abort
  let l:result = cursorshape#compat#has_termcap_si()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: has_termcap_si matches exists('&t_SI') && exists('&t_EI')
function! s:suite.test_has_termcap_si_matches_exists() abort
  let l:result = cursorshape#compat#has_termcap_si()
  let l:expected = exists('&t_SI') && exists('&t_EI')
  call s:assert.equals(l:result, l:expected)
endfunction

" Test: supports_modechanged returns boolean
function! s:suite.test_supports_modechanged_returns_boolean() abort
  let l:result = cursorshape#compat#supports_modechanged()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: supports_modechanged matches exists('##ModeChanged')
function! s:suite.test_supports_modechanged_matches_exists() abort
  let l:result = cursorshape#compat#supports_modechanged()
  let l:expected = exists('##ModeChanged')
  call s:assert.equals(l:result, l:expected)
endfunction

" ============================================================================
" Notification Tests
" ============================================================================

" Test: notify with info level does not throw error
function! s:suite.test_notify_info_no_error() abort
  " Should not throw an error
  call cursorshape#compat#notify('test info message', 'info')
  " If we reach here, no exception was thrown
  call s:assert.true(1)
endfunction

" Test: notify with warn level does not throw error
function! s:suite.test_notify_warn_no_error() abort
  " Should not throw an error
  call cursorshape#compat#notify('test warn message', 'warn')
  call s:assert.true(1)
endfunction

" Test: notify with error level does not throw error
function! s:suite.test_notify_error_no_error() abort
  " Should not throw an error
  call cursorshape#compat#notify('test error message', 'error')
  call s:assert.true(1)
endfunction

" Test: notify with unknown level does not throw error (defaults to info)
function! s:suite.test_notify_unknown_level_no_error() abort
  " Should default to info behavior
  call cursorshape#compat#notify('test message', 'unknown_level')
  call s:assert.true(1)
endfunction

" ============================================================================
" Integration Tests
" ============================================================================

" Test: Neovim should have guicursor
function! s:suite.test_nvim_has_guicursor() abort
  if cursorshape#compat#is_nvim()
    " Neovim should always have guicursor support
    call s:assert.true(cursorshape#compat#has_guicursor())
  endif
endfunction

" Test: Vim may have termcap support (environment-dependent)
function! s:suite.test_vim_termcap_support() abort
  if !cursorshape#compat#is_nvim()
    " Just verify the function returns a valid boolean
    " Actual support depends on terminal capabilities
    let l:result = cursorshape#compat#has_termcap_si()
    call s:assert.is_number(l:result)
  endif
endfunction

" Test: Editor type consistency
function! s:suite.test_editor_type_consistency() abort
  let l:is_nvim = cursorshape#compat#is_nvim()
  let l:has_nvim = has('nvim')

  " is_nvim() should always match has('nvim')
  call s:assert.equals(l:is_nvim, l:has_nvim)
endfunction
