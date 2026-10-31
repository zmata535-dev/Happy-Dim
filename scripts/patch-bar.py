#!/usr/bin/env python3
"""
patch-bar.py — Safely inject Celebrate mode into Omarchy's Bar.qml
"""
import sys
import re

CELEBRATION_BLOCK = '''
  // --- Celebration mode (random bright colors for every icon) ---
  property bool celebrationActive: false
  property bool celebrationGrayActive: false
  property bool canResetGray: false
  property color celebrationGrayColor: "#808080"
  property string configuredPostColor: "gray"
  property int configuredCelebrateDuration: 3000
  property string savedCursorPos: ""
  property int celebrationTick: 0
  property var celebrationColorMap: ({})

  FileView {
    path: root.omarchyConfigDir + "/happy-dim.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (parsed) {
          if (parsed.celebrateColor === "dark-gray" || parsed.celebrateColor === "gray") {
            root.configuredPostColor = parsed.celebrateColor
          }
          if (typeof parsed.celebrateDuration === "number" && parsed.celebrateDuration > 0) {
            root.configuredCelebrateDuration = Math.round(parsed.celebrateDuration * 1000)
          }
        }
      } catch (e) {}
    }
  }

  FileView {
    path: root.omarchyConfigDir + "/auto-dim.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (parsed) {
          if (parsed.celebrateColor === "dark-gray" || parsed.celebrateColor === "gray") {
            root.configuredPostColor = parsed.celebrateColor
          }
          if (typeof parsed.celebrateDuration === "number" && parsed.celebrateDuration > 0) {
            root.configuredCelebrateDuration = Math.round(parsed.celebrateDuration * 1000)
          }
        }
      } catch (e) {}
    }
  }

  function resolvePostColor(colorName) {
    if (colorName === "dark-gray") return "#404040"
    return "#808080"
  }

  // System activity watchers
  property var activeToplevelWatcher: ToplevelManager.activeToplevel
  onActiveToplevelWatcherChanged: if (root.canResetGray) root.resetCelebrationGray()

  property var focusedWorkspaceWatcher: Hyprland.focusedWorkspace
  onFocusedWorkspaceWatcherChanged: if (root.canResetGray) root.resetCelebrationGray()

  property var focusedMonitorWatcher: Hyprland.focusedMonitor
  onFocusedMonitorWatcherChanged: if (root.canResetGray) root.resetCelebrationGray()

  onBarHoveredChanged: if (barHovered && root.canResetGray) root.resetCelebrationGray()

  function randomBrightColor() {
    var h = Math.random() * 360
    var s = 0.9 + Math.random() * 0.1
    var v = 0.9 + Math.random() * 0.1
    var c = v * s
    var x = c * (1 - Math.abs(((h / 60) % 2) - 1))
    var m = v - c
    var r = 0, g = 0, b = 0
    if (h < 60)       { r = c; g = x; b = 0 }
    else if (h < 120) { r = x; g = c; b = 0 }
    else if (h < 180) { r = 0; g = c; b = x }
    else if (h < 240) { r = 0; g = x; b = c }
    else if (h < 300) { r = x; g = 0; b = c }
    else              { r = c; g = 0; b = x }
    return Qt.rgba(r + m, g + m, b + m, 1.0)
  }

  function refreshCelebrationColors() {
    var map = {}
    for (var id in pluginBarApis) {
      map[id] = randomBrightColor()
    }
    var bg = randomBrightColor()
    root.foreground = bg
    root.barForeground = bg
    celebrationColorMap = map
    celebrationTick++
  }

  function startCelebration(durationMs, postColor) {
    var duration = (typeof durationMs === "number" && durationMs > 0) ? durationMs : root.configuredCelebrateDuration
    var chosenColor = (postColor === "dark-gray" || postColor === "gray") ? postColor : root.configuredPostColor
    celebrationGrayColor = resolvePostColor(chosenColor)
    celebrationGrayActive = false
    canResetGray = false
    celebrationGraceTimer.stop()
    cursorWatcherTimer.stop()
    savedCursorPos = ""
    celebrationStopTimer.interval = duration
    refreshCelebrationColors()
    celebrationActive = true
    celebrationTimer.restart()
    celebrationStopTimer.restart()
  }

  function enterCelebrationGray() {
    celebrationTimer.stop()
    celebrationActive = false
    celebrationColorMap = ({})
    celebrationGrayActive = true
    canResetGray = false
    savedCursorPos = ""
    root.foreground = celebrationGrayColor
    root.barForeground = celebrationGrayColor
    cursorPosInitProc.running = true
    celebrationGraceTimer.restart()
  }

  function resetCelebrationGray() {
    if (!celebrationGrayActive && !celebrationActive) return
    celebrationTimer.stop()
    celebrationStopTimer.stop()
    celebrationGraceTimer.stop()
    cursorWatcherTimer.stop()
    celebrationActive = false
    celebrationGrayActive = false
    canResetGray = false
    celebrationColorMap = ({})
    savedCursorPos = ""
    root.foreground = root.themeForeground
    root.barForeground = root.useTransparentForeground ? root.transparentForeground : root.themeForeground
  }

  function stopCelebration() {
    resetCelebrationGray()
  }

  Timer {
    id: celebrationTimer
    interval: 75
    repeat: true
    running: false
    onTriggered: root.refreshCelebrationColors()
  }

  Timer {
    id: celebrationStopTimer
    interval: 3000
    repeat: false
    running: false
    onTriggered: root.enterCelebrationGray()
  }

  Timer {
    id: celebrationGraceTimer
    interval: 350
    repeat: false
    running: false
    onTriggered: {
      root.canResetGray = true
      cursorWatcherTimer.restart()
    }
  }

  IdleMonitor {
    id: celebrationIdleMonitor
    enabled: root.celebrationGrayActive
    timeout: 1
    onIsIdleChanged: {
      if (!isIdle && root.canResetGray) {
        root.resetCelebrationGray()
      }
    }
  }

  Process {
    id: cursorPosInitProc
    command: ["hyprctl", "cursorpos"]
    stdout: SplitParser {
      onRead: function(line) {
        var pos = String(line || "").trim()
        if (pos) root.savedCursorPos = pos
      }
    }
  }

  Process {
    id: cursorWatcher
    command: ["hyprctl", "cursorpos"]
    stdout: SplitParser {
      onRead: function(line) {
        var pos = String(line || "").trim()
        if (!pos) return
        if (root.savedCursorPos === "") {
          root.savedCursorPos = pos
        } else if (root.savedCursorPos !== pos && root.canResetGray) {
          root.resetCelebrationGray()
        }
      }
    }
  }

  Timer {
    id: cursorWatcherTimer
    interval: 100
    repeat: true
    running: false
    onTriggered: {
      if (!cursorWatcher.running) cursorWatcher.running = true
    }
  }
'''

