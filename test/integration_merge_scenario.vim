" test/integration_merge_scenario.vim
" Real-world integration test for guicursor merge behavior
" Tests realistic user scenarios where existing guicursor settings should be preserved

scriptencoding utf-8

let s:suite = themis#suite('integration_merge_scenario')
let s:assert = themis#helper('assert')

" Setup before each test
function! s:suite.before_each() abort
  runtime autoload/cursorshape/core.vim
  runtime autoload/cursorshape/internal/guicursor.vim
  call cursorshape#internal#guicursor#reset()

  if !exists('+guicursor')
    call themis#log('Skipping integration tests: +guicursor not available')
  endif
endfunction

" Cleanup after each test
function! s:suite.after_each() abort
  call cursorshape#internal#guicursor#reset()
endfunction

" ============================================================================
" Real-world Scenarios
" ============================================================================

" Scenario 1: User has custom showmatch cursor
" Many users set sm (showmatch) to have a different cursor when showing matches
function! s:suite.test_scenario_showmatch_preservation() abort
  if !exists('+guicursor')
    return
  endif

  " User's vimrc: Custom showmatch cursor
  let &guicursor = 'n:block-blinkon0,i-ci:ver25-blinkon1,sm:block-blinkwait175-blinkon175-blinkoff150'

  " User installs cursorshape plugin
  let l:modes = {
        \ 'normal': 'block_blink',
        \ 'insert': 'bar_steady',
        \ 'replace': 'underline_blink'
        \ }
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Verify: cursorshape modes are applied
  call s:assert.match(&guicursor, 'n:block')
  call s:assert.match(&guicursor, 'i-ci:ver25')
  call s:assert.match(&guicursor, 'r-cr:hor20')

  " Verify: showmatch setting is preserved
  call s:assert.match(&guicursor, 'sm:block-blinkwait175-blinkon175-blinkoff150')
endfunction

" Scenario 2: User has global blink settings with 'a:' mode
" The 'a:' mode applies to all modes as a fallback
function! s:suite.test_scenario_global_blink_settings() abort
  if !exists('+guicursor')
    return
  endif

  " User's vimrc: Global blink timing
  let &guicursor = 'n:block,i-ci:ver25,a:blinkwait700-blinkon400-blinkoff250'

  " Apply cursorshape
  let l:modes = {'normal': 'bar_steady', 'insert': 'underline_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Verify: cursorshape modes are applied
  call s:assert.match(&guicursor, 'n:ver25-blinkon0')
  call s:assert.match(&guicursor, 'i-ci:hor20')

  " Verify: global 'a:' setting is preserved
  call s:assert.match(&guicursor, 'a:blinkwait700-blinkon400-blinkoff250')
endfunction

" Scenario 3: User has highlight group references
" guicursor can reference highlight groups (e.g., Cursor/lCursor)
function! s:suite.test_scenario_highlight_group_references() abort
  if !exists('+guicursor')
    return
  endif

  " User's vimrc: Custom highlight groups with special characters and colons
  let &guicursor = 'n:block-Cursor/lCursor,i-ci:ver25-Cursor/lCursor:3000,sm:hor50-Cursor'

  " Apply cursorshape
  let l:modes = {'insert': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Verify: insert mode updated
  call s:assert.match(&guicursor, 'i-ci:ver25')

  " Verify: showmatch with custom highlight preserved
  call s:assert.match(&guicursor, 'sm:hor50-Cursor')
endfunction

" Scenario 4: User disables cursorshape and re-enables
" Settings should be properly restored and re-applied
function! s:suite.test_scenario_disable_reenable() abort
  if !exists('+guicursor')
    return
  endif

  " Initial user settings with custom modes
  let &guicursor = 'n:block-blinkon0,i-ci:ver25,sm:hor20,a:blinkwait500'
  let l:original = &guicursor

  " User enables cursorshape
  let l:modes = {'normal': 'bar_blink', 'insert': 'underline_steady'}
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Verify: modes changed
  call s:assert.not_equals(&guicursor, l:original)

  " User disables cursorshape
  call cursorshape#internal#guicursor#restore('startup')

  " Verify: completely restored including custom modes
  call s:assert.equals(&guicursor, l:original)
  call s:assert.match(&guicursor, 'sm:hor20')
  call s:assert.match(&guicursor, 'a:blinkwait500')

  " User re-enables cursorshape
  call cursorshape#internal#guicursor#apply(l:modes, 'startup')

  " Verify: custom modes preserved again
  call s:assert.match(&guicursor, 'sm:hor20')
  call s:assert.match(&guicursor, 'a:blinkwait500')
endfunction

" Scenario 5: Multiple plugins modify guicursor
" Simulate another plugin adding settings after cursorshape
function! s:suite.test_scenario_multiple_plugins() abort
  if !exists('+guicursor')
    return
  endif

  " Initial: empty guicursor
  let &guicursor = ''

  " Plugin 1 (cursorshape): sets normal and insert
  let l:modes1 = {'normal': 'block_blink', 'insert': 'bar_steady'}
  call cursorshape#internal#guicursor#apply(l:modes1, 'default')

  " Plugin 2: adds showmatch and operator modes
  let &guicursor = &guicursor . ',sm:hor20,o:hor50'

  " Plugin 1 updates (cursorshape): updates normal mode
  let l:modes2 = {'normal': 'underline_blink'}
  call cursorshape#internal#guicursor#apply(l:modes2, 'default')

  " Verify: cursorshape's normal mode is updated
  call s:assert.match(&guicursor, 'n:hor20')

  " Verify: Plugin 2's modes are preserved
  call s:assert.match(&guicursor, 'sm:hor20')
  call s:assert.match(&guicursor, 'o:hor50')
endfunction

" Scenario 6: Empty guicursor should work gracefully
function! s:suite.test_scenario_empty_initial_guicursor() abort
  if !exists('+guicursor')
    return
  endif

  " User has no guicursor set (empty)
  let &guicursor = ''

  " Apply cursorshape
  let l:modes = {'normal': 'block_steady', 'insert': 'bar_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Verify: cursorshape modes applied
  call s:assert.match(&guicursor, 'n:block')
  call s:assert.match(&guicursor, 'i-ci:ver25')

  " No crash or error should occur
  call s:assert.not_equals(&guicursor, '')
endfunction

" Scenario 7: User has only unmanaged modes
function! s:suite.test_scenario_only_unmanaged_modes() abort
  if !exists('+guicursor')
    return
  endif

  " User only sets unmanaged modes
  let &guicursor = 'sm:hor20-blinkwait100,a:blinkwait500'

  " Apply cursorshape
  let l:modes = {'normal': 'block_blink'}
  call cursorshape#internal#guicursor#apply(l:modes, 'default')

  " Verify: cursorshape mode added
  call s:assert.match(&guicursor, 'n:block')

  " Verify: unmanaged modes preserved
  call s:assert.match(&guicursor, 'sm:hor20-blinkwait100')
  call s:assert.match(&guicursor, 'a:blinkwait500')
endfunction
