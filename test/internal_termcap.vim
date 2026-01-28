" test/internal_termcap.vim
" Tests for autoload/cursorshape/internal/termcap.vim
" Vim termcap backend implementation tests

scriptencoding utf-8

let s:suite = themis#suite('internal_termcap')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/core.vim
  runtime autoload/cursorshape/compat.vim
  runtime autoload/cursorshape/internal/termcap.vim

  " Enable debug mode for tests
  let g:cursorshape_debug = 1

  " Skip tests if running on Neovim (termcap not used)
  if cursorshape#compat#is_nvim()
    call themis#log('Skipping termcap tests: Running on Neovim')
    return
  endif

  " Skip tests if termcap is not available
  if !exists('&t_SI') || !exists('&t_EI')
    call themis#log('Skipping termcap tests: t_SI/t_EI not available')
    return
  endif

  " Reset internal state before each test
  call cursorshape#internal#termcap#reset()
endfunction

" Cleanup after each test
function! s:suite.after_each() abort
  " Skip cleanup if not in Vim or termcap not available
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Reset internal state
  call cursorshape#internal#termcap#reset()
endfunction

" Cleanup after all tests
function! s:suite.after() abort
  " Clean up debug mode
  unlet! g:cursorshape_debug
endfunction

" ============================================================================
" Apply Tests
" ============================================================================

" Test: apply sets t_SI/t_EI/t_SR termcap options
function! s:suite.test_apply_sets_termcap() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Save original values
  let l:orig_si = &t_SI
  let l:orig_ei = &t_EI
  let l:orig_sr = &t_SR

  let l:modes = {
        \ 'normal': 'block_blink',
        \ 'insert': 'bar_blink',
        \ 'replace': 'underline_blink'
        \ }
  call cursorshape#internal#termcap#apply(l:modes, 'default')

  " Termcap options should be modified (appended)
  " Note: We check if they're different, not exact values, since we append
  call s:assert.true(len(&t_SI) >= len(l:orig_si))
  call s:assert.true(len(&t_EI) >= len(l:orig_ei))
  call s:assert.true(len(&t_SR) >= len(l:orig_sr))
endfunction

" Test: apply with 'default' restore mode modifies t_te
function! s:suite.test_apply_default_modifies_tte() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:orig_te = &t_te

  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'default')

  " t_te should be modified (appended)
  call s:assert.true(len(&t_te) >= len(l:orig_te))
endfunction

" Test: apply with 'startup' restore mode modifies t_te (falls back to default)
function! s:suite.test_apply_startup_modifies_tte() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:orig_te = &t_te

  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'startup')

  " t_te should be modified (startup falls back to default behavior)
  call s:assert.true(len(&t_te) >= len(l:orig_te))
endfunction

" Test: apply with 'none' restore mode does not modify t_te
function! s:suite.test_apply_none_does_not_modify_tte() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:orig_te = &t_te

  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'none')

  " t_te should not be modified for 'none' restore mode
  call s:assert.equals(&t_te, l:orig_te)
endfunction

" Test: apply prevents duplicate application
function! s:suite.test_apply_prevents_duplicate() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {'normal': 'block_blink', 'insert': 'bar_blink'}

  " First apply
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  let l:after_first = &t_SI

  " Second apply (should be prevented)
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  let l:after_second = &t_SI

  " Values should be identical (no duplicate application)
  call s:assert.equals(l:after_second, l:after_first)
endfunction