IPC_HANDLER_BLOCK = '''
  IpcHandler {
    target: "zm.celebrate"

    function start(): void {
      root.startCelebration(root.configuredCelebrateDuration, root.configuredPostColor)
    }

    function startWith(durationMs: int, postColor: string): void {
      root.startCelebration(durationMs, postColor)
    }

    function stop(): void {
      root.resetCelebrationGray()
    }

    function reset(): void {
      root.resetCelebrationGray()
    }
  }
'''

def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if "zm.celebrate" in content:
        print(f"[setup-bar] {filepath} already has celebrate integration.")
        return True

    # 1. Insert celebration properties block
    urgent_target = "property color urgent: Color.bar.active"
    if urgent_target in content:
        content = content.replace(urgent_target, urgent_target + "\n" + CELEBRATION_BLOCK, 1)
    else:
        print("[setup-bar] Warning: Could not find urgent color property anchor.")
        return False

    # 2. Patch bindPluginBarApi
    old_foreground = "api.foreground = Qt.binding(function() { return root.foreground })"
    new_foreground = """api.foreground = Qt.binding(function() {
      if (root.celebrationActive) {
        var _t = root.celebrationTick
        return (root.celebrationColorMap && root.celebrationColorMap[key]) ? root.celebrationColorMap[key] : root.foreground
      }
      if (root.celebrationGrayActive) {
        return root.celebrationGrayColor
      }
      return root.foreground
    })"""
    if old_foreground in content:
        content = content.replace(old_foreground, new_foreground, 1)

    old_barForeground = "api.barForeground = Qt.binding(function() { return root.barForeground })"
    new_barForeground = """api.barForeground = Qt.binding(function() {
      if (root.celebrationActive) {
        var _t = root.celebrationTick
        return (root.celebrationColorMap && root.celebrationColorMap[key]) ? root.celebrationColorMap[key] : root.barForeground
      }
      if (root.celebrationGrayActive) {
        return root.celebrationGrayColor
      }
      return root.barForeground
    })"""
    if old_barForeground in content:
        content = content.replace(old_barForeground, new_barForeground, 1)

    # 3. Suppress foregroundAnimation during celebration
    old_anim = "api.foregroundAnimationEnabled = Qt.binding(function() { return root.foregroundAnimationEnabled })"
    new_anim = """api.foregroundAnimationEnabled = Qt.binding(function() {
      return root.celebrationActive ? false : root.foregroundAnimationEnabled
    })"""
    if old_anim in content:
        content = content.replace(old_anim, new_anim, 1)

    # 4. Insert IpcHandler before the Variants block
    if "Variants {" in content:
        content = content.replace("Variants {", IPC_HANDLER_BLOCK + "\n  Variants {", 1)
    else:
        # fallback before last closing brace
        last_brace = content.rfind("}")
        if last_brace != -1:
            content = content[:last_brace] + IPC_HANDLER_BLOCK + "\n}"

    # 5. Add HoverHandler wakeups
    content = content.replace(
        "onHoveredChanged: root.setBarHovered(hovered)",
        "onHoveredChanged: root.setBarHovered(hovered)\n        onPointChanged: if (root.canResetGray) root.resetCelebrationGray()"
    )

    # 6. Ensure firstParty widgets also receive themed API colors
    content = content.replace(
        'if ("bar" in target) target.bar = firstParty\n        ? root : root.pluginBarApiFor(pluginApiId, moduleName, registered)',
        'if ("bar" in target) target.bar = root.pluginBarApiFor(pluginApiId, moduleName, registered)'
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[setup-bar] Successfully patched {filepath}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: patch-bar.py <path-to-Bar.qml>")
        sys.exit(1)
    success = patch_file(sys.argv[1])
    sys.exit(0 if success else 1)
