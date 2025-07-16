### Kanata Keyboard Layers Summary

#### **Layer 1: Main Modifiers (Default)**
- **Media/System Controls**:  
  Tap F1-F10 for standard keys; hold for shortcuts:  
  - `F1`: Quit terminal (`Ctrl+Alt+Q`)  
  - `F5-F8`: Mute/volume/mic controls (`Alt+F5`-`Alt+F8`)  
  - `F10`: Lock screen (`Ctrl+Alt+Shift+L`)  

- **Symbols/Numbers**:  
  Hold number keys for shifted symbols (e.g., `1` → `!`, `-` → `_`).  

- **Home-Row Modifiers**:  
  Tap `S/D/F` for letters; hold for modifiers:  
  - `S`: Meta (Super)  
  - `D`: Alt  
  - `F`: Ctrl  

- **Navigation Shortcuts**:  
  Hold `Y/U/I/O` for: Home, PgDn, PgUp, End.  

- **Layer Toggles**:  
  - Hold `Left Meta` → **Layer 2**  
  - Hold `Space` → **Layer 3**  

---

#### **Layer 2: Workspaces & Windows (Left Meta Hold)**
- **Workspace Switching**:  
  `1-4`: Switch to workspace 1-4 (`Alt+Meta+1`-`4`).  

- **Window Management**:  
  - Move window left/right workspaces: `Shift+Meta+PgUp/PgDn`  
  - Move workspace left/right: `Meta+Left/Right`  

- **Tile Controls**:  
  `Ctrl+Meta+,/.` to move/resize tiles.  

- **Config Reload**:  
  `F12`: Reload Kanata config.  

---

#### **Layer 3: Editing & Mouse (Space Hold)**
- **Text Editing**:  
  - Delete word: `,` (backward), `.` (forward)  
  - Delete line: `[` (to start), `]` (to end)  
  - Arrow keys: `H/J/K/L` ← ↓ ↑ →  

- **Mouse Emulation**:  
  - Scroll wheel: `W/A/S/D` (left/down/up/right)  
  - Horizontal scroll: `Q/E` (left/right)  

- **Terminal Shortcuts**:  
  `Ctrl+W` (close tab), `Alt+D` (delete word).  

---

### Key Implementation Notes
- **Tap-Hold**: All modifiers use 200ms tap-hold timing.  
- **Layer Toggles**: Transient (reverts on key release).  
- **Wayland**: Virtual input via `uinput`; no low-level interception.  
- **GNOME Integration**: Media keys, workspace shortcuts, and mouse emulation work natively.  

> No conflicts reported in active use per user feedback. With current custom Gnome settings from user repo
