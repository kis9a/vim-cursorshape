# cursorshape

A Vim/Neovim plugin for controlling terminal cursor shape based on editing mode.

## Features

- **Mode-specific cursor shapes**: Change cursor appearance for Normal, Insert, and Replace modes
- **Cross-editor compatibility**: Works seamlessly on both Vim 8.0+ and Neovim 0.5+
- **Flexible backends**: Automatic backend selection (Neovim's `guicursor` or Vim's termcap)
- **Intelligent guicursor merging**: Preserves user's existing settings in Neovim
- **Individual mode configuration**: Configure normal/visual/cmdline/insert/replace modes independently
- **Environment cache refresh**: Accurate runtime information with force refresh support
- **Safe fallback**: Gracefully handles unsupported terminals and environments
- **Customizable shapes**: Block, bar (vertical line), or underline cursor with blinking or steady variants
- **Restore policy**: Control cursor behavior on exit

## Requirements

- Vim 8.0+ or Neovim 0.5+
- Terminal emulator that supports DECSCUSR escape sequences

### Supported Terminals

- iTerm2
- Kitty
- Alacritty
- WezTerm
- XTerm
- Konsole
- GNOME Terminal (recent versions with libvte)
- tmux (requires `g:cursorshape_allow_tmux=1`)

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'kis9a/vim-cursorshape'
```

### Using [Vundle](https://github.com/VundleVim/Vundle.vim)

```vim
Plugin 'kis9a/vim-cursorshape'
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('kis9a/vim-cursorshape')
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'kis9a/vim-cursorshape'
```

## Quick Start

The plugin works out of the box with default settings:
- Normal mode: Blinking block cursor
- Visual mode: Blinking block cursor
- Command-line mode: Blinking block cursor
- Insert mode: Blinking bar cursor
- Replace mode: Blinking underline cursor

No configuration needed for basic usage!

## Configuration

### Available Options

```vim
" Enable/disable cursor shape control (default: 1)
let g:cursorshape_enabled = 1

" Backend selection: 'auto', 'vim_termcap', 'nvim_guicursor', 'none' (default: 'auto')
let g:cursorshape_backend = 'auto'

" Cursor shapes for each mode (default shown below)
let g:cursorshape_modes = {
  \ 'normal': 'block_blink',
  \ 'visual': 'block_blink',
  \ 'cmdline': 'block_blink',
  \ 'insert': 'bar_blink',
  \ 'replace': 'underline_blink',
  \ }

" Restore policy on exit: 'default', 'startup', 'none' (default: 'default')
let g:cursorshape_restore = 'default'

" Allow cursor shape control in tmux/screen (default: 0)
let g:cursorshape_allow_tmux = 0

" Enable debug mode (default: 0)
let g:cursorshape_debug = 0
```

### Available Modes

You can configure cursor shapes for the following modes:

- `normal` - Normal mode (n)
- `visual` - Visual mode (v)
- `cmdline` - Command-line mode (c)
- `insert` - Insert mode (i, ci)
- `replace` - Replace mode (r, cr)
- `operator` - Operator-pending mode (o) [optional]
- `visual_exclusive` - Visual-exclusive mode (ve) [optional]

**Note for Neovim users:** Individual mode settings are intelligently merged with your existing guicursor configuration. Only the modes specified in `g:cursorshape_modes` are updated, preserving any custom settings for other modes (such as `sm`, `o`, `ve`).

### Cursor Shapes

Available shape values for `g:cursorshape_modes`:

- `block_blink` - Blinking block (█)
- `block_steady` - Steady block (█)
- `bar_blink` - Blinking vertical bar (|)
- `bar_steady` - Steady vertical bar (|)
- `underline_blink` - Blinking underline (_)
- `underline_steady` - Steady underline (_)

### Example Configurations

#### Steady (non-blinking) cursors

```vim
let g:cursorshape_modes = {
  \ 'normal': 'block_steady',
  \ 'visual': 'block_steady',
  \ 'cmdline': 'block_steady',
  \ 'insert': 'bar_steady',
  \ 'replace': 'underline_steady',
  \ }
```

#### Custom shapes per mode

```vim
let g:cursorshape_modes = {
  \ 'normal': 'block_blink',
  \ 'visual': 'underline_blink',
  \ 'cmdline': 'block_steady',
  \ 'insert': 'underline_blink',
  \ 'replace': 'bar_steady',
  \ }
```

#### Enable in tmux

```vim
let g:cursorshape_allow_tmux = 1
```

### Advanced Usage

#### Force Refresh Environment Info

To get the latest environment information (e.g., after tmux attach/detach):

```vim
" Reset cache and get fresh info
call cursorshape#deps#env#reset_cache()
:CursorShapeInfo  " Now shows current environment
```

You can also force refresh programmatically:

```vim
" Force refresh environment detection
let env = cursorshape#deps#env#detect({'force': 1})
```

#### Debug Mode

Enable debug mode for advanced testing and internal function access:

```vim
let g:cursorshape_debug = 1
```

**Warning:** Debug mode enables internal functions (like `cursorshape#internal#termcap#reset()`) that are intended for testing only and may not work as expected for normal use. Use with caution.

