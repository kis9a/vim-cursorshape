" test/deps_env.vim
" Tests for autoload/cursorshape/deps/env.vim
" Environment detection layer tests

scriptencoding utf-8

let s:suite = themis#suite('deps_env')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/deps/env.vim
  " Reset cache before each test for accurate results
  call cursorshape#deps#env#reset_cache()
endfunction

" ============================================================================
" Environment Detection Tests
" ============================================================================

" Test: detect returns valid dict structure
function! s:suite.test_detect_returns_dict() abort
  let l:env = cursorshape#deps#env#detect()
  call s:assert.is_dict(l:env)
endfunction

" Test: detect includes all required keys
function! s:suite.test_detect_has_required_keys() abort
  let l:env = cursorshape#deps#env#detect()

  call s:assert.has_key(l:env, 'is_tmux')
  call s:assert.has_key(l:env, 'is_screen')
  call s:assert.has_key(l:env, 'term')
  call s:assert.has_key(l:env, 'term_program')
endfunction

" Test: detect returns correct types for all fields
function! s:suite.test_detect_field_types() abort
  let l:env = cursorshape#deps#env#detect()

  call s:assert.is_number(l:env.is_tmux)
  call s:assert.is_number(l:env.is_screen)
  call s:assert.is_string(l:env.term)
  call s:assert.is_string(l:env.term_program)
endfunction

" Test: detect returns boolean values for is_tmux
function! s:suite.test_detect_is_tmux_boolean() abort
  let l:env = cursorshape#deps#env#detect()
  call s:assert.true(l:env.is_tmux == 0 || l:env.is_tmux == 1)
endfunction

" Test: detect returns boolean values for is_screen
function! s:suite.test_detect_is_screen_boolean() abort
  let l:env = cursorshape#deps#env#detect()
  call s:assert.true(l:env.is_screen == 0 || l:env.is_screen == 1)
endfunction

" Test: detect term matches &term
function! s:suite.test_detect_term_matches() abort
  let l:env = cursorshape#deps#env#detect()
  call s:assert.equals(l:env.term, &term)
endfunction

" Test: detect term_program matches $TERM_PROGRAM or empty
function! s:suite.test_detect_term_program() abort
  let l:env = cursorshape#deps#env#detect()
  let l:expected = exists('$TERM_PROGRAM') ? $TERM_PROGRAM : ''
  call s:assert.equals(l:env.term_program, l:expected)
endfunction

" ============================================================================
" Tmux Detection Tests
" ============================================================================

" Test: is_tmux returns boolean
function! s:suite.test_is_tmux_returns_boolean() abort
  let l:result = cursorshape#deps#env#is_tmux()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: is_tmux matches environment detection
function! s:suite.test_is_tmux_matches_detect() abort
  let l:result = cursorshape#deps#env#is_tmux()
  let l:env = cursorshape#deps#env#detect()
  call s:assert.equals(l:result, l:env.is_tmux)
endfunction

" Test: is_tmux matches $TMUX environment variable
function! s:suite.test_is_tmux_matches_env_var() abort
  let l:result = cursorshape#deps#env#is_tmux()
  let l:expected = (exists('$TMUX') && !empty($TMUX)) ? 1 : 0
  call s:assert.equals(l:result, l:expected)
endfunction

" ============================================================================
" Screen Detection Tests
" ============================================================================

" Test: is_screen returns boolean
function! s:suite.test_is_screen_returns_boolean() abort
  let l:result = cursorshape#deps#env#is_screen()
  call s:assert.is_number(l:result)
  call s:assert.true(l:result == 0 || l:result == 1)
endfunction

" Test: is_screen matches environment detection
function! s:suite.test_is_screen_matches_detect() abort
  let l:result = cursorshape#deps#env#is_screen()
  let l:env = cursorshape#deps#env#detect()
  call s:assert.equals(l:result, l:env.is_screen)
endfunction

" Test: is_screen matches $STY environment variable
function! s:suite.test_is_screen_matches_env_var() abort
  let l:result = cursorshape#deps#env#is_screen()
  let l:expected = (exists('$STY') && !empty($STY)) ? 1 : 0
  call s:assert.equals(l:result, l:expected)
endfunction

" ============================================================================
" Caching Tests
" ============================================================================

" Test: detect returns same result on multiple calls (caching)
function! s:suite.test_detect_caching() abort
  let l:env1 = cursorshape#deps#env#detect()
  let l:env2 = cursorshape#deps#env#detect()

  " Should return identical results
  call s:assert.equals(l:env1.is_tmux, l:env2.is_tmux)
  call s:assert.equals(l:env1.is_screen, l:env2.is_screen)
  call s:assert.equals(l:env1.term, l:env2.term)
  call s:assert.equals(l:env1.term_program, l:env2.term_program)
endfunction

" ============================================================================
" Integration Tests
" ============================================================================

