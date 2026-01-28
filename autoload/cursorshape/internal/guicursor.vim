" autoload/cursorshape/internal/guicursor.vim
" Neovim guicursor backend implementation
" Manages Neovim's &guicursor option with differential application and restoration

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Internal state
let s:guicursor_applied = 0
let s:original_guicursor = ''

" Parse guicursor string into a dictionary
" Converts a guicursor string (e.g., "n-v-c:block,i-ci:ver25") into a dict
" mapping mode-list to settings for easier manipulation
" Handles settings with multiple colons (e.g., "n:block-Cursor/lCursor:3000")
" @param {string} guicursor The guicursor option value to parse
" @return {dict} Dictionary mapping mode-list to settings
"   Example: {'n-v-c': 'block-blinkon0', 'i-ci': 'ver25-blinkwait200'}
function! s:parse_guicursor(guicursor) abort
  let l:result = {}
  if empty(a:guicursor)
    return l:result
  endif

  " Split by comma to get individual mode:setting pairs
  for l:item in split(a:guicursor, ',')
    " Split by first colon only to separate mode-list from settings
    " Settings may contain additional colons (e.g., Cursor/lCursor:3000)
    let l:colon_idx = stridx(l:item, ':')
    if l:colon_idx > 0
      let l:mode = l:item[:l:colon_idx - 1]
      " Include everything after first colon as the setting (may contain more colons)
      let l:setting = l:item[l:colon_idx + 1:]
      let l:result[l:mode] = l:setting
    endif
  endfor

  return l:result
endfunction

" Merge new guicursor settings with existing ones
" This function preserves existing mode settings that are not being replaced
" and removes only the modes that conflict with modes being set in new_modes
" @param {string} existing Current &guicursor value
" @param {dict} new_modes Dictionary of mode-list to settings to apply
" @return {string} Merged guicursor string
function! s:merge_guicursor(existing, new_modes) abort
  " Parse existing guicursor into dict
  let l:existing_dict = s:parse_guicursor(a:existing)

  " Build a set of individual mode characters that are being set
  " For example, if new_modes has 'n-v-c' and 'i-ci', we're setting n, v, c, i, ci
  let l:new_mode_chars = {}
  for l:mode_list in keys(a:new_modes)
    " Split by dash to get individual modes
    " Note: 'ci' is a single mode, not 'c' and 'i'
    let l:parts = split(l:mode_list, '-')
    for l:part in l:parts
      let l:new_mode_chars[l:part] = 1
    endfor
  endfor

  " Remove existing mode-lists that overlap with what we're setting
  " We need to remove entries that contain any of the modes we're setting
  let l:keys_to_remove = []
  for l:existing_mode_list in keys(l:existing_dict)
    let l:has_overlap = 0
    let l:existing_parts = split(l:existing_mode_list, '-')
    for l:part in l:existing_parts
      if has_key(l:new_mode_chars, l:part)
        let l:has_overlap = 1
        break
      endif
    endfor
    if l:has_overlap
      call add(l:keys_to_remove, l:existing_mode_list)
    endif
  endfor

  " Remove overlapping modes from existing
  for l:key in l:keys_to_remove
    call remove(l:existing_dict, l:key)
  endfor

  " Add new modes from cursorshape
  call extend(l:existing_dict, a:new_modes)

  " Convert dictionary back to guicursor string format
  let l:parts = []
  for [l:mode, l:setting] in items(l:existing_dict)
    call add(l:parts, l:mode . ':' . l:setting)
  endfor

  return join(l:parts, ',')
endfunction

" Apply cursor shapes to Neovim's &guicursor option
" Merges new cursor shapes with existing &guicursor settings to preserve
" user-configured modes that cursorshape doesn't manage
" @param {dict} modes Dictionary of mode -> shape mappings
"   Example: {'normal': 'block_blink', 'insert': 'bar_blink', 'replace': 'underline_blink'}
" @param {string} restore Restoration mode ('default', 'startup', 'none')
function! cursorshape#internal#guicursor#apply(modes, restore) abort
  " For 'startup' restore mode: save original guicursor value on first application
  if a:restore ==# 'startup' && !s:guicursor_applied
    let s:original_guicursor = &guicursor
  endif

  " Convert each mode's shape to guicursor format using core layer
  " Build a dict mapping mode-list to settings for merging
  let l:new_modes = {}
  for [l:mode, l:shape] in items(a:modes)
    let l:part = cursorshape#core#shape_to_guicursor(l:mode, l:shape)
    " Split "n-v-c:block-blinkon0" into mode-list and settings
    let l:colon_idx = stridx(l:part, ':')
    if l:colon_idx > 0
      let l:mode_list = l:part[:l:colon_idx - 1]
      let l:settings = l:part[l:colon_idx + 1:]
      let l:new_modes[l:mode_list] = l:settings
    endif
  endfor

  " Merge with existing guicursor settings to preserve unmanaged modes
  let l:merged = s:merge_guicursor(&guicursor, l:new_modes)
  let &guicursor = l:merged

  " Mark as applied
  let s:guicursor_applied = 1
endfunction

" Restore cursor shapes based on restoration mode
" @param {string} restore Restoration mode
"   'default'  : Reset to safe default ('a:block-blinkon0')
"   'startup'  : Restore to original value saved on first apply
"   'none'     : Do nothing
function! cursorshape#internal#guicursor#restore(restore) abort
  if a:restore ==# 'default'
    " Set to safe default: block cursor with no blinking
    let &guicursor = 'a:block-blinkon0'
  elseif a:restore ==# 'startup'
    " Restore original value if it was saved
    if !empty(s:original_guicursor)
      let &guicursor = s:original_guicursor
    endif
  endif
  " For 'none', do nothing

  " Mark as not applied
  let s:guicursor_applied = 0
endfunction

" Reset internal state (primarily for testing)
" Clears applied flag and original guicursor cache
function! cursorshape#internal#guicursor#reset() abort
  let s:guicursor_applied = 0
  let s:original_guicursor = ''
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
