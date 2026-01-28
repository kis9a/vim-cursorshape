" test/test_guicursor_merge.vim
" Tests for guicursor merging logic
" Verifies that existing user settings are preserved when applying cursorshape

scriptencoding utf-8

let s:suite = themis#suite('guicursor_merge')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/core.vim
  runtime autoload/cursorshape/internal/guicursor.vim

  " Reset internal state before each test
  call cursorshape#internal#guicursor#reset()

  " Skip tests if guicursor is not available
  if !exists('+guicursor')
    call themis#log('Skipping guicursor merge tests: +guicursor not available')
  endif
endfunction

" Cleanup after each test
function! s:suite.after_each() abort
  " Reset internal state
  call cursorshape#internal#guicursor#reset()
endfunction

" ============================================================================
" Merge Tests - Preserving User Settings
" ============================================================================

" Test: apply preserves unmanaged modes
function! s:suite.test_apply_preserves_unmanaged_modes() abort
  if !exists('+guicursor')
    return
  endif

  " Set guicursor with both managed and unmanaged modes
  " sm (showmatch) is not managed by cursorshape
  let &guicursor = 'n:block-blinkon0,i-ci:ver25,sm:block-blinkwait175'

  " Apply cursorshape modes
  let l:modes = {'normal': 'bar_blink', 'insert': 'underline_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should contain new cursorshape settings
  call s:assert.match(&guicursor, 'n:ver25')
  call s:assert.match(&guicursor, 'i-ci:hor20')

  " Should preserve unmanaged mode (sm)
  call s:assert.match(&guicursor, 'sm:block-blinkwait175')
endfunction

" Test: apply with complex existing settings
function! s:suite.test_apply_with_complex_existing() abort
  if !exists('+guicursor')
    return
  endif

  " Complex existing guicursor with multiple unmanaged modes
  let &guicursor = 'n:block,i-ci:ver25,sm:hor20,a:blinkwait700'

  let l:modes = {'normal': 'underline_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should contain new normal mode
  call s:assert.match(&guicursor, 'n:hor20')

  " Should preserve sm and a modes
  call s:assert.match(&guicursor, 'sm:hor20')
  call s:assert.match(&guicursor, 'a:blinkwait700')
endfunction

" Test: apply with empty existing guicursor
function! s:suite.test_apply_with_empty_existing() abort
  if !exists('+guicursor')
    return
  endif

  " Start with empty guicursor
  let &guicursor = ''

  let l:modes = {'normal': 'block_steady', 'insert': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should contain only cursorshape modes
  call s:assert.match(&guicursor, 'n:block')
  call s:assert.match(&guicursor, 'i-ci:ver25')
endfunction

" Test: apply multiple times preserves unmanaged modes
function! s:suite.test_multiple_apply_preserves_unmanaged() abort
  if !exists('+guicursor')
    return
  endif

  " Set initial guicursor with unmanaged mode
  let &guicursor = 'n:block,sm:hor20-blinkwait100'

  " First apply
  let l:modes1 = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes1, 'default')

  " Verify sm is preserved after first apply
  call s:assert.match(&guicursor, 'sm:hor20-blinkwait100')

  " Second apply with different mode
  let l:modes2 = {'insert': 'underline_steady'}
  call cursorshape#internal#guicursor#apply(l:modes2, 'default')

  " Verify sm is still preserved after second apply
  call s:assert.match(&guicursor, 'sm:hor20-blinkwait100')
endfunction

" Test: restore with startup preserves original including unmanaged modes
function! s:suite.test_restore_preserves_original_unmanaged() abort
  if !exists('+guicursor')
    return
  endif

  " Set complex original guicursor
  let &guicursor = 'n:block-blinkon0,sm:hor20,a:blinkwait500'
  let l:original = &guicursor

  " Apply with startup mode
  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Verify changed
  call s:assert.not_equals(&guicursor, l:original)

  " Restore
  call cursorshape#internal#guicursor#restore('startup')

  " Should restore complete original including unmanaged modes
  call s:assert.equals(&guicursor, l:original)
  call s:assert.match(&guicursor, 'sm:hor20')
  call s:assert.match(&guicursor, 'a:blinkwait500')
endfunction

" Test: managed mode list coverage
function! s:suite.test_managed_modes_removed_correctly() abort
  if !exists('+guicursor')
    return
  endif

  " Set guicursor with various managed mode combinations
  let &guicursor = 'n:block,i-ci:ver25,r-cr:hor20,ve:block,o:hor50'

  " Apply cursorshape (only replaces normal mode)
  let l:modes = {'normal': 'bar_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Normal mode should be replaced
  call s:assert.match(&guicursor, 'n:ver25-blinkon0')

  " Other modes that weren't replaced should still be there
  call s:assert.match(&guicursor, 'i-ci:ver25')
  call s:assert.match(&guicursor, 'r-cr:hor20')
  call s:assert.match(&guicursor, 've:block')
  call s:assert.match(&guicursor, 'o:hor50')
endfunction

" Test: parse_guicursor helper function
" This tests the internal parsing logic indirectly through apply behavior
function! s:suite.test_parse_handles_edge_cases() abort
  if !exists('+guicursor')
    return
  endif

  " Edge case: multiple colons in settings with unmanaged mode
  " sm (showmatch) is unmanaged, so it should be preserved
  " Note: insert maps to i-ci, so both i and ci entries will be removed
  let &guicursor = 'n:block,sm:block-Cursor/lCursor:3000,i:ver25'

  let l:modes = {'insert': 'bar_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should preserve complex sm mode settings (unmanaged, has multiple colons)
  call s:assert.match(&guicursor, 'sm:block-Cursor/lCursor:3000')

  " Should update insert mode (now i-ci instead of just i)
  call s:assert.match(&guicursor, 'i-ci:ver25-blinkon0')
  " Original i:ver25 should be removed (replaced by i-ci)
  call s:assert.not_match(&guicursor, 'i:ver25[^-]')
endfunction
