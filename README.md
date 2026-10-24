# QtQuickIndustrialWidgets ⚡

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Qt Version](https://img.shields.io/badge/Qt-6.x%20(Qt%20Quick)-41CD52.svg?logo=qt)](https://www.qt.io/)
[![Status](https://img.shields.io/badge/Status-Under%20Active%20Development-orange.svg)](#roadmap)

A modern, high-performance **Qt Quick / QML** instrumentation and SCADA widget suite designed for embedded Linux, touchscreens, test benches, automotive clusters, and industrial HMIs.

This project is the native Qt Quick evolution of the popular [**QtIndustrialWidgets**](https://github.com/paolosereno/QtIndustrialWidgets) (`QtWidgets`) C++ library.

---

## 🎯 Vision & Goals

While the original `QtIndustrialWidgets` excels in traditional desktop `QtWidgets` applications, modern industrial HMIs, automotive dashboards, and medical devices increasingly demand:

- **GPU Acceleration:** High frame rates (60+ FPS) with minimal CPU load via Qt Quick Scene Graph (`QSGNode`).
- **Touch-Friendly Controls:** Smooth capacitive-touch gestures, fluid animations, and responsive state transitions.
- **Declarative QML API:** Clean property bindings, easy theming, and modern design integration without boilerplate code.
- **Cross-Platform & Embedded Ready:** Optimized for desktop (Windows, macOS, Linux) and resource-constrained embedded targets (Raspberry Pi, Toradex, i.MX8, STM32MP1).

---

## 🎛 Planned Widget Suite

We are porting the complete set of 12 proven industrial widgets:

| Category | Component | Description |
| :--- | :--- | :--- |
| **Displays & Readouts** | `SevenSegmentDisplay` | Multi-digit vector LED/LCD display with decimal points and ghost segments. |
| | `LedIndicator` | Configurable multi-state status LEDs with realistic lens diffusion. |
| | `LevelMeter` | Stereo dB meter with peak-hold for telemetry and audio signals. |
| **Gauges & Dials** | `RadialGauge` | Circular & semicircular dials (RPM, pressure, speed) with warning zones. |
| | `LinearGauge` | Vertical/horizontal column and thermometer bar displays. |
| | `CircularBargraph` | Segmented arc bargraph with peak memory. |
| | `Compass` | Heading indicator card with heading bug alignment. |
| **Controls** | `IndustrialKnob` | Smooth/stepped rotary knob with realistic knurling and gesture support. |
| | `IndustrialSwitch` | Toggle switches, rockers, and safety-guarded toggle covers. |
| **Alarms & Charts** | `AnnunciatorPanel` | ISA-18.1 compliant alarm annunciator tiles (unack, ack, ringback). |
| | `StripChart` | High-frequency rolling telemetry stream plotting. |
| | `AnalysisChart` | Historical data review chart with zoom/pan capabilities. |

---

## 🏗 Planned Usage in QML

The goal is to provide a plug-and-play QML module (`qt_add_qml_module`):

```qml
import QtQuick
import QtQuick.Controls
import QtQuickIndustrialWidgets

Item {
    width: 640
    height: 480

    Row {
        anchors.centerIn: parent
        spacing: 20

        SevenSegmentDisplay {
            digits: 4
            value: "12.34"
            colorPreset: "amber"
            showGhostSegments: true
        }

        RadialGauge {
            value: telemetrySource.speed
            minimumValue: 0
            maximumValue: 240
            unit: "km/h"
        }
    }
}
