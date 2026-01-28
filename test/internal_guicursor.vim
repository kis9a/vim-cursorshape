" test/internal_guicursor.vim
" Tests for autoload/cursorshape/internal/guicursor.vim
" Neovim guicursor backend implementation tests

scriptencoding utf-8

let s:suite = themis#suite('internal_guicursor')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/core.vim
  runtime autoload/cursorshape/internal/guicursor.vim

  " Reset internal state before each test
  call cursorshape#internal#guicursor#reset()

  " Skip tests if guicursor is not available
  if !exists('+guicursor')
    call themis#log('Skipping guicursor tests: +guicursor not available')
  endif
endfunction

" Cleanup after each test
function! s:suite.after_each() abort
  " Reset internal state
  call cursorshape#internal#guicursor#reset()
endfunction

" ============================================================================
" Apply Tests
" ============================================================================

" Test: apply modifies &guicursor
function! s:suite.test_apply_modifies_guicursor() abort
  if !exists('+guicursor')
    return
  endif

  let l:original = &guicursor
  let l:modes = {'normal': 'block_blink', 'insert': 'bar_blink'}

  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " guicursor should be changed
  call s:assert.not_equals(&guicursor, l:original)
endfunction

" Test: apply with single mode
function! s:suite.test_apply_single_mode() abort
  if !exists('+guicursor')
    return
  endif

  let l:modes = {'normal': 'block_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should contain normal mode configuration (n: not n-v-c:)
  call s:assert.match(&guicursor, 'n:block')
  call s:assert.match(&guicursor, 'blinkon0')
endfunction

" Test: apply with multiple modes
function! s:suite.test_apply_multiple_modes() abort
  if !exists('+guicursor')
    return
  endif

  let l:modes = {
        \ 'normal': 'block_steady',
        \ 'insert': 'bar_blink',
        \ 'replace': 'underline_steady'
        \ }
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Should contain all mode configurations
  call s:assert.match(&guicursor, 'n:block')
  call s:assert.match(&guicursor, 'i-ci:ver25')
  call s:assert.match(&guicursor, 'r-cr:hor20')
endfunction

" Test: apply with 'startup' restore mode saves original guicursor
function! s:suite.test_apply_startup_saves_original() abort
  if !exists('+guicursor')
    return
  endif

  " Set a known guicursor value
  let &guicursor = 'a:block-blinkon0'
  let l:original = &guicursor

  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Now restore with 'startup' mode
  call cursorshape#internal#guicursor#restore('startup')

  " Should be restored to original
  call s:assert.equals(&guicursor, l:original)
endfunction

" ============================================================================
" Restore Tests
" ============================================================================

" Test: restore with 'default' sets safe default
function! s:suite.test_restore_default() abort
  if !exists('+guicursor')
    return
  endif

  " Apply some cursor shapes first
  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Now restore with 'default'
  call cursorshape#internal#guicursor#restore('default')

  " Should be set to safe default
  call s:assert.equals(&guicursor, 'a:block-blinkon0')
endfunction

" Test: restore with 'startup' restores original value
function! s:suite.test_restore_startup() abort
  if !exists('+guicursor')
    return
  endif

  " Set a known guicursor value
  let &guicursor = 'a:hor20-blinkon0'
  let l:original = &guicursor

  " Apply with 'startup' mode (this saves the original)
  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Restore with 'startup'
  call cursorshape#internal#guicursor#restore('startup')

  " Should be restored to original
  call s:assert.equals(&guicursor, l:original)
endfunction

" Test: restore with 'none' does nothing
function! s:suite.test_restore_none() abort
  if !exists('+guicursor')
    return
  endif

  " Apply cursor shapes
  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'none')

  let l:after_apply = &guicursor

  " Restore with 'none'
  call cursorshape#internal#guicursor#restore('none')

  " Should remain unchanged
  call s:assert.equals(&guicursor, l:after_apply)
endfunction

" Test: restore without prior apply (startup mode, no saved value)
function! s:suite.test_restore_startup_without_saved() abort
  if !exists('+guicursor')
    return
  endif

  " Reset to ensure no saved value
  call cursorshape#internal#guicursor#reset()

  let l:before = &guicursor

  " Restore with 'startup' mode without saving anything
  call cursorshape#internal#guicursor#restore('startup')

  " Should remain unchanged (no saved value to restore)
  call s:assert.equals(&guicursor, l:before)
endfunction

" ============================================================================
" Reset Tests
" ============================================================================

" Test: reset clears internal state
function! s:suite.test_reset_clears_state() abort
  if !exists('+guicursor')
    return
  endif

  " Apply with startup mode to save original
  let &guicursor = 'a:block-blinkon0'
  let l:modes = {'normal': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Reset
  call cursorshape#internal#guicursor#reset()

  " Now restore with startup should not restore (no saved value)
  let l:before = &guicursor
  call cursorshape#internal#guicursor#restore('startup')
  call s:assert.equals(&guicursor, l:before)
endfunction

" Test: reset allows re-saving original guicursor
function! s:suite.test_reset_allows_resave() abort
  if !exists('+guicursor')
    return
  endif

  " First apply with startup
  let &guicursor = 'a:block-blinkon0'
  call cursorshape#internal#guicursor#apply({'normal': 'bar_blink'}, 'startup')

  " Reset
  call cursorshape#internal#guicursor#reset()

  " Apply again with different original
  let &guicursor = 'a:hor20-blinkon0'
  let l:second_original = &guicursor
  call cursorshape#internal#guicursor#apply({'normal': 'block_blink'}, 'startup')

  " Restore should restore to second original
  call cursorshape#internal#guicursor#restore('startup')
  call s:assert.equals(&guicursor, l:second_original)
endfunction

" ============================================================================
" Integration Tests
" ============================================================================

" Test: full cycle - apply and restore
function! s:suite.test_full_cycle() abort
  if !exists('+guicursor')
    return
  endif

  let &guicursor = 'a:block-blinkon0'
  let l:original = &guicursor

  " Apply
  let l:modes = {'normal': 'bar_blink', 'insert': 'underline_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Verify applied
  call s:assert.not_equals(&guicursor, l:original)

  " Restore
  call cursorshape#internal#guicursor#restore('startup')

  " Should be back to original
  call s:assert.equals(&guicursor, l:original)
endfunction

" Test: multiple apply calls with startup mode (should only save first original)
function! s:suite.test_multiple_apply_startup() abort
  if !exists('+guicursor')
    return
  endif

  let &guicursor = 'a:block-blinkon0'
  let l:original = &guicursor

  " First apply
  call cursorshape#internal#guicursor#apply({'normal': 'bar_blink'}, 'startup')

  " Second apply (should not overwrite saved original)
  call cursorshape#internal#guicursor#apply({'normal': 'underline_blink'}, 'startup')

  " Restore should restore to first original
  call cursorshape#internal#guicursor#restore('startup')
  call s:assert.equals(&guicursor, l:original)
endfunction

" Test: empty modes dict with merge logic
function! s:suite.test_apply_empty_modes() abort
  if !exists('+guicursor')
    return
  endif

  " Set an existing guicursor with both managed and unmanaged modes
  let &guicursor = 'n:block,sm:hor20-blinkon0'

  " Apply with empty modes (cursorshape applies nothing)
  call cursorshape#internal#guicursor#apply({}, 'default')

  " With merge logic: when applying empty dict, existing settings preserved
  " sm (unmanaged) should remain, n (managed but not being replaced) remains too
  call s:assert.match(&guicursor, 'sm:hor20-blinkon0')
  call s:assert.match(&guicursor, 'n:block')
endfunction