## Commands

| Command | Description |
|---------|-------------|
| `:CursorShapeEnable` | Enable cursor shape control |
| `:CursorShapeDisable` | Disable cursor shape control |
| `:CursorShapeToggle` | Toggle cursor shape control on/off |
| `:CursorShapeInfo` | Display current configuration and environment info |
| `:CursorShapeTest` | Test cursor shape changes (shows guidance) |

## Functions

Public API functions for advanced usage:

```vim
" Enable cursor shape control
call cursorshape#enable()

" Disable cursor shape control
call cursorshape#disable()

" Toggle cursor shape control
call cursorshape#toggle()

" Get configuration and environment information
let info = cursorshape#info()

" Re-apply current cursor shape settings
call cursorshape#apply()
```

## Backends

The plugin uses different backends depending on the editor and environment:

### Auto Selection (Default)

When `g:cursorshape_backend` is set to `'auto'`, the plugin automatically selects the best backend:

1. If under tmux/screen and `allow_tmux=0`: use `'none'` (disabled)
2. If Neovim and `guicursor` available: use `'nvim_guicursor'`
3. If Vim and `t_SI`/`t_EI` available: use `'vim_termcap'`
4. Otherwise: use `'none'` (disabled)

### Neovim guicursor Backend

- Uses Neovim's `guicursor` option
- Works in both TUI and GUI modes
- Supports startup restore
- References: `:help 'guicursor'`, `:help tui-cursor-shape`

### Vim termcap Backend

- Uses Vim's termcap options (`t_SI`, `t_EI`, `t_SR`, `t_te`)
- Appends escape sequences safely
- Limited restore support (cannot query startup shape)
- References: `:help t_SI`, `:help t_EI`, `:help t_SR`

### None Backend

- Safe fallback when no backend is available
- Used in unsupported environments or when explicitly disabled

## Compatibility

### Vim vs Neovim

- **Vim**: Uses termcap options (`t_SI`, `t_EI`, `t_SR`)
- **Neovim**: Uses `guicursor` option (`t_*` options are ignored)

### tmux/screen

By default, cursor shape control is disabled under tmux/screen for safety. To enable:

```vim
let g:cursorshape_allow_tmux = 1
```

Note: Ensure your tmux configuration allows cursor shape pass-through.

### Terminal Support

Most modern terminal emulators support DECSCUSR escape sequences. Unsupported terminals will gracefully fallback to the `'none'` backend with no visual changes.

## Troubleshooting

### Cursor shape doesn't change

1. Run `:CursorShapeInfo` to check backend and capabilities
2. Verify your terminal supports cursor shape sequences
3. Try a different terminal emulator (iTerm2, Kitty, Alacritty, etc.)
4. If using tmux, set `let g:cursorshape_allow_tmux = 1`

### Cursor shape not restored on exit

This is a known limitation in some environments. Options:

- Set `g:cursorshape_restore='default'` to restore to block cursor
- Set `g:cursorshape_restore='none'` to keep current shape

### Plugin doesn't work in tmux

By default, the plugin is disabled in tmux for safety. Enable with:

```vim
let g:cursorshape_allow_tmux = 1
```

### Error messages on startup

1. Check `:messages` for detailed error information
2. Run `:CursorShapeInfo` to diagnose the issue
3. Verify your Vim/Neovim version meets requirements

## Known Limitations

### Vim termcap backend cannot be fully disabled

**Issue:** Once you enable the plugin with Vim's termcap backend, you cannot fully disable it without restarting Vim.

**Reason:** Vim's termcap options (t_SI, t_EI, t_SR) cannot be cleared once set. The `:CursorShapeDisable` command will warn you about this limitation.

**Technical Details:**
- The plugin appends escape sequences to Vim's termcap options
- These options cannot be safely reverted to their original values
- The disable command only prevents further changes but cannot remove existing sequences

**Workarounds:**
1. **Restart Vim** to fully clear the settings
2. Set `g:cursorshape_enabled = 0` in your vimrc to prevent auto-enable on next startup
3. Consider using **Neovim** if you need full disable/re-enable support (Neovim's `guicursor` can be fully reset)

**Note:** This is a Vim limitation, not a plugin bug. Use `:CursorShapeInfo` to check your current backend.

## Documentation

For detailed documentation, see:

```vim
:help cursorshape
```

## License

MIT License - Copyright (c) 2026 @kis9a

See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## See Also

- [Vim termcap documentation](https://vimhelp.org/term.txt.html)
- [Neovim TUI cursor shape](https://neovim.io/doc/user/term.html#tui-cursor-shape)
- [DECSCUSR escape sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_)
