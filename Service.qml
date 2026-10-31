import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  // Injected by omarchy-shell
  property var shell: null

  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/happy-dim.json"
  readonly property string fallbackConfigPath: Quickshell.env("HOME") + "/.config/omarchy/auto-dim.json"
  readonly property string stayAwakePath: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"

  property real minutes: 1.0
  property real dimFactor: 0.25
  property bool enabled: true
  property bool stayAwake: false

  property bool celebrateEnabled: true
  property int celebrateDuration: 3
  property string celebrateColor: "gray"

  property int savedBrightness: 0
  property bool isDimmed: false

  readonly property int dimTimeoutSeconds: Math.max(1, Math.round(root.minutes * 60))

  function applyConfig(raw) {
    var parsed = null
    if (raw && String(raw).trim() !== "") {
      try { parsed = JSON.parse(raw) } catch (e) { parsed = null }
    }
    if (!parsed || typeof parsed !== "object") return

    if (typeof parsed.minutes === "number" && parsed.minutes > 0) {
      root.minutes = parsed.minutes
    }

    if (typeof parsed.dimPercentage === "number" && parsed.dimPercentage > 0 && parsed.dimPercentage <= 100) {
      root.dimFactor = parsed.dimPercentage / 100.0
    } else if (typeof parsed.dimFactor === "number" && parsed.dimFactor > 0 && parsed.dimFactor <= 1.0) {
      root.dimFactor = parsed.dimFactor
    }

    if (typeof parsed.enabled === "boolean") {
      root.enabled = parsed.enabled
    }

    if (typeof parsed.celebrateEnabled === "boolean") {
      root.celebrateEnabled = parsed.celebrateEnabled
    }

    if (typeof parsed.celebrateDuration === "number" && parsed.celebrateDuration > 0) {
      root.celebrateDuration = Math.round(parsed.celebrateDuration)
    }

    if (parsed.celebrateColor === "dark-gray" || parsed.celebrateColor === "gray") {
      root.celebrateColor = parsed.celebrateColor
    }

    console.log("happy-dim service: loaded config (idle=" + root.dimTimeoutSeconds + "s, dimFactor=" + root.dimFactor + ", celebrate=" + root.celebrateEnabled + ", dur=" + root.celebrateDuration + "s, color=" + root.celebrateColor + ")")
  }

  property FileView configFile: FileView {
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyConfig(text())
    onLoadFailed: fallbackConfigFile.reload()
  }

  property FileView fallbackConfigFile: FileView {
    path: root.fallbackConfigPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyConfig(text())
  }

  property FileView stayAwakeFile: FileView {
    path: root.stayAwakePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.stayAwake = true
    onLoadFailed: root.stayAwake = false
  }

  Timer {
    interval: 1000
    running: true
    onTriggered: {
      root.configFile.reload()
      root.stayAwakeFile.reload()
    }
  }

  function handleIdle() {
    if (!root.enabled || root.stayAwake || root.isDimmed) return
    console.log("happy-dim: idle detected after " + root.dimTimeoutSeconds + "s, dimming display...")
    readBrightnessProc.running = true
    if (root.celebrateEnabled) {
      var durMs = root.celebrateDuration * 1000
      Quickshell.execDetached(["omarchy-shell", "zm.celebrate", "startWith", String(durMs), root.celebrateColor])
    }
  }

  function handleActive() {
    if (root.isDimmed && root.savedBrightness > 0) {
      var restoreVal = root.savedBrightness
      console.log("happy-dim: user activity detected, restoring brightness to " + restoreVal + "%")
      root.isDimmed = false
      root.savedBrightness = 0
      Quickshell.execDetached(["omarchy-brightness-display", "--no-osd", restoreVal + "%"])
    }
    if (root.celebrateEnabled) {
      Quickshell.execDetached(["omarchy-shell", "zm.celebrate", "reset"])
    }
  }

  Process {
    id: readBrightnessProc
    command: ["omarchy-brightness-display"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var str = String(text || "").trim()
        var current = parseInt(str, 10)
        if (isNaN(current) || current <= 1) {
          console.log("happy-dim: current brightness too low or unreadable: " + str)
          return
        }
        if (!idleMonitor.isIdle) {
          console.log("happy-dim: user became active before dim could be applied")
          return
        }
        root.savedBrightness = current
        var target = Math.max(1, Math.round(current * root.dimFactor))
        console.log("happy-dim: dimming display from " + current + "% to " + target + "%")
        root.isDimmed = true
        Quickshell.execDetached(["omarchy-brightness-display", "--no-osd", target + "%"])
      }
    }
  }

  IdleMonitor {
    id: idleMonitor
    enabled: root.enabled && !root.stayAwake && root.dimTimeoutSeconds > 0
    timeout: root.dimTimeoutSeconds
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle) {
        root.handleIdle()
      } else {
        root.handleActive()
      }
    }
  }

  Component.onDestruction: {
    if (root.isDimmed && root.savedBrightness > 0) {
      Quickshell.execDetached(["omarchy-brightness-display", "--no-osd", root.savedBrightness + "%"])
    }
    if (root.celebrateEnabled) {
      Quickshell.execDetached(["omarchy-shell", "zm.celebrate", "reset"])
    }
  }
}
