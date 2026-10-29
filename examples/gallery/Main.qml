// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuickIndustrialWidgets

ApplicationWindow {
    id: appWindow
    width: 1200
    height: 820
    minimumWidth: 850
    minimumHeight: 600
    visible: true
    title: "QtQuickIndustrialWidgets — Native Qt 6 SCADA Suite"
    color: "#0f1218"

    // --- Simulated Telemetry Generator ---
    property bool simulationRunning: true
    property real simTime: 0.0

    Timer {
        interval: 33 // ~30 FPS telemetry updates
        running: appWindow.simulationRunning
        repeat: true
        onTriggered: {
            appWindow.simTime += 0.04
            // Fluctuating realistic industrial metrics
            rpmGauge.value = 3200 + Math.sin(appWindow.simTime * 0.8) * 2800 + Math.sin(appWindow.simTime * 3.1) * 350
            pressureGauge.value = 55 + Math.sin(appWindow.simTime * 0.5) * 32 + Math.cos(appWindow.simTime * 1.7) * 8
            tempGauge.value = 72 + Math.sin(appWindow.simTime * 0.3) * 22

            if (typeof stereoMeter !== "undefined" && stereoMeter) {
                const audioL = -18.0 + Math.sin(appWindow.simTime * 2.5) * 12.0 + Math.cos(appWindow.simTime * 5.7) * 6.0
                const audioR = -20.0 + Math.sin(appWindow.simTime * 2.3 + 0.5) * 14.0 + Math.cos(appWindow.simTime * 4.9) * 5.0
                stereoMeter.setValue(0, audioL)
                stereoMeter.setValue(1, audioR)
            }
            if (typeof tankMeter !== "undefined" && tankMeter) {
                tankMeter.setValue(0, 65 + Math.sin(appWindow.simTime * 0.4) * 20)
                tankMeter.setValue(1, 42 + Math.sin(appWindow.simTime * 0.3 + 1.0) * 15)
                tankMeter.setValue(2, 88 + Math.cos(appWindow.simTime * 0.2) * 8)
                tankMeter.setValue(3, 25 + Math.sin(appWindow.simTime * 0.6) * 18)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ====================================================================
        // Top Control / Status Bar (Matching C++ MainWindow topBar)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: "#181d27"
            radius: 8
            border.color: "#273142"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "QtQuickIndustrialWidgets ⚡"
                        font.pixelSize: 17
                        font.bold: true
                        color: "#f5f6fa"
                    }
                    Text {
                        text: "Native Qt 6 QML Instrumentation & SCADA Suite"
                        font.pixelSize: 11
                        color: "#8a95a5"
                    }
                }

                Item { Layout.fillWidth: true }

                // Top Bar Status Annunciator LEDs
                RowLayout {
                    spacing: 14

                    LedIndicator {
                        labelText: "RUN"
                        on: appWindow.simulationRunning
                        onColor: "#2ecc71"
                        textColor: "#d2dae2"
                    }

                    LedIndicator {
                        labelText: "WARN"
                        on: pressureGauge.value >= pressureGauge.warningThreshold
                        blinking: on
                        blinkRateMs: 380
                        onColor: "#fed330"
                        textColor: "#d2dae2"
                    }

                    LedIndicator {
                        labelText: "FAULT"
                        on: tempGauge.value >= tempGauge.errorThreshold
                        blinking: on
                        blinkRateMs: 180
                        onColor: "#eb3b5a"
                        textColor: "#d2dae2"
                    }

                    LedIndicator {
                        shape: LedIndicator.Shape.Rectangular
                        labelText: "AUX PUMP"
                        on: true
                        onColor: "#00e5ff"
                        textColor: "#d2dae2"
                    }

                    Button {
                        text: appWindow.simulationRunning ? "Pause Sim" : "Resume Sim"
                        onClicked: appWindow.simulationRunning = !appWindow.simulationRunning
                    }
                }
            }
        }

        // ====================================================================
        // Navigation Tab Bar
        // ====================================================================
        TabBar {
            id: mainTabBar
            Layout.fillWidth: true
            currentIndex: 0

            background: Rectangle {
                color: "#141822"
                radius: 6
            }

            TabButton {
                text: "📊  SCADA Overview"
                width: implicitWidth + 24
            }
            TabButton {
                text: "🎛️  Radial Gauges"
                width: implicitWidth + 24
            }
            TabButton {
                text: "💡  Status LEDs"
                width: implicitWidth + 24
            }
            TabButton {
                text: "🎚️  Industrial Knobs"
                width: implicitWidth + 24
            }
            TabButton {
                text: "🔢  7-Segment Displays"
                width: implicitWidth + 24
            }
            TabButton {
                text: "🌡️  Linear Gauges"
                width: implicitWidth + 24
            }
            TabButton {
                text: "🔌  Industrial Switches"
                width: implicitWidth + 24
            }
            TabButton {
                text: "📶  Level Meters"
                width: implicitWidth + 24
            }
        }

        // ====================================================================
        // Tab Content Views (StackLayout)
        // ====================================================================
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabBar.currentIndex

            // ----------------------------------------------------------------
            // TAB 0: SCADA Overview (Dashboard + Controls + Indicators)
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                RowLayout {
                    width: parent.width
                    spacing: 16

                    // Left Panel: Main Gauges
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 480
                        Layout.preferredHeight: 640
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Text {
                                text: "Live Telemetry Powertrain"
                                font.pixelSize: 15
                                font.bold: true
                                color: "#f5f6fa"
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 2
                                rowSpacing: 16
                                columnSpacing: 16

                                // Gauge 1: RPM
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignCenter
                                    spacing: 4
                                    RadialGauge {
                                        id: rpmGauge
                                        width: 210
                                        height: 210
                                        Layout.preferredWidth: 210
                                        Layout.preferredHeight: 210
                                        minimum: 0
                                        maximum: 8000
                                        precision: 0
                                        unit: "RPM"
                                        warningThreshold: 6000
                                        errorThreshold: 7200
                                        majorTicks: 8
                                        minorTicks: 4
                                    }
                                    Text {
                                        text: "Engine Tachometer"
                                        font.pixelSize: 12
                                        color: "#8a95a5"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                // Gauge 2: Pressure
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignCenter
                                    spacing: 4
                                    RadialGauge {
                                        id: pressureGauge
                                        width: 210
                                        height: 210
                                        Layout.preferredWidth: 210
                                        Layout.preferredHeight: 210
                                        minimum: 0
                                        maximum: 100
                                        precision: 1
                                        unit: "bar"
                                        warningThreshold: 70
                                        errorThreshold: 85
                                        majorTicks: 10
                                        minorTicks: 4
                                    }
                                    Text {
                                        text: "Hydraulic Pressure"
                                        font.pixelSize: 12
                                        color: "#8a95a5"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                // Gauge 3: Temperature
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignCenter
                                    spacing: 4
                                    RadialGauge {
                                        id: tempGauge
                                        width: 210
                                        height: 210
                                        Layout.preferredWidth: 210
                                        Layout.preferredHeight: 210
                                        minimum: 0
                                        maximum: 120
                                        precision: 1
                                        unit: "°C"
                                        warningThreshold: 80
                                        errorThreshold: 100
                                        majorTicks: 6
                                        minorTicks: 3
                                    }
                                    Text {
                                        text: "Core Temperature"
                                        font.pixelSize: 12
                                        color: "#8a95a5"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                // Gauge 4: Interactive PSI
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignCenter
                                    spacing: 4
                                    RadialGauge {
                                        id: interactiveGauge
                                        width: 210
                                        height: 210
                                        Layout.preferredWidth: 210
                                        Layout.preferredHeight: 210
                                        minimum: 0
                                        maximum: 100
                                        value: testSlider.value
                                        precision: 1
                                        unit: "PSI"
                                        warningThreshold: 65
                                        errorThreshold: 85
                                        majorTicks: 10
                                        minorTicks: 4
                                    }
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 6
                                        Text { text: "0"; color: "#8a95a5"; font.pixelSize: 10 }
                                        Slider {
                                            id: testSlider
                                            from: 0
                                            to: 100
                                            value: 45.0
                                            Layout.preferredWidth: 130
                                        }
                                        Text { text: "100"; color: "#8a95a5"; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }
                    }

                    // Right Panel: Controls & LEDs
                    ColumnLayout {
                        Layout.preferredWidth: 380
                        Layout.minimumWidth: 340
                        Layout.preferredHeight: 640
                        spacing: 16

                        // Pilot LEDs Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "Annunciator Status (LedIndicator)"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                }

                                ColumnLayout {
                                    spacing: 10

                                    LedIndicator {
                                        labelText: "MAIN POWER (Click to toggle)"
                                        on: true
                                        clickable: true
                                        onColor: "#2ecc71"
                                    }

                                    LedIndicator {
                                        labelText: "HIGH PRESSURE WARNING"
                                        on: pressureGauge.value >= pressureGauge.warningThreshold
                                        blinking: on
                                        blinkRateMs: 380
                                        onColor: "#fed330"
                                    }

                                    LedIndicator {
                                        labelText: "CORE OVERHEAT CRITICAL"
                                        on: tempGauge.value >= tempGauge.errorThreshold
                                        blinking: on
                                        blinkRateMs: 200
                                        onColor: "#eb3b5a"
                                    }

                                    LedIndicator {
                                        labelText: "TELEMETRY LINK ACTIVE"
                                        on: appWindow.simulationRunning
                                        onColor: "#00e5ff"
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#273142"
                                }

                                Text {
                                    text: "Rectangular Pilot Lamps"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }

                                RowLayout {
                                    spacing: 24

                                    LedIndicator {
                                        shape: LedIndicator.Shape.Rectangular
                                        labelText: "VALVE 1"
                                        on: true
                                        onColor: "#2ecc71"
                                        clickable: true
                                    }

                                    LedIndicator {
                                        shape: LedIndicator.Shape.Rectangular
                                        labelText: "COOLANT 2"
                                        on: true
                                        blinking: true
                                        blinkRateMs: 500
                                        onColor: "#fed330"
                                    }
                                }
                            }
                        }

                        // Rotary Knobs Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 310
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                Text {
                                    text: "Rotary Setpoints (IndustrialKnob)"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 16

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignCenter
                                        spacing: 4

                                        IndustrialKnob {
                                            id: flowKnob
                                            width: 150
                                            height: 175
                                            Layout.preferredWidth: 150
                                            Layout.preferredHeight: 175
                                            minimum: 0
                                            maximum: 100
                                            value: 65
                                            step: 1
                                            unit: "%"
                                            pointerColor: "#00e5ff"
                                            trackColor: "#00e5ff"
                                        }

                                        Text {
                                            text: "Flow Rate (Continuous)"
                                            font.pixelSize: 11
                                            color: "#8a95a5"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignCenter
                                        spacing: 4

                                        IndustrialKnob {
                                            id: modeKnob
                                            width: 150
                                            height: 175
                                            Layout.preferredWidth: 150
                                            Layout.preferredHeight: 175
                                            mode: IndustrialKnob.Mode.Discrete
                                            discreteSteps: 5
                                            minimum: 1
                                            maximum: 5
                                            value: 3
                                            precision: 0
                                            unit: "ST"
                                            pointerColor: "#fed330"
                                            trackColor: "#fed330"
                                        }

                                        Text {
                                            text: "Selector (5-Stage)"
                                            font.pixelSize: 11
                                            color: "#8a95a5"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 1: Radial Gauges Dedicated Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 340
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 30

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                RadialGauge {
                                    width: 250
                                    height: 250
                                    value: rpmGauge.value
                                    minimum: 0
                                    maximum: 8000
                                    precision: 0
                                    unit: "RPM"
                                    warningThreshold: 6000
                                    errorThreshold: 7200
                                }
                                Text {
                                    text: "Live Tachometer (0-8000 RPM)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                RadialGauge {
                                    width: 250
                                    height: 250
                                    value: pressureGauge.value
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "bar"
                                    warningThreshold: 70
                                    errorThreshold: 85
                                }
                                Text {
                                    text: "Manometer (0-100 bar)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                RadialGauge {
                                    width: 250
                                    height: 250
                                    value: tempGauge.value
                                    minimum: 0
                                    maximum: 120
                                    precision: 1
                                    unit: "°C"
                                    warningThreshold: 80
                                    errorThreshold: 100
                                }
                                Text {
                                    text: "Thermometer (0-120 °C)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 2: Status LEDs Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                Rectangle {
                    width: parent.width
                    height: 500
                    color: "#161b24"
                    radius: 8
                    border.color: "#273142"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 30
                        spacing: 20

                        Text {
                            text: "Pilot LED Indicators (Clickable, Blinking & Multi-color)"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#f5f6fa"
                        }

                        GridLayout {
                            columns: 2
                            rowSpacing: 18
                            columnSpacing: 40

                            LedIndicator {
                                labelText: "POWER NORMAL (Green - Click to toggle)"
                                on: true
                                clickable: true
                                onColor: "#2ecc71"
                            }

                            LedIndicator {
                                labelText: "HIGH TEMP ALARM (Red - Blinking fast 180ms)"
                                on: true
                                blinking: true
                                blinkRateMs: 180
                                onColor: "#eb3b5a"
                            }

                            LedIndicator {
                                labelText: "MAINTENANCE ADVISORY (Amber - Blinking 400ms)"
                                on: true
                                blinking: true
                                blinkRateMs: 400
                                onColor: "#fed330"
                            }

                            LedIndicator {
                                labelText: "ETHERNET COMM OK (Cyan)"
                                on: true
                                onColor: "#00e5ff"
                            }

                            LedIndicator {
                                shape: LedIndicator.Shape.Rectangular
                                labelText: "ANNUNCIATOR PANEL 1 (Rectangular Green)"
                                on: true
                                onColor: "#2ecc71"
                                clickable: true
                            }

                            LedIndicator {
                                shape: LedIndicator.Shape.Rectangular
                                labelText: "ANNUNCIATOR PANEL 2 (Rectangular Amber Blinking)"
                                on: true
                                blinking: true
                                blinkRateMs: 450
                                onColor: "#fed330"
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 3: Industrial Knobs Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                Rectangle {
                    width: parent.width
                    height: 500
                    color: "#161b24"
                    radius: 8
                    border.color: "#273142"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 40
                        spacing: 50

                        ColumnLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 12

                            IndustrialKnob {
                                width: 220
                                height: 250
                                minimum: 0
                                maximum: 100
                                value: 42
                                unit: "%"
                                pointerColor: "#00e5ff"
                                trackColor: "#00e5ff"
                            }
                            Text {
                                text: "Continuous Potentiometer Knob (Drag or Mouse Wheel)"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#f5f6fa"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 12

                            IndustrialKnob {
                                width: 220
                                height: 250
                                mode: IndustrialKnob.Mode.Discrete
                                discreteSteps: 7
                                minimum: 1
                                maximum: 7
                                value: 4
                                precision: 0
                                unit: "POS"
                                pointerColor: "#fed330"
                                trackColor: "#fed330"
                            }
                            Text {
                                text: "7-Position Stepped Rotary Selector"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#f5f6fa"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 4: SevenSegmentDisplay Dedicated Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                Rectangle {
                    width: parent.width
                    implicitHeight: segCol.implicitHeight + 60
                    color: "#161b24"
                    radius: 8
                    border.color: "#273142"
                    border.width: 1

                    ColumnLayout {
                        id: segCol
                        anchors.fill: parent
                        anchors.margins: 30
                        spacing: 24

                        Text {
                            text: "SevenSegmentDisplay Vector Readouts & Color Presets"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#f5f6fa"
                        }

                        // Row 1: Interactive & Main Presets
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Neon Cyan (Telemetry Engine RPM: 0-8000)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 5
                                    decimalPlaces: 0
                                    value: rpmGauge.value
                                    activeSegmentColor: "#00e5ff"
                                    showLeadingZeros: false
                                }
                            }

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Amber Preset (Hydraulic Pressure: 0-100 bar)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 5
                                    decimalPlaces: 2
                                    value: pressureGauge.value
                                    colorPreset: "amber"
                                    showLeadingZeros: true
                                }
                            }

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Alarm Red Preset (High Temp: 0-120 °C)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 5
                                    decimalPlaces: 1
                                    value: tempGauge.value
                                    colorPreset: "red"
                                }
                            }
                        }

                        // Row 2: Status & Alphanumeric Text Mode
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Green Preset (System Ready / Counter)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 6
                                    decimalPlaces: 0
                                    value: 12480
                                    colorPreset: "green"
                                    showLeadingZeros: true
                                }
                            }

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Alphanumeric Text Mode ('PASS')"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 5
                                    text: " PASS"
                                    colorPreset: "green"
                                }
                            }

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Diagnostic Error Mode ('Err')"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                SevenSegmentDisplay {
                                    width: 260
                                    height: 75
                                    digitCount: 5
                                    text: " Err "
                                    colorPreset: "red"
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 5: LinearGauge Dedicated Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                Rectangle {
                    width: parent.width
                    implicitHeight: linCol.implicitHeight + 60
                    color: "#161b24"
                    radius: 8
                    border.color: "#273142"
                    border.width: 1

                    ColumnLayout {
                        id: linCol
                        anchors.fill: parent
                        anchors.margins: 30
                        spacing: 24

                        Text {
                            text: "LinearGauge Vertical Thermometers & Horizontal Bar Displays"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#f5f6fa"
                        }

                        // Section A: Vertical Gauges Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 40

                            // 1. Bulb Thermometer (Live Core Temperature)
                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Bulb Thermometer (Core Temp °C)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                LinearGauge {
                                    width: 120
                                    height: 300
                                    value: tempGauge.value
                                    minimum: -20
                                    maximum: 120
                                    precision: 1
                                    unit: "°C"
                                    thermometerMode: true
                                    warningThreshold: 80
                                    errorThreshold: 100
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // 2. Flat Column Bar (Hydraulic Pressure)
                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Flat Column Bar (Pressure bar)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                LinearGauge {
                                    width: 120
                                    height: 300
                                    value: pressureGauge.value
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "bar"
                                    thermometerMode: false
                                    warningThreshold: 70
                                    errorThreshold: 85
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // 3. Interactive Vertical Slider (Interactive Mouse / Wheel)
                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Interactive Level (Drag / Wheel)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                LinearGauge {
                                    id: interactiveVertGauge
                                    width: 120
                                    height: 300
                                    value: 45.0
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "%"
                                    thermometerMode: true
                                    warningThreshold: 60
                                    errorThreshold: 85
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // 4. Multi-color Continuous Gradient Liquid
                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: "Continuous Gradient Fill Mode"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                LinearGauge {
                                    width: 120
                                    height: 300
                                    value: interactiveVertGauge.value
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "%"
                                    thermometerMode: true
                                    gradientLiquid: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Section B: Horizontal Gauges
                        Text {
                            text: "Horizontal Orientation Layouts"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#8a95a5"
                            Layout.topMargin: 12
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            // Horizontal 1: Power Output Bar
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: "Horizontal Linear Bar Gauge (Power Output: 0-100 kW)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                LinearGauge {
                                    Layout.fillWidth: true
                                    height: 85
                                    orientation: LinearGauge.Orientation.Horizontal
                                    thermometerMode: false
                                    value: (rpmGauge.value / 8000.0) * 100.0
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "kW"
                                    warningThreshold: 75
                                    errorThreshold: 90
                                }
                            }

                            // Horizontal 2: Continuous Gradient Horizontal
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: "Horizontal Thermometer with Multi-Color Gradient Fill"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#8a95a5"
                                }
                                LinearGauge {
                                    Layout.fillWidth: true
                                    height: 85
                                    orientation: LinearGauge.Orientation.Horizontal
                                    thermometerMode: true
                                    gradientLiquid: true
                                    value: interactiveVertGauge.value
                                    minimum: 0
                                    maximum: 100
                                    precision: 1
                                    unit: "%"
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 6: Industrial Switches Dedicated Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // Header Description
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Text {
                                text: "🔌 Industrial Panel Switches Showcase"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#f5f6fa"
                            }
                            Text {
                                text: "Bat-handle toggle levers, curved rocker paddles, 2/3 positions, and flip-up safety guards"
                                font.pixelSize: 12
                                color: "#8a95a5"
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Main Switches Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Panel 1: Guarded Toggle Lever (Crimson Flip-Up Safety Guard)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "Safety Guarded Toggle Lever"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Click guard to flip open, then actuate lever"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                IndustrialSwitch {
                                    id: guardedSwitch
                                    width: 110
                                    height: 180
                                    Layout.alignment: Qt.AlignCenter
                                    switchType: IndustrialSwitch.SwitchType.ToggleLever
                                    hasSafetyGuard: true
                                    label: "MAIN PWR"
                                    labelOff: "OFF"
                                    labelOn: "ARMED"
                                    hasLed: true
                                    ledColor: "#eb3b5a"
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8
                                    Button {
                                        text: guardedSwitch.isGuardOpen ? "Close Guard" : "Open Guard"
                                        onClicked: guardedSwitch.setGuardOpen(!guardedSwitch.isGuardOpen)
                                    }
                                    Button {
                                        text: guardedSwitch.checked ? "Turn OFF" : "Turn ON"
                                        onClicked: guardedSwitch.toggle()
                                    }
                                }
                            }
                        }

                        // Panel 2: 3-Position Multi-Detent Switch
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "3-Position Multi-Detent Selector"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Detents: MAN (0) / OFF (1) / AUTO (2)"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                IndustrialSwitch {
                                    id: threePosSwitch
                                    width: 110
                                    height: 180
                                    Layout.alignment: Qt.AlignCenter
                                    switchType: IndustrialSwitch.SwitchType.ToggleLever
                                    positionCount: 3
                                    position: 2
                                    label: "FEED PUMP"
                                    labelOff: "MAN"
                                    labelCenter: "OFF"
                                    labelOn: "AUTO"
                                    hasLed: true
                                    ledColor: "#2ecc71"
                                }

                                Text {
                                    text: "Position: " + threePosSwitch.position + " (" + (threePosSwitch.position === 0 ? "MAN" : threePosSwitch.position === 1 ? "OFF" : "AUTO") + ")"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#fed330"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Panel 3: Industrial Rocker Switch
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "Curved Rocker Switch"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "3D tilt displacement with illuminated status bar"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                IndustrialSwitch {
                                    id: rockerSwitch
                                    width: 110
                                    height: 180
                                    Layout.alignment: Qt.AlignCenter
                                    switchType: IndustrialSwitch.SwitchType.Rocker
                                    label: "EXHAUST"
                                    labelOff: "STOP"
                                    labelOn: "RUN"
                                    hasLed: true
                                    ledColor: "#00e5ff"
                                }

                                Text {
                                    text: "Status: " + (rockerSwitch.checked ? "RUNNING" : "STOPPED")
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: rockerSwitch.checked ? "#00e5ff" : "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Panel 4: Horizontal Toggle Switch
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "Horizontal Orientation Switch"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Left-to-right throw with lateral detent action"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                IndustrialSwitch {
                                    id: horizontalSwitch
                                    width: 180
                                    height: 110
                                    Layout.alignment: Qt.AlignCenter
                                    orientation: IndustrialSwitch.Orientation.Horizontal
                                    switchType: IndustrialSwitch.SwitchType.ToggleLever
                                    label: "INTERLOCK"
                                    labelOff: "DISENG"
                                    labelOn: "ENGAGED"
                                    hasLed: true
                                    ledColor: "#fed330"
                                }

                                Text {
                                    text: "Interlock: " + (horizontalSwitch.checked ? "ENGAGED" : "DISENGAGED")
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: horizontalSwitch.checked ? "#fed330" : "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }

                    // Interactive Configurator Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 32

                            // Preview Switch
                            IndustrialSwitch {
                                id: configSwitch
                                width: configHorizontalCheck.checked ? 170 : 105
                                height: configHorizontalCheck.checked ? 105 : 150
                                switchType: configTypeCombo.currentIndex === 0 ? IndustrialSwitch.SwitchType.ToggleLever : IndustrialSwitch.SwitchType.Rocker
                                orientation: configHorizontalCheck.checked ? IndustrialSwitch.Orientation.Horizontal : IndustrialSwitch.Orientation.Vertical
                                positionCount: configPos3Check.checked ? 3 : 2
                                hasSafetyGuard: configGuardCheck.checked
                                hasLed: configLedCheck.checked
                                label: "CUSTOM"
                                ledColor: configColorCombo.currentValue
                            }

                            // Controls Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                rowSpacing: 10
                                columnSpacing: 24

                                CheckBox {
                                    id: configGuardCheck
                                    text: "Safety Guard"
                                    checked: true
                                }

                                CheckBox {
                                    id: configPos3Check
                                    text: "3-Position Mode"
                                    checked: false
                                }

                                CheckBox {
                                    id: configHorizontalCheck
                                    text: "Horizontal Layout"
                                    checked: false
                                }

                                CheckBox {
                                    id: configLedCheck
                                    text: "Pilot LED Lamp"
                                    checked: true
                                }

                                RowLayout {
                                    spacing: 8
                                    Text { text: "Actuator:"; color: "#8a95a5"; font.pixelSize: 12 }
                                    ComboBox {
                                        id: configTypeCombo
                                        model: ["Toggle Bat Lever", "Curved Rocker"]
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Text { text: "LED Color:"; color: "#8a95a5"; font.pixelSize: 12 }
                                    ComboBox {
                                        id: configColorCombo
                                        textRole: "text"
                                        valueRole: "value"
                                        model: [
                                            { text: "Emerald Green", value: "#2ecc71" },
                                            { text: "Neon Cyan", value: "#00e5ff" },
                                            { text: "Amber Gold", value: "#fed330" },
                                            { text: "Crimson Red", value: "#eb3b5a" }
                                        ]
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // TAB 7: Level Meters Dedicated Showcase
            // ----------------------------------------------------------------
            ScrollView {
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // Header Description
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Text {
                                text: "📶 Multi-Channel Level Meters (LevelMeter)"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#f5f6fa"
                            }
                            Text {
                                text: "Stereo dB / VU meters, telemetry amplitude bars, floating peak hold, segmented LED ladder and continuous gradient modes"
                                font.pixelSize: 12
                                color: "#8a95a5"
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Main Level Meters Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Panel 1: Stereo Master VU Meter (dBFS)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 380
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                Text {
                                    text: "Stereo Master VU Meter (-60 to +6 dB)"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Segmented LED ladder with floating peak-hold bars"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                LevelMeter {
                                    id: stereoMeter
                                    width: 130
                                    height: 250
                                    Layout.alignment: Qt.AlignCenter
                                    channelCount: 2
                                    channelLabels: ["L", "R"]
                                    minimum: -60.0
                                    maximum: 6.0
                                    warningThreshold: -6.0
                                    errorThreshold: 0.0
                                    segmentCount: 24
                                    unit: "dB"
                                    title: "STEREO MASTER"
                                    displayMode: LevelMeter.DisplayMode.Segmented
                                    peakHoldEnabled: true
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8
                                    Button {
                                        text: "Reset Peaks"
                                        onClicked: stereoMeter.resetPeaks()
                                    }
                                    Button {
                                        text: "Burst +3 dB"
                                        onClicked: {
                                            stereoMeter.setValue(0, 3.2)
                                            stereoMeter.setValue(1, 2.5)
                                        }
                                    }
                                }
                            }
                        }

                        // Panel 2: 4-Channel Telemetry Tank Levels (%)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 380
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                Text {
                                    text: "4-Channel Tank Fill Levels (0-100%)"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Solid continuous fill with dynamic color bands"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                LevelMeter {
                                    id: tankMeter
                                    width: 170
                                    height: 250
                                    Layout.alignment: Qt.AlignCenter
                                    channelCount: 4
                                    channelLabels: ["T1", "T2", "T3", "T4"]
                                    minimum: 0.0
                                    maximum: 100.0
                                    warningThreshold: 75.0
                                    errorThreshold: 90.0
                                    unit: "%"
                                    title: "TANK FILL"
                                    displayMode: LevelMeter.DisplayMode.Continuous
                                    peakHoldEnabled: true
                                }

                                Text {
                                    text: "Channels: T1=65% • T2=42% • T3=88% • T4=25%"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Panel 3: Horizontal Orientation Level Meter
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 380
                            color: "#161b24"
                            radius: 8
                            border.color: "#273142"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                Text {
                                    text: "Horizontal Orientation Layout"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#f5f6fa"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Dual horizontal bar meters with bottom scale"
                                    font.pixelSize: 11
                                    color: "#8a95a5"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                LevelMeter {
                                    id: horizMeter
                                    Layout.fillWidth: true
                                    height: 120
                                    orientation: LevelMeter.Orientation.Horizontal
                                    channelCount: 2
                                    channelLabels: ["CH 1", "CH 2"]
                                    minimum: -60.0
                                    maximum: 6.0
                                    warningThreshold: -6.0
                                    errorThreshold: 0.0
                                    unit: "dB"
                                    title: "AUXILIARY BUS"
                                    displayMode: LevelMeter.DisplayMode.Segmented
                                    values: [stereoMeter.getChannelValue(0), stereoMeter.getChannelValue(1)]
                                }

                                LevelMeter {
                                    Layout.fillWidth: true
                                    height: 110
                                    orientation: LevelMeter.Orientation.Horizontal
                                    channelCount: 1
                                    channelLabels: ["MAIN"]
                                    minimum: 0.0
                                    maximum: 100.0
                                    unit: "kW"
                                    displayMode: LevelMeter.DisplayMode.Continuous
                                    value: (rpmGauge.value / 8000.0) * 100.0
                                }
                            }
                        }
                    }

                    // Interactive Configurator Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        color: "#161b24"
                        radius: 8
                        border.color: "#273142"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 32

                            // Preview Meter
                            LevelMeter {
                                id: configMeter
                                width: configHorizCheck.checked ? 280 : (24 + channelCount * 18 + 40)
                                height: configHorizCheck.checked ? (24 + channelCount * 18 + 36) : 180
                                orientation: configHorizCheck.checked ? LevelMeter.Orientation.Horizontal : LevelMeter.Orientation.Vertical
                                displayMode: configModeCombo.currentIndex === 0 ? LevelMeter.DisplayMode.Segmented : LevelMeter.DisplayMode.Continuous
                                channelCount: Math.round(configChannelSlider.value)
                                segmentCount: Math.round(configSegSlider.value)
                                peakHoldEnabled: configPeakCheck.checked
                                scaleVisible: configScaleCheck.checked
                                minimum: -60
                                maximum: 6
                                unit: "dB"
                                title: "CUSTOM"
                                value: configValSlider.value
                            }

                            // Controls Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                rowSpacing: 10
                                columnSpacing: 24

                                CheckBox {
                                    id: configPeakCheck
                                    text: "Peak Hold"
                                    checked: true
                                }

                                CheckBox {
                                    id: configScaleCheck
                                    text: "Scale Visible"
                                    checked: true
                                }

                                CheckBox {
                                    id: configHorizCheck
                                    text: "Horizontal Layout"
                                    checked: false
                                }

                                RowLayout {
                                    spacing: 8
                                    Text { text: "Mode:"; color: "#8a95a5"; font.pixelSize: 12 }
                                    ComboBox {
                                        id: configModeCombo
                                        model: ["Segmented (LED)", "Continuous (Fill)"]
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Text { text: "Channels: " + Math.round(configChannelSlider.value); color: "#8a95a5"; font.pixelSize: 12 }
                                    Slider {
                                        id: configChannelSlider
                                        from: 1
                                        to: 6
                                        value: 2
                                        stepSize: 1
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Text { text: "Segments: " + Math.round(configSegSlider.value); color: "#8a95a5"; font.pixelSize: 12 }
                                    Slider {
                                        id: configSegSlider
                                        from: 10
                                        to: 40
                                        value: 24
                                        stepSize: 2
                                    }
                                }

                                RowLayout {
                                    Layout.columnSpan: 3
                                    spacing: 12
                                    Text { text: "Manual Signal Value: " + configValSlider.value.toFixed(1) + " dB"; color: "#8a95a5"; font.pixelSize: 12 }
                                    Slider {
                                        id: configValSlider
                                        Layout.fillWidth: true
                                        from: -60
                                        to: 6
                                        value: -12
                                        onValueChanged: configMeter.setValue(0, value)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
