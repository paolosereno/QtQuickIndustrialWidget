<!--
SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>

SPDX-License-Identifier: MIT
-->

# QtQuickIndustrialWidgets ⚡

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Qt Version](https://img.shields.io/badge/Qt-6.x%20(Qt%20Quick)-41CD52.svg?logo=qt)](https://www.qt.io/)
[![Status: Pre-Alpha](https://img.shields.io/badge/Status-Initial%20Development%20(Unstable)-yellow.svg)](#status)

A modern, high-performance **Qt Quick / QML** instrumentation and SCADA widget suite designed for embedded Linux, touchscreens, test benches, automotive clusters, and industrial HMIs.

This project is the native Qt Quick evolution of the [**QtIndustrialWidgets**](https://github.com/paolosereno/QtIndustrialWidgets) (`QtWidgets`) C++ library.

---

> [!WARNING]
> ### ⚠️ Project Status: Initial Development / Experimental
> This library is currently in an **early, initial stage of development**.
> The widgets, QML APIs, property names, and behavior are **not yet considered stable** and may undergo breaking changes, refactoring, and substantial revisions. Do not use in critical production environments without thorough testing.

---

## 🎯 Vision & Goals

While the original `QtIndustrialWidgets` excels in traditional desktop `QtWidgets` applications, modern industrial HMIs, automotive dashboards, and medical devices increasingly demand:

- **GPU Acceleration:** High frame rates (60+ FPS) with minimal CPU load via Qt Quick Scene Graph (`QSGNode`) and native `QtQuick.Shapes`.
- **Touch-Friendly Controls:** Smooth capacitive-touch gestures, fluid animations, and responsive state transitions.
- **Declarative QML API:** Clean property bindings, easy theming, and modern design integration without boilerplate code.
- **Cross-Platform & Embedded Ready:** Optimized for desktop (Windows, macOS, Linux) and resource-constrained embedded targets (Raspberry Pi, Toradex, i.MX8, STM32MP1).

---

## 🎛 Widget Suite Roadmap & Status

We are porting the complete set of 12 industrial widgets:

| Category | Component | Description | Status |
| :--- | :--- | :--- | :--- |
| **Displays & Readouts** | `SevenSegmentDisplay` | Multi-digit vector LED/LCD display with decimal points and ghost segments. | ⏳ Planned |
| | `LedIndicator` | Configurable multi-state status LEDs with realistic lens diffusion. | 🧪 Experimental (Preview) |
| | `LevelMeter` | Stereo dB meter with peak-hold for telemetry and audio signals. | ⏳ Planned |
| **Gauges & Dials** | `RadialGauge` | Circular & semicircular dials (RPM, pressure, speed) with warning zones. | 🧪 Experimental (Preview) |
| | `LinearGauge` | Vertical/horizontal column and thermometer bar displays. | ⏳ Planned |
| | `CircularBargraph` | Segmented arc bargraph with peak memory. | ⏳ Planned |
| | `Compass` | Heading indicator card with heading bug alignment. | ⏳ Planned |
| **Controls** | `IndustrialKnob` | Smooth/stepped rotary knob with realistic knurling and gesture support. | 🧪 Experimental (Preview) |
| | `IndustrialSwitch` | Toggle switches, rockers, and safety-guarded toggle covers. | ⏳ Planned |
| **Alarms & Charts** | `AnnunciatorPanel` | ISA-18.1 compliant alarm annunciator tiles (unack, ack, ringback). | ⏳ Planned |
| | `StripChart` | High-frequency rolling telemetry stream plotting. | ⏳ Planned |
| | `AnalysisChart` | Historical data review chart with zoom/pan capabilities. | ⏳ Planned |

---

## 🏗 Quick Start in QML

The library is packaged as a standard Qt 6 QML module (`QtQuickIndustrialWidgets`):

```qml
import QtQuick
import QtQuick.Controls
import QtQuickIndustrialWidgets

Item {
    width: 640
    height: 480

    Row {
        anchors.centerIn: parent
        spacing: 30

        LedIndicator {
            labelText: "SYSTEM READY"
            on: true
            onColor: "#2ecc71"
        }

        RadialGauge {
            width: 220
            height: 220
            value: 65.0
            minimum: 0
            maximum: 100
            unit: "bar"
            warningThreshold: 75
            errorThreshold: 90
        }

        IndustrialKnob {
            width: 200
            height: 220
            value: 40.0
            minimum: 0
            maximum: 100
            unit: "%"
        }
    }
}
```

---

## 🚀 Building & Running the Gallery

The project provides an interactive SCADA dashboard gallery demonstrating the components with live simulated telemetry and interactive controls.

### Prerequisites
- Qt 6.5+ (`qtbase`, `declarative`, `quick`, `quickshapes`)
- CMake 3.21+
- C++17 compatible compiler (GCC, Clang, or MSVC)

### Build Instructions
```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Launch the interactive gallery
./build/examples/gallery/gallery
```

---

## 📄 License

[MIT](LICENSE) (SPDX: `MIT`, full text in [LICENSES/MIT.txt](LICENSES/MIT.txt)).
Every file carries SPDX copyright and license information, compliant with the [REUSE specification](https://reuse.software/).

Copyright (c) 2026 Paolo Sereno.
