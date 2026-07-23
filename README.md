# AFFAN Waypoint & Checkpoint Teleporter

Auto teleport + custom waypoint system untuk Roblox obby/tower games.

## ✨ Features v3.0

### 🎯 Dual Mode System
- **Checkpoint Mode**: Auto-scan dan sequential teleport
- **Waypoint Mode**: Custom position marking + save/load

### 💾 Save/Load System
- Simpan waypoints ke JSON file
- Auto-naming dengan timestamp
- Load waypoints antar session

### 📋 Waypoint Manager
- Scrollable waypoint list
- Individual teleport per waypoint
- Delete individual waypoint
- Real-time counter

### 🔧 Smart Features
- Loop mode (auto restart setelah complete)
- Adjustable delay (0.1-3.0s)
- Pause/Resume control
- Progress tracking
- Ceiling detection (anti-stuck)

## 📥 Installation

Copy dan paste ke executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MiksuTrg/affan-checkpoint-teleporter/master/affan.lua"))()
```

## 🎮 Usage

### Mode 1: Checkpoint Auto-Teleport
1. Click **📍 Checkpoint** mode
2. Click **🔍 SCAN** untuk detect checkpoints
3. Click **▶ START** untuk auto teleport
4. Toggle **Loop Mode** untuk repeat

### Mode 2: Custom Waypoint
1. Click **🎯 Waypoint** mode
2. Berdiri di posisi yang mau di-save
3. Click **📌 MARK** untuk save waypoint
4. Repeat untuk titik lain
5. Click **▶ START** untuk auto TP semua waypoints

### Save/Load Workflow
1. Mark beberapa waypoints (mode waypoint)
2. Click **💾 SAVE** → auto-save ke file timestamp
3. Tutup executor / restart game
4. Load script lagi
5. Click **📂 LOAD** → restore semua waypoints
6. Click **▶ START** → auto TP dari saved data

### Individual Teleport
- Lihat waypoint list (scroll area)
- Click tombol **TP** di sebelah waypoint
- Langsung TP ke posisi itu (no loop)

## 🔄 Version History

### v3.0 (2026-07-23)
- ➕ Custom waypoint system
- ➕ Save/Load JSON files
- ➕ Waypoint manager UI
- ➕ Dual mode (Checkpoint/Waypoint)
- ➕ Individual waypoint teleport
- 🐛 10 bug fixes (connection leaks, state management, etc)

### v2.0.1 (2026-07-23)
- 🐛 Fix WindUI error → Native Roblox UI
- 🐛 Fix UI state bugs
- 🐛 Fix character death handling
- 🐛 Fix memory leaks

### v2.0 (2026-07-23)
- ➕ Native Roblox UI (no WindUI)
- ➕ Improved checkpoint scanning
- ➕ Better error handling

### v1.0 (Initial)
- Basic checkpoint teleport
- WindUI interface

## 💻 Compatibility

✅ Synapse X  
✅ KRNL  
✅ Script-Ware  
✅ Fluxus  
✅ Delta  
✅ Codex  

**Requirements:**
- `writefile()` / `readfile()` untuk save/load
- `listfiles()` untuk file detection

## 📊 Stats

- **Lines**: 959
- **Size**: 32.8 KB
- **Functions**: 15
- **Modes**: 2 (Checkpoint + Waypoint)

## 🔒 Features

- 🎯 Dual-strategy checkpoint scanning (folder + name-based)
- 💾 JSON serialization (Vector3 + CFrame)
- 🔄 Loop mode dengan auto-restart
- ⏸ Pause/Resume control
- 📊 Real-time progress tracking
- 🚀 Individual waypoint teleport
- 🗑 Delete individual waypoint
- 🔍 Ceiling detection (anti-stuck)
- 🛡 Character death handling
- 🧹 Memory leak prevention

## ⚙️ Technical Details

**JSON Format:**
```json
{
  "version": "3.0",
  "waypoints": [
    {
      "name": "WP_1",
      "pos": [X, Y, Z],
      "rot": [px, py, pz, lvx, lvy, lvz],
      "timestamp": 1234567890
    }
  ],
  "savedAt": 1234567890,
  "mapName": "Workspace"
}
```

**File Naming:**
- Pattern: `affan_waypoints_<name>.json`
- Auto-generated: `wp_MMDD_HHMM` (timestamp)

## 📝 Credits

UI Library: Native Roblox (ScreenGui)