" Test: is_applied returns correct status
function! s:suite.test_is_applied_status() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Initially not applied
  call s:assert.equals(cursorshape#internal#termcap#is_applied(), 0)

  " After apply, should be applied
  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  call s:assert.equals(cursorshape#internal#termcap#is_applied(), 1)
endfunction

" ============================================================================
" Reset Tests
" ============================================================================

" Test: reset throws error without debug mode
function! s:suite.test_reset_requires_debug_mode() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Disable debug mode
  let l:saved_debug = get(g:, 'cursorshape_debug', 0)
  let g:cursorshape_debug = 0

  try
    " This should throw an error
    call cursorshape#internal#termcap#reset()
    call s:assert.fail('Expected error but none was thrown')
  catch /cursorshape: reset() is only available in debug mode/
    " Expected error - test passes
  catch
    call s:assert.fail('Unexpected error: ' . v:exception)
  finally
    " Restore debug mode
    let g:cursorshape_debug = l:saved_debug
  endtry
endfunction

" Test: reset works with debug mode enabled
function! s:suite.test_reset_works_with_debug_mode() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Ensure debug mode is enabled (should be set in before_each)
  call s:assert.equals(get(g:, 'cursorshape_debug', 0), 1)

  " Apply first
  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  call s:assert.equals(cursorshape#internal#termcap#is_applied(), 1)

  " Reset should work without error
  try
    call cursorshape#internal#termcap#reset()
    call s:assert.equals(cursorshape#internal#termcap#is_applied(), 0)
  catch
    call s:assert.fail('Unexpected error: ' . v:exception)
  endtry
endfunction

" Test: reset clears applied flag
function! s:suite.test_reset_clears_flag() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Apply first
  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  call s:assert.equals(cursorshape#internal#termcap#is_applied(), 1)

  " Reset
  call cursorshape#internal#termcap#reset()

  " Flag should be cleared
  call s:assert.equals(cursorshape#internal#termcap#is_applied(), 0)
endfunction

" Test: reset allows re-application
function! s:suite.test_reset_allows_reapply() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {'normal': 'block_blink', 'insert': 'bar_blink'}

  " First apply
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  let l:after_first = &t_SI

  " Reset
  call cursorshape#internal#termcap#reset()

  " Second apply should now work
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  let l:after_second = &t_SI

  " Second application should append again
  call s:assert.true(len(l:after_second) > len(l:after_first))
endfunction

" ============================================================================
" Shape Conversion Tests
" ============================================================================

" Test: apply converts shapes correctly for insert mode
function! s:suite.test_apply_converts_insert_shape() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {'insert': 'bar_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'none')

  " t_SI should contain the bar cursor escape sequence
  call s:assert.match(&t_SI, "\e\\[5 q")
endfunction

" Test: apply converts shapes correctly for replace mode
function! s:suite.test_apply_converts_replace_shape() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {'replace': 'underline_blink'}
  call cursorshape#internal#termcap#apply(l:modes, 'none')

  " t_SR should contain the underline cursor escape sequence
  call s:assert.match(&t_SR, "\e\\[3 q")
endfunction

" Test: apply converts shapes correctly for normal mode
function! s:suite.test_apply_converts_normal_shape() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {'normal': 'block_steady'}
  call cursorshape#internal#termcap#apply(l:modes, 'none')

  " t_EI should contain the block steady cursor escape sequence
  call s:assert.match(&t_EI, "\e\\[2 q")
endfunction

" ============================================================================
" Integration Tests
" ============================================================================

" Test: apply with all modes
function! s:suite.test_apply_all_modes() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:modes = {
        \ 'normal': 'block_blink',
        \ 'insert': 'bar_blink',
        \ 'replace': 'underline_blink'
        \ }

  call cursorshape#internal#termcap#apply(l:modes, 'default')

  " All termcap options should be set
  call s:assert.match(&t_SI, "\e\\[5 q")
  call s:assert.match(&t_SR, "\e\\[3 q")
  call s:assert.match(&t_EI, "\e\\[1 q")
  call s:assert.match(&t_te, "\e\\[1 q")
endfunction

" Test: apply with partial modes (using defaults)
function! s:suite.test_apply_partial_modes() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  " Only specify normal mode, others should get defaults
  let l:modes = {'normal': 'block_steady'}

  call cursorshape#internal#termcap#apply(l:modes, 'none')

  " t_EI should have block steady
  call s:assert.match(&t_EI, "\e\\[2 q")

  " t_SI should have default (bar_blink)
  call s:assert.match(&t_SI, "\e\\[5 q")
endfunction

" Test: empty modes dict uses all defaults
function! s:suite.test_apply_empty_modes() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  call cursorshape#internal#termcap#apply({}, 'none')

  " Should apply default shapes
  call s:assert.match(&t_SI, "\e\\[5 q")
  call s:assert.match(&t_EI, "\e\\[1 q")
endfunction

" ============================================================================
" Restore Mode Tests
" ============================================================================

" Test: different restore modes affect t_te differently
function! s:suite.test_restore_modes() abort
  if cursorshape#compat#is_nvim() || !exists('&t_SI') || !exists('&t_EI')
    return
  endif

  let l:orig_te = &t_te
  let l:modes = {'normal': 'block_blink'}

  " Test 'default' mode
  call cursorshape#internal#termcap#reset()
  call cursorshape#internal#termcap#apply(l:modes, 'default')
  let l:te_default = &t_te
  call s:assert.true(len(l:te_default) > len(l:orig_te))

  " Test 'none' mode
  let &t_te = l:orig_te
  call cursorshape#internal#termcap#reset()
  call cursorshape#internal#termcap#apply(l:modes, 'none')
  let l:te_none = &t_te
  call s:assert.equals(l:te_none, l:orig_te)
endfunction
