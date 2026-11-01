# Happy Dim 󰃞 󰐝

An aesthetic, energy-saving **Auto-Dim & Icon Celebrate** shell plugin for [Omarchy](https://omarchy.org/) Linux (Hyprland + Quickshell).

When inactivity is detected, **Happy Dim** dims your display to save battery/screen life and triggers a dazzling **celebration flash** across your status bar icons, transitioning into a soothing dimmed gray until you return. Any user activity instantly restores your display brightness and theme colors.

---

## ✨ Features

- **🌙 Display Auto-Dimming**: Automatically dims your screen brightness by a customizable factor (25%, 50%, or 75%) after a configurable period of inactivity.
- **🖥️ Screensaver Aware**: Reads your system's screensaver deadline from `~/.config/omarchy/shell.json` (`idle.screensaver`), prominently displaying it in the settings card and dynamically constraining the dimming countdown below this deadline.
- **🎉 Celebrate Timing (Before, After, or Both)**:
  - **Before Reset (Idle)**: Celebrate when inactivity countdown triggers, before any user activity reset.
  - **After Reset (Wake)**: Celebrate when user activity returns / display wakes up from dim (welcome-back celebration).
  - **Both**: Celebrate on idle, and celebrate again upon waking up!
- **⏱️ Independent Celebrate Countdown**: Choose an independent countdown for status bar celebration (when timing is Before or Both), dynamically limited by your chosen Dim countdown.
- **🌫️ Post-Celebrate Transition**: After the flashing duration on idle, icons smoothly transition into either **Neutral Gray** (`#808080`) or **Dark Gray** (`#404040`).
- **⚡ Multi-Vector Instant Wake**: As soon as any activity occurs (mouse movement, keypress, workspace switch, window focus, or bar hover), display brightness and bar colors seamlessly return to normal.
- **☕ Respects Stay Awake**: Automatically pauses dimming whenever Omarchy's system `stay-awake` indicator is active.
- **🎛️ Interactive Settings Popup**: Configure all parameters directly from the status bar popup menu, with an **Apply** button to reload service changes immediately.

---

## 📸 Settings GUI

Clicking the `󰃞` bar widget opens the settings popup:

1. **Screensaver Info Banner**: Shows current system screensaver timeout (e.g. `2m 30s (150s)`) and explains that dimming occurs before this limit.
2. **Countdown to Dim**: Dynamic choices constrained strictly below the screensaver timeout (`15s`, `30s`, `45s`, `1m`, `1m 30s`, `2m`, etc.).
3. **Dim Level**: Choose `25% (very dim)`, `50% (half)`, or `75% (subtle)`.
4. **Celebrate Toggle**: Turn the icon celebration effect on or off.
5. **Celebrate Timing**:
   - `● Before Reset (Idle)`: Flashes when idle begins.
   - `● After Reset (Wake)`: Flashes upon waking up from dim.
   - `● Both`: Flashes both on idle and upon waking up!
6. **Countdown to Celebrate**: Dynamic choices constrained to `≤ Dim countdown` (visible when timing is Before or Both).
7. **Celebrate Flash Duration**: Choose `1s`, `2s`, `3s`, `5s`, or `8s`.
8. **Post-Celebrate Color**: Switch between **`● Gray`** and **`● Dark Gray`**.
9. **Apply Button**: Instantly reloads plugins and restarts the service with your changes.
10. **Test Button**: Live test the entire celebrate + dim sequence according to your selected timing mode.

---

## 🚀 Installation

### 1. Install via Omarchy Plugin Manager

```bash
omarchy plugin add https://github.com/zmata535-dev/Happy-Dim.git --enable --yes
```

### 2. Status Bar Celebrate Setup

To enable the icon celebration and post-celebrate gray animation on your status bar, run the setup script:

```bash
~/.config/omarchy/plugins/zm.happy-dim/scripts/setup-bar.sh
```

---

## 💻 CLI Commands

The plugin provides a standalone `celebrate` CLI helper:

```bash
# Flash the bar using your configured auto-dim duration & color:
celebrate

# Override duration (seconds) and color on the fly:
celebrate 2 dark-gray
celebrate 5 gray

# Manually reset anytime:
celebrate reset
```

Or via Quickshell IPC directly:

```bash
# Open / Close / Toggle Settings popup:
omarchy-shell zm.happy-dim toggle

# Trigger celebration:
omarchy-shell zm.celebrate start

# Trigger with custom duration (ms) and color:
omarchy-shell zm.celebrate startWith 3000 dark-gray

# Reset bar back to normal theme colors:
omarchy-shell zm.celebrate reset
```

---

## ⚙️ Configuration File

Settings are saved in `~/.config/omarchy/happy-dim.json`:

```json
{
  "dimSeconds": 60,
  "celebrateSeconds": 30,
  "celebrateTiming": "before",
  "minutes": 1.0,
  "dimPercentage": 25,
  "enabled": true,
  "celebrateEnabled": true,
  "celebrateDuration": 3,
  "celebrateColor": "gray"
}
```

---

## 📄 License

[MIT](LICENSE) © 2026 [zmata535-dev](https://github.com/zmata535-dev)
