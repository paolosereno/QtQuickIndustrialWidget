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
        }
    }
}
