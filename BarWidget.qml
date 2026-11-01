import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.zmata535-dev.happy-dim"

  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/happy-dim.json"
  readonly property string fallbackConfigPath: Quickshell.env("HOME") + "/.config/omarchy/auto-dim.json"
  readonly property string shellConfigPath: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
  readonly property string stayAwakePath: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"

  property int dimSeconds: 60
  property int celebrateSeconds: 30
  property string celebrateTiming: "before" // "before", "after", "both"
  property real minutes: 1.0
  property int dimPercentage: 25
  property bool enabled: true
  property bool stayAwake: false

  property bool celebrateEnabled: true
  property int celebrateDuration: 3
  property string celebrateColor: "gray"

  property int screensaverSeconds: 150

  property bool popupOpen: false
  readonly property bool opened: popupOpen

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  function formatSeconds(sec) {
    if (!sec || sec <= 0) return "Disabled"
    if (sec < 60) return sec + "s"
    var m = Math.floor(sec / 60)
    var s = sec % 60
    if (s === 0) return m === 1 ? "1 min" : m + " mins"
    return m + "m " + s + "s"
  }

  readonly property var allDimCandidates: [15, 30, 45, 60, 90, 120, 150, 180, 240, 300, 600]

  readonly property var dimOptions: {
    var maxSec = root.screensaverSeconds > 0 ? root.screensaverSeconds : 999999
    var list = []
    for (var i = 0; i < allDimCandidates.length; i++) {
      var sec = allDimCandidates[i]
      if (sec < maxSec) {
        list.push({ label: formatSeconds(sec), sec: sec })
      }
    }
    if (list.length === 0) {
      var fallback = Math.max(5, Math.floor(maxSec * 0.75))
      list.push({ label: formatSeconds(fallback), sec: fallback })
    }
    return list
  }

  readonly property var allCelebrateCandidates: [5, 10, 15, 20, 30, 45, 60, 90, 120, 180]

  readonly property var celebrateOptions: {
    var maxSec = root.dimSeconds
    var list = []
    for (var i = 0; i < allCelebrateCandidates.length; i++) {
      var sec = allCelebrateCandidates[i]
      if (sec < maxSec) {
        list.push({ label: formatSeconds(sec), sec: sec })
      }
    }
    list.push({ label: formatSeconds(maxSec) + " (On Dim)", sec: maxSec })
    return list
  }

  function setDimSeconds(sec) {
    root.dimSeconds = sec
    root.minutes = sec / 60.0
    if (root.celebrateSeconds > root.dimSeconds) {
      root.celebrateSeconds = root.dimSeconds
    }
    root.saveConfig()
  }

  function setCelebrateSeconds(sec) {
    root.celebrateSeconds = Math.min(sec, root.dimSeconds)
    root.saveConfig()
  }

  function applyShellConfig(raw) {
    var parsed = null
    if (raw && String(raw).trim() !== "") {
      try { parsed = JSON.parse(raw) } catch (e) { parsed = null }
    }
    if (parsed && parsed.idle && typeof parsed.idle.screensaver === "number" && parsed.idle.screensaver > 0) {
      root.screensaverSeconds = parsed.idle.screensaver
    } else {
      root.screensaverSeconds = 150
    }

    if (root.screensaverSeconds > 0 && root.dimSeconds >= root.screensaverSeconds) {
      var maxOpt = 15
      for (var i = 0; i < root.dimOptions.length; i++) {
        if (root.dimOptions[i].sec > maxOpt) maxOpt = root.dimOptions[i].sec
      }
      root.dimSeconds = maxOpt
      root.minutes = maxOpt / 60.0
      if (root.celebrateSeconds > root.dimSeconds) {
        root.celebrateSeconds = root.dimSeconds
      }
    }
  }

  function applyConfig(raw) {
    var parsed = null
    if (raw && String(raw).trim() !== "") {
      try { parsed = JSON.parse(raw) } catch (e) { parsed = null }
    }
    if (!parsed || typeof parsed !== "object") return

    if (typeof parsed.dimSeconds === "number" && parsed.dimSeconds > 0) {
      root.dimSeconds = Math.round(parsed.dimSeconds)
      root.minutes = root.dimSeconds / 60.0
    } else if (typeof parsed.minutes === "number" && parsed.minutes > 0) {
      root.dimSeconds = Math.max(1, Math.round(parsed.minutes * 60))
      root.minutes = parsed.minutes
    }

    if (typeof parsed.celebrateSeconds === "number" && parsed.celebrateSeconds > 0) {
      root.celebrateSeconds = Math.min(Math.round(parsed.celebrateSeconds), root.dimSeconds)
    } else {
      root.celebrateSeconds = root.dimSeconds
    }

    if (parsed.celebrateTiming === "before" || parsed.celebrateTiming === "after" || parsed.celebrateTiming === "both") {
      root.celebrateTiming = parsed.celebrateTiming
    } else {
      root.celebrateTiming = "before"
    }

    if (typeof parsed.dimPercentage === "number" && parsed.dimPercentage > 0 && parsed.dimPercentage <= 100) {
      root.dimPercentage = Math.round(parsed.dimPercentage)
    }
    if (typeof parsed.enabled === "boolean") root.enabled = parsed.enabled
    if (typeof parsed.celebrateEnabled === "boolean") root.celebrateEnabled = parsed.celebrateEnabled
    if (typeof parsed.celebrateDuration === "number" && parsed.celebrateDuration > 0) {
      root.celebrateDuration = Math.round(parsed.celebrateDuration)
    }
    if (parsed.celebrateColor === "dark-gray" || parsed.celebrateColor === "gray") {
      root.celebrateColor = parsed.celebrateColor
    }
  }

  function saveConfig() {
    var data = {
      dimSeconds: root.dimSeconds,
      celebrateSeconds: root.celebrateSeconds,
      celebrateTiming: root.celebrateTiming,
      minutes: root.minutes,
      dimPercentage: root.dimPercentage,
      enabled: root.enabled,
      celebrateEnabled: root.celebrateEnabled,
      celebrateDuration: root.celebrateDuration,
      celebrateColor: root.celebrateColor
    }
    var str = JSON.stringify(data, null, 2) + "\n"
    if (root.configFile && typeof root.configFile.setText === "function") {
      root.configFile.setText(str)
    } else {
      Quickshell.execDetached(["bash", "-c", "cat > \"$HOME/.config/omarchy/happy-dim.json\" << 'EOF'\n" + str + "EOF\ncp \"$HOME/.config/omarchy/happy-dim.json\" \"$HOME/.config/omarchy/auto-dim.json\" 2>/dev/null || true\n"])
    }
  }

  property FileView shellConfigFile: FileView {
    path: root.shellConfigPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyShellConfig(text())
    onLoadFailed: root.applyShellConfig("")
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
      root.shellConfigFile.reload()
      root.configFile.reload()
      root.stayAwakeFile.reload()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰃞"
    slotSize: Style.bar.iconSlot
    dimmed: !root.enabled
    active: root.enabled
    useActiveColor: false
    tooltipText: root.enabled
      ? ("Happy Dim (Dim: " + root.formatSeconds(root.dimSeconds) + " · " + root.dimPercentage + "%" + (root.celebrateEnabled ? (" · Celebrate: " + root.celebrateTiming) : "") + ")")
      : "Happy Dim (Disabled)"

    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.enabled = !root.enabled
        root.saveConfig()
      } else {
        root.toggle()
      }
    }
  }

  IpcHandler {
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    onOpenChanged: {
      if (root.popupOpen !== open) {
        root.popupOpen = open
      }
    }
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(contentCol.implicitHeight)

    Column {
      id: contentCol
      width: parent.width
      spacing: Style.space(12)

      // Header row
      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰃞"
          color: Commons.Color.accent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - toggleSwitch.width - Style.space(40)
          spacing: Style.space(2)

          Text {
            text: "Happy Dim"
            color: root.bar ? root.bar.barForeground : Commons.Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            text: root.enabled
              ? ("Dims after " + root.formatSeconds(root.dimSeconds) + (root.celebrateEnabled ? (" · Celebrate " + root.celebrateTiming + " reset") : ""))
              : "Auto dimming paused"
            color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        ToggleSwitch {
          id: toggleSwitch
          anchors.verticalCenter: parent.verticalCenter
          checked: root.enabled
          onToggled: {
            root.enabled = !root.enabled
            root.saveConfig()
          }
        }
      }

      // Screensaver Information Card
      BorderSurface {
        width: parent.width
        radius: Style.cornerRadius
        color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.08)
        borderSpec: Border.controlSpec("normal", root.bar ? root.bar.barForeground : Commons.Color.foreground, Commons.Color.accent)
        implicitHeight: ssRow.implicitHeight + Style.space(16)

        Row {
          id: ssRow
          anchors.fill: parent
          anchors.margins: Style.space(10)
          spacing: Style.space(10)

          Text {
            text: "󰍹"
            color: Commons.Color.accent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(40)
            spacing: Style.space(2)

            Row {
              spacing: Style.space(6)
              Text {
                text: "Screensaver Timeout:"
                color: root.bar ? root.bar.barForeground : Commons.Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
              Text {
                text: root.screensaverSeconds > 0 ? (root.formatSeconds(root.screensaverSeconds) + " (" + root.screensaverSeconds + "s)") : "Disabled"
                color: Commons.Color.accent
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }

            Text {
              text: "System limit from shell.json. Screen dimming is constrained below this countdown."
              color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.55)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
              width: parent.width
            }
          }
        }
      }

      PanelSeparator {
        width: parent.width
        foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
      }

      // Countdown to Dim Setting (Limited by screensaver)
      Column {
        width: parent.width
        spacing: Style.space(6)

        Row {
          spacing: Style.space(6)
          Text {
            text: "COUNTDOWN TO DIM"
            color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            text: "(Limit: < " + root.formatSeconds(root.screensaverSeconds) + ")"
            color: Commons.Color.accent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.dimOptions

            Button {
              required property var modelData
              text: modelData.label
              selected: root.dimSeconds === modelData.sec
              active: selected
              bordered: true
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: root.setDimSeconds(modelData.sec)
            }
          }
        }
      }

      // Dim Level Setting
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "DIM LEVEL (% OF CURRENT)"
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(8)

          Repeater {
            model: [
              { label: "25% (very dim)", val: 25 },
              { label: "50% (half)",      val: 50 },
              { label: "75% (subtle)",    val: 75 }
            ]

            Button {
              required property var modelData
              text: modelData.label
              selected: root.dimPercentage === modelData.val
              active: selected
              bordered: true
              horizontalPadding: Style.space(10)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: {
                root.dimPercentage = modelData.val
                root.saveConfig()
              }
            }
          }
        }
      }

      PanelSeparator {
        width: parent.width
        foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
      }

      // Celebrate Settings Section
      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰐝"
          color: Commons.Color.accent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - celebrateToggle.width - Style.space(40)
          spacing: Style.space(2)

          Text {
            text: "Bar Icon Celebration"
            color: root.bar ? root.bar.barForeground : Commons.Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            text: {
              if (!root.celebrateEnabled) return "Celebrate disabled"
              if (root.celebrateTiming === "before") return "Flashes on idle (" + root.celebrateDuration + "s) before reset"
              if (root.celebrateTiming === "after") return "Flashes on wake-up (" + root.celebrateDuration + "s) after reset"
              return "Flashes both on idle and after reset"
            }
            color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        ToggleSwitch {
          id: celebrateToggle
          anchors.verticalCenter: parent.verticalCenter
          checked: root.celebrateEnabled
          onToggled: {
            root.celebrateEnabled = !root.celebrateEnabled
            root.saveConfig()
          }
        }
      }

      // Celebrate Timing Setting (Before / After Reset / Both)
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled

        Text {
          text: "CELEBRATE TIMING"
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(6)

          Repeater {
            model: [
              { label: "Before Reset (Idle)", val: "before" },
              { label: "After Reset (Wake)", val: "after" },
              { label: "Both", val: "both" }
            ]

            Button {
              required property var modelData
              text: modelData.label
              selected: root.celebrateTiming === modelData.val
              active: selected
              bordered: true
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: {
                root.celebrateTiming = modelData.val
                root.saveConfig()
              }
            }
          }
        }

        Text {
          text: {
            if (root.celebrateTiming === "before") return "Celebrates when idle countdown triggers, before user returns."
            if (root.celebrateTiming === "after") return "Celebrates when user activity returns / screen wakes up from dim."
            return "Celebrates on idle, and celebrates again upon waking up!"
          }
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      // Countdown to Celebrate Setting (Visible when timing is "before" or "both")
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled && root.celebrateTiming !== "after"

        Row {
          spacing: Style.space(6)
          Text {
            text: "COUNTDOWN TO CELEBRATE"
            color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            text: "(Limit: ≤ " + root.formatSeconds(root.dimSeconds) + ")"
            color: Commons.Color.accent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.celebrateOptions

            Button {
              required property var modelData
              text: modelData.label
              selected: root.celebrateSeconds === modelData.sec
              active: selected
              bordered: true
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: root.setCelebrateSeconds(modelData.sec)
            }
          }
        }
      }

      // Celebrate Duration
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled

        Text {
          text: "CELEBRATE FLASH DURATION"
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(6)

          Repeater {
            model: [
              { label: "1s", val: 1 },
              { label: "2s", val: 2 },
              { label: "3s", val: 3 },
              { label: "5s", val: 5 },
              { label: "8s", val: 8 }
            ]

            Button {
              required property var modelData
              text: modelData.label
              selected: root.celebrateDuration === modelData.val
              active: selected
              bordered: true
              horizontalPadding: Style.space(10)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: {
                root.celebrateDuration = modelData.val
                root.saveConfig()
              }
            }
          }
        }
      }

      // Post-Celebrate Color (For idle transition)
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled && root.celebrateTiming !== "after"

        Text {
          text: "POST-CELEBRATE COLOR (IDLE)"
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(8)

          Button {
            text: "● Gray"
            selected: root.celebrateColor === "gray"
            active: selected
            bordered: true
            horizontalPadding: Style.space(12)
            verticalPadding: Style.space(4)
            foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
            onClicked: {
              root.celebrateColor = "gray"
              root.saveConfig()
            }
          }

          Button {
            text: "● Dark Gray"
            selected: root.celebrateColor === "dark-gray"
            active: selected
            bordered: true
            horizontalPadding: Style.space(12)
            verticalPadding: Style.space(4)
            foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
            onClicked: {
              root.celebrateColor = "dark-gray"
              root.saveConfig()
            }
          }
        }
      }

      PanelSeparator {
        width: parent.width
        foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
      }

      // Status indicator & Actions
      Row {
        width: parent.width
        spacing: Style.space(8)

        Column {
          width: parent.width - applyBtn.width - testBtn.width - Style.space(16)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Row {
            spacing: Style.space(5)
            Rectangle {
              width: Style.space(7)
              height: Style.space(7)
              radius: width / 2
              anchors.verticalCenter: parent.verticalCenter
              color: !root.enabled ? "#888888" : (root.stayAwake ? "#ffaa00" : Commons.Color.accent)
            }
            Text {
              text: !root.enabled ? "Paused" : (root.stayAwake ? "Stay Awake active" : "Monitoring idle")
              color: root.bar ? root.bar.barForeground : Commons.Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        Button {
          id: applyBtn
          text: "Apply"
          iconText: "󰑓"
          bordered: true
          horizontalPadding: Style.space(10)
          verticalPadding: Style.space(4)
          foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
          onClicked: {
            root.saveConfig()
            Quickshell.execDetached(["bash", "-c", "sleep 0.3 && omarchy-shell shell rescanPlugins"])
          }
        }

        Button {
          id: testBtn
          text: root.celebrateEnabled ? "Test" : "Test Dim"
          iconText: "󰃜"
          bordered: true
          horizontalPadding: Style.space(10)
          verticalPadding: Style.space(4)
          foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
          onClicked: {
            var dur = root.celebrateEnabled ? root.celebrateDuration : 0
            var col = root.celebrateColor
            var timing = root.celebrateTiming
            var dimPct = root.dimPercentage
            var waitSec = (dur > 0 ? dur + 2 : 3)

            var beforeCelebrate = (root.celebrateEnabled && (timing === "before" || timing === "both"))
              ? "omarchy-shell zm.celebrate startWith " + (dur * 1000) + " " + col + "\n"
              : ""

            var afterCelebrate = (root.celebrateEnabled && (timing === "after" || timing === "both"))
              ? "omarchy-shell zm.celebrate startWith " + ((dur + 5) * 1000) + " gray\nsleep " + dur + "\nomarchy-shell zm.celebrate reset\n"
              : "omarchy-shell zm.celebrate reset\n"

            Quickshell.execDetached(["bash", "-c",
              "orig=$(omarchy brightness display)\n" +
              "half=$(( orig * " + dimPct + " / 100 ))\n" +
              "(( half < 1 )) && half=1\n" +
              beforeCelebrate +
              "omarchy brightness display --no-osd \"${half}%\"\n" +
              "sleep " + waitSec + "\n" +
              "omarchy brightness display --no-osd \"${orig}%\"\n" +
              afterCelebrate
            ])
          }
        }
      }
    }
  }
}