" Test: is_tmux and is_screen are mutually exclusive in typical setups
function! s:suite.test_tmux_screen_mutual_exclusion() abort
  let l:is_tmux = cursorshape#deps#env#is_tmux()
  let l:is_screen = cursorshape#deps#env#is_screen()

  " In typical setups, you're either in tmux OR screen, not both
  " However, this is not strictly enforced, so we just verify they're booleans
  call s:assert.is_number(l:is_tmux)
  call s:assert.is_number(l:is_screen)
endfunction

" Test: term is a string (may be empty in -u NONE environment)
function! s:suite.test_term_is_string() abort
  let l:env = cursorshape#deps#env#detect()
  " &term should be a string (may be empty when running with -u NONE)
  call s:assert.is_string(l:env.term)
endfunction

" Test: detect consistency across multiple calls
function! s:suite.test_detect_consistency() abort
  " Call detect multiple times and verify consistency
  let l:results = []
  for l:i in range(5)
    call add(l:results, cursorshape#deps#env#detect())
  endfor

  " All results should be identical
  for l:i in range(1, 4)
    call s:assert.equals(l:results[0].is_tmux, l:results[l:i].is_tmux)
    call s:assert.equals(l:results[0].is_screen, l:results[l:i].is_screen)
    call s:assert.equals(l:results[0].term, l:results[l:i].term)
    call s:assert.equals(l:results[0].term_program, l:results[l:i].term_program)
  endfor
endfunction

" ============================================================================
" Cache Reset Tests
" ============================================================================

" Test: reset_cache clears the cache
function! s:suite.test_reset_cache() abort
  " First call populates cache
  let l:env1 = cursorshape#deps#env#detect()
  call s:assert.has_key(l:env1, 'is_tmux')

  " Reset cache
  call cursorshape#deps#env#reset_cache()

  " Second call should re-populate (we can verify by checking it returns something)
  let l:env2 = cursorshape#deps#env#detect()

  " Both should have the same structure
  call s:assert.has_key(l:env2, 'is_tmux')
  call s:assert.has_key(l:env2, 'is_screen')
  call s:assert.has_key(l:env2, 'term')
  call s:assert.has_key(l:env2, 'term_program')

  " Values should be identical (since environment hasn't changed)
  call s:assert.equals(l:env1.is_tmux, l:env2.is_tmux)
  call s:assert.equals(l:env1.is_screen, l:env2.is_screen)
  call s:assert.equals(l:env1.term, l:env2.term)
  call s:assert.equals(l:env1.term_program, l:env2.term_program)
endfunction

" Test: force option bypasses cache
function! s:suite.test_detect_force_option() abort
  " First call populates cache
  let l:env1 = cursorshape#deps#env#detect()

  " Second call with force=1 should bypass cache
  let l:env2 = cursorshape#deps#env#detect({'force': 1})

  " Both should have the same keys
  call s:assert.has_key(l:env2, 'is_tmux')
  call s:assert.has_key(l:env2, 'is_screen')
  call s:assert.has_key(l:env2, 'term')
  call s:assert.has_key(l:env2, 'term_program')

  " Values should be identical (since environment hasn't changed)
  call s:assert.equals(l:env1.is_tmux, l:env2.is_tmux)
  call s:assert.equals(l:env1.is_screen, l:env2.is_screen)
  call s:assert.equals(l:env1.term, l:env2.term)
  call s:assert.equals(l:env1.term_program, l:env2.term_program)
endfunction

" Test: force option with force=0 uses cache
function! s:suite.test_detect_force_false_uses_cache() abort
  " First call populates cache
  let l:env1 = cursorshape#deps#env#detect()

  " Second call with force=0 (explicit) should use cache
  let l:env2 = cursorshape#deps#env#detect({'force': 0})

  " Should return cached result
  call s:assert.equals(l:env1.is_tmux, l:env2.is_tmux)
  call s:assert.equals(l:env1.is_screen, l:env2.is_screen)
  call s:assert.equals(l:env1.term, l:env2.term)
  call s:assert.equals(l:env1.term_program, l:env2.term_program)
endfunction

" Test: empty options dict uses cache
function! s:suite.test_detect_empty_opts_uses_cache() abort
  " First call populates cache
  let l:env1 = cursorshape#deps#env#detect()

  " Second call with empty options dict should use cache
  let l:env2 = cursorshape#deps#env#detect({})

  " Should return cached result
  call s:assert.equals(l:env1.is_tmux, l:env2.is_tmux)
  call s:assert.equals(l:env1.is_screen, l:env2.is_screen)
  call s:assert.equals(l:env1.term, l:env2.term)
  call s:assert.equals(l:env1.term_program, l:env2.term_program)
endfunction

" Test: reset_cache can be called multiple times
function! s:suite.test_reset_cache_multiple_times() abort
  " Populate cache
  call cursorshape#deps#env#detect()

  " Reset multiple times
  call cursorshape#deps#env#reset_cache()
  call cursorshape#deps#env#reset_cache()
  call cursorshape#deps#env#reset_cache()

  " Should still work correctly
  let l:env = cursorshape#deps#env#detect()
  call s:assert.has_key(l:env, 'is_tmux')
  call s:assert.has_key(l:env, 'is_screen')
endfunction
