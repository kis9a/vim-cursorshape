" autoload/cursorshape/internal/termcap.vim
" Vim termcap backend implementation
" Safely manages t_SI/t_EI/t_SR/t_ti/t_te terminal capabilities

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Flag to prevent duplicate application
let s:termcap_applied = 0

" Apply cursor shape settings via termcap options
" @param {dict} modes Mode-to-shape mapping
"   {
"     'normal': 'block_blink',
"     'insert': 'bar_blink',
"     'replace': 'underline_blink'
"   }
" @param {string} restore Restore policy ('default', 'startup', 'none')
"   - 'default': Reset cursor to normal shape on exit
"   - 'startup': Attempt to restore to startup shape (falls back to 'default')
"   - 'none': Leave cursor shape unchanged on exit
"
" Important constraints:
"   - t_EI must be set for t_SI/t_SR to be sent by Vim
"   - Use append (.=) to avoid overwriting existing sequences
"   - Only apply once to prevent duplicate sequences
function! cursorshape#internal#termcap#apply(modes, restore) abort
  " Prevent duplicate application
  if s:termcap_applied
    return
  endif

  " Convert abstract shapes to termcap escape sequences
  let l:normal_seq = cursorshape#core#shape_to_termcap(get(a:modes, 'normal', 'block_blink'))
  let l:insert_seq = cursorshape#core#shape_to_termcap(get(a:modes, 'insert', 'bar_blink'))
  let l:replace_seq = cursorshape#core#shape_to_termcap(get(a:modes, 'replace', 'underline_blink'))

  " Set termcap options
  " t_SI: Cursor shape when entering Insert mode
  let &t_SI .= l:insert_seq

  " t_SR: Cursor shape when entering Replace mode
  let &t_SR .= l:replace_seq

  " t_EI: Cursor shape when leaving Insert/Replace mode (REQUIRED)
  " This must be set for t_SI and t_SR to be sent by Vim
  let &t_EI .= l:normal_seq

  " Handle restore policy
  if a:restore ==# 'default'
    " Reset cursor to normal shape on exit via t_te (exit termcap mode)
    let &t_te .= l:normal_seq
  elseif a:restore ==# 'startup'
    " 'startup' policy: Restore to original startup cursor shape
    " Note: Cannot reliably capture startup cursor shape, so fall back to 'default'
    " This is a limitation of Vim's termcap system
    let &t_te .= l:normal_seq
  endif
  " For 'none', do not modify t_te

  " Mark as applied
  let s:termcap_applied = 1
endfunction

" Reset termcap settings (for testing only)
" WARNING: This only resets the internal flag. The actual t_SI/t_EI/t_SR
" cannot be fully reset without restarting Vim.
" @private Only available in debug mode (g:cursorshape_debug=1)
function! cursorshape#internal#termcap#reset() abort
  " Only allow reset in debug mode
  if !get(g:, 'cursorshape_debug', 0)
    throw 'cursorshape: reset() is only available in debug mode (set g:cursorshape_debug=1)'
  endif

  let s:termcap_applied = 0
  " Note: t_SI/t_EI/t_SR cannot be cleared - Vim restart required
endfunction

" Check if termcap has been applied (for testing)
" @return {number} 1 if applied, 0 otherwise
function! cursorshape#internal#termcap#is_applied() abort
  return s:termcap_applied
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
