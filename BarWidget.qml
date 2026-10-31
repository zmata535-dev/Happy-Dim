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
  readonly property string stayAwakePath: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"

  property real minutes: 1.0
  property int dimPercentage: 25
  property bool enabled: true
  property bool stayAwake: false

  property bool celebrateEnabled: true
  property int celebrateDuration: 3
  property string celebrateColor: "gray"

  property bool popupOpen: false
  readonly property bool opened: popupOpen

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  readonly property string minutesLabel: {
    if (minutes < 0.5) return Math.round(minutes * 60) + "s"
    if (minutes < 1.0) return Math.round(minutes * 60) + "s"
    if (minutes === 1.0) return "1 min"
    return minutes + " mins"
  }

  function applyConfig(raw) {
    var parsed = null
    if (raw && String(raw).trim() !== "") {
      try { parsed = JSON.parse(raw) } catch (e) { parsed = null }
    }
    if (!parsed || typeof parsed !== "object") return

    if (typeof parsed.minutes === "number" && parsed.minutes > 0) root.minutes = parsed.minutes
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
    tooltipText: root.enabled ? ("Happy Dim (" + root.minutesLabel + " · " + root.dimPercentage + "%" + (root.celebrateEnabled ? " · Celebrate" : "") + ")") : "Happy Dim (Disabled)"

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
    contentWidth: popup.fittedContentWidth(Style.space(330))
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
            text: root.enabled ? ("Dims display after " + root.minutesLabel + (root.celebrateEnabled ? " + Celebrate" : "")) : "Auto dimming paused"
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

      PanelSeparator {
        width: parent.width
        foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
      }

      // Timeout Setting
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "TIME BEFORE CELEBRATE & DIM"
          color: Qt.rgba(root.bar ? root.bar.barForeground.r : 1, root.bar ? root.bar.barForeground.g : 1, root.bar ? root.bar.barForeground.b : 1, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(5)

          Repeater {
            model: [
              { label: "15s", val: 0.25 },
              { label: "30s", val: 0.5 },
              { label: "1m",  val: 1.0 },
              { label: "2m",  val: 2.0 },
              { label: "3m",  val: 3.0 },
              { label: "5m",  val: 5.0 },
              { label: "10m", val: 10.0 }
            ]

            Button {
              required property var modelData
              text: modelData.label
              selected: Math.abs(root.minutes - modelData.val) < 0.01
              active: selected
              bordered: true
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(4)
              foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
              onClicked: {
                root.minutes = modelData.val
                root.saveConfig()
              }
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
            text: "Celebrate on Dim"
            color: root.bar ? root.bar.barForeground : Commons.Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            text: root.celebrateEnabled ? ("Flashes " + root.celebrateDuration + "s then " + root.celebrateColor) : "Celebrate disabled"
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

      // Celebrate Duration
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled

        Text {
          text: "CELEBRATE DURATION"
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

      // Post-Celebrate Color
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.celebrateEnabled

        Text {
          text: "POST-CELEBRATE COLOR"
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

      // Status indicator & Test action
      Row {
        width: parent.width
        spacing: Style.space(8)

        Column {
          width: parent.width - testBtn.width - Style.space(8)
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
          id: testBtn
          text: root.celebrateEnabled ? "Test Celebrate" : "Test Dim"
          iconText: "󰃜"
          bordered: true
          horizontalPadding: Style.space(10)
          verticalPadding: Style.space(4)
          foreground: root.bar ? root.bar.barForeground : Commons.Color.foreground
          onClicked: {
            var dur = root.celebrateEnabled ? root.celebrateDuration : 0
            var col = root.celebrateColor
            var celebrateCmd = root.celebrateEnabled
              ? "omarchy-shell zm.celebrate startWith " + (dur * 1000) + " " + col + "\n"
              : ""
            var resetCmd = root.celebrateEnabled
              ? "omarchy-shell zm.celebrate reset\n"
              : ""
            var waitSec = (dur > 0 ? dur + 2 : 3)
            Quickshell.execDetached(["bash", "-c",
              "orig=$(omarchy brightness display)\n" +
              "half=$(( orig * " + root.dimPercentage + " / 100 ))\n" +
              "(( half < 1 )) && half=1\n" +
              celebrateCmd +
              "omarchy brightness display --no-osd \"${half}%\"\n" +
              "sleep " + waitSec + "\n" +
              "omarchy brightness display --no-osd \"${orig}%\"\n" +
              resetCmd
            ])
          }
        }
      }
    }
  }
}
