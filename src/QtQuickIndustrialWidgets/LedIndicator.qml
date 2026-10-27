// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * \class LedIndicator
 * \brief High-performance status LED / pilot lamp in Qt Quick.
 *
 * Equivalent to QtIndustrialWidgets::LedIndicator with GPU acceleration,
 * realistic 3D lens highlight, optional radial glow halo, circular or rectangular
 * shapes, metallic bezel rim, autonomous blinking, and smooth transitions.
 */
Item {
    id: root

    enum Shape {
        Circular = 0,
        Rectangular = 1
    }

    // --- Properties ---
    property bool on: true
    property bool blinking: false
    property int blinkRateMs: 500
    property color onColor: "#2ecc71"
    property color offColor: Qt.rgba(onColor.r / 6, onColor.g / 6, onColor.b / 6, 1.0)
    property color bezelColor: "#3c4655"
    property bool bezelVisible: true
    property bool glowEffect: true
    property int shape: LedIndicator.Shape.Circular
    property string labelText: ""
    property color textColor: "#f5f6fa"
    property font font: Qt.font({ pixelSize: 13, weight: Font.Medium })
    property bool clickable: false
    property bool smoothTransition: true

    // --- Signals ---
    signal ledStateChanged(bool on)
    signal clicked()
    signal appearanceChanged()

    // --- Implicit Size & Defaults ---
    implicitWidth: labelText.length > 0 ? (28 + 8 + textMetrics.width + 6) : 28
    implicitHeight: labelText.length > 0 ? Math.max(28, textMetrics.height + 4) : 28
    width: implicitWidth
    height: implicitHeight

    TextMetrics {
        id: textMetrics
        font: root.font
        text: root.labelText
    }

    // --- State and Blinking ---
    property bool _blinkState: true

    Timer {
        id: blinkTimer
        interval: Math.max(50, root.blinkRateMs)
        running: root.blinking
        repeat: true
        onTriggered: {
            root._blinkState = !root._blinkState
        }
    }

    onBlinkingChanged: {
        if (!blinking) {
            _blinkState = true
        }
        appearanceChanged()
    }

    onOnChanged: {
        ledStateChanged(on)
        appearanceChanged()
    }

    readonly property bool isLit: on && (!blinking || _blinkState)
    property real litProgress: isLit ? 1.0 : 0.0

    Behavior on litProgress {
        enabled: root.smoothTransition
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }

    // --- Methods ---
    function setOn(val) {
        if (root.on !== val) {
            root.on = val
            root.ledStateChanged(root.on)
            root.appearanceChanged()
        }
    }

    function setOff() {
        setOn(false)
    }

    function toggle() {
        setOn(!root.on)
    }

    // --- Geometry Computations ---
    readonly property real ledSize: {
        if (root.labelText.length > 0) {
            return Math.min(root.height - 4, 36)
        } else {
            return Math.min(root.width, root.height) - 4
        }
    }
    readonly property real ledX: root.labelText.length > 0 ? 2.0 : (root.width - ledSize) * 0.5
    readonly property real ledY: (root.height - ledSize) * 0.5
    readonly property real cx: ledX + ledSize * 0.5
    readonly property real cy: ledY + ledSize * 0.5
    readonly property real radius: ledSize * 0.5
    readonly property real lensRadius: root.bezelVisible ? radius * 0.78 : radius

    // --- Component Visual Layers ---

    // 1. Radial Glow Halo (Lit state)
    Shape {
        id: glowLayer
        anchors.fill: parent
        visible: root.glowEffect && root.litProgress > 0.001
        opacity: root.litProgress

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.cx
                centerY: root.cy
                centerRadius: root.radius * 1.35
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root.onColor.r, root.onColor.g, root.onColor.b, 120 / 255)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(root.onColor.r, root.onColor.g, root.onColor.b, 40 / 255)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(root.onColor.r, root.onColor.g, root.onColor.b, 0.0)
                }
            }
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.radius * 1.35
                radiusY: root.radius * 1.35
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // 2. Bezel Layer (Machined Aluminum / Industrial Case)
    Shape {
        id: circularBezel
        anchors.fill: parent
        visible: root.bezelVisible && root.shape === LedIndicator.Shape.Circular

        // Outer Metallic Rim
        ShapePath {
            strokeWidth: 1.0
            strokeColor: Qt.darker(root.bezelColor, 1.8)
            fillGradient: RadialGradient {
                centerX: root.cx
                centerY: root.cy
                centerRadius: root.radius
                GradientStop { position: 0.0; color: Qt.lighter(root.bezelColor, 1.3) }
                GradientStop { position: 0.85; color: root.bezelColor }
                GradientStop { position: 1.0; color: Qt.darker(root.bezelColor, 1.6) }
            }
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Inner Dark Recess Ring
        ShapePath {
            strokeWidth: 1.0
            strokeColor: Qt.rgba(0, 0, 0, 0.627)
            fillColor: "#0a0c10"
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.radius * 0.85
                radiusY: root.radius * 0.85
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Rectangular Bezel
    Rectangle {
        id: rectangularBezel
        visible: root.bezelVisible && root.shape === LedIndicator.Shape.Rectangular
        x: root.ledX
        y: root.ledY
        width: root.ledSize
        height: root.ledSize
        radius: 4.0
        border.width: 1.2
        border.color: Qt.darker(root.bezelColor, 1.8)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.lighter(root.bezelColor, 1.3) }
            GradientStop { position: 1.0; color: Qt.darker(root.bezelColor, 1.5) }
        }
    }

    // 3. Circular 3D Lens Core
    Item {
        id: circularLensContainer
        anchors.fill: parent
        visible: root.shape === LedIndicator.Shape.Circular

        // Base Lens (lit and unlit cross-fade for ultra-smooth transition)
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0.8
                strokeColor: Qt.darker(root.offColor, 1.8)
                fillGradient: RadialGradient {
                    centerX: root.cx
                    centerY: root.cy
                    focalX: root.cx - root.lensRadius * 0.25
                    focalY: root.cy - root.lensRadius * 0.25
                    centerRadius: root.lensRadius
                    GradientStop { position: 0.0; color: Qt.lighter(root.offColor, 1.3) }
                    GradientStop { position: 0.6; color: root.offColor }
                    GradientStop { position: 1.0; color: Qt.darker(root.offColor, 1.7) }
                }
                PathAngleArc {
                    centerX: root.cx
                    centerY: root.cy
                    radiusX: root.lensRadius
                    radiusY: root.lensRadius
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Shape {
            anchors.fill: parent
            opacity: root.litProgress
            ShapePath {
                strokeWidth: 0.8
                strokeColor: Qt.darker(root.onColor, 1.4)
                fillGradient: RadialGradient {
                    centerX: root.cx
                    centerY: root.cy
                    focalX: root.cx - root.lensRadius * 0.25
                    focalY: root.cy - root.lensRadius * 0.25
                    centerRadius: root.lensRadius
                    GradientStop { position: 0.0; color: Qt.lighter(root.onColor, 1.7) }
                    GradientStop { position: 0.5; color: root.onColor }
                    GradientStop { position: 0.9; color: Qt.darker(root.onColor, 1.3) }
                    GradientStop { position: 1.0; color: Qt.darker(root.onColor, 1.7) }
                }
                PathAngleArc {
                    centerX: root.cx
                    centerY: root.cy
                    radiusX: root.lensRadius
                    radiusY: root.lensRadius
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        // Top Specular Reflection Dome Glare
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: root.cx
                    y1: root.cy - root.lensRadius * 0.75
                    x2: root.cx
                    y2: root.cy
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(1, 1, 1, 0.51 + 0.35 * root.litProgress)
                    }
                    GradientStop {
                        position: 0.6
                        color: Qt.rgba(1, 1, 1, 0.12 + 0.19 * root.litProgress)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0.0)
                    }
                }
                PathAngleArc {
                    centerX: root.cx
                    centerY: root.cy - root.lensRadius * 0.375
                    radiusX: root.lensRadius * 0.65
                    radiusY: root.lensRadius * 0.375
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        // Bottom Ambient Bounce Crescent
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: root.cx
                    y1: root.cy + root.lensRadius * 0.8
                    x2: root.cx
                    y2: root.cy + root.lensRadius * 0.35
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(1, 1, 1, 0.14 + 0.21 * root.litProgress)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0.0)
                    }
                }
                PathAngleArc {
                    centerX: root.cx
                    centerY: root.cy + root.lensRadius * 0.575
                    radiusX: root.lensRadius * 0.45
                    radiusY: root.lensRadius * 0.225
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }

    // 4. Rectangular 3D Lens Core
    Item {
        id: rectangularLensContainer
        visible: root.shape === LedIndicator.Shape.Rectangular
        x: root.bezelVisible ? root.ledX + 3.0 : root.ledX
        y: root.bezelVisible ? root.ledY + 3.0 : root.ledY
        width: root.bezelVisible ? root.ledSize - 6.0 : root.ledSize
        height: root.bezelVisible ? root.ledSize - 6.0 : root.ledSize

        // Unlit base lens
        Rectangle {
            anchors.fill: parent
            radius: 3.0
            border.width: 0.8
            border.color: Qt.darker(root.offColor, 1.7)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.lighter(root.offColor, 1.2) }
                GradientStop { position: 1.0; color: Qt.darker(root.offColor, 1.6) }
            }
        }

        // Lit lens
        Rectangle {
            anchors.fill: parent
            radius: 3.0
            border.width: 0.8
            border.color: Qt.darker(root.onColor, 1.3)
            opacity: root.litProgress
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.lighter(root.onColor, 1.5) }
                GradientStop { position: 0.5; color: root.onColor }
                GradientStop { position: 1.0; color: Qt.darker(root.onColor, 1.4) }
            }
        }

        // Specular Glare Stripe
        Rectangle {
            x: 2.0
            y: 2.0
            width: parent.width - 4.0
            height: parent.height * 0.38
            radius: 2.0
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.39 + 0.35 * root.litProgress)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(1, 1, 1, 0.0)
                }
            }
        }
    }

    // 5. Status Caption Label
    Text {
        id: labelItem
        visible: root.labelText.length > 0
        x: root.ledX + root.ledSize + 8.0
        anchors.verticalCenter: parent.verticalCenter
        text: root.labelText
        font: root.font
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
    }

    // 6. Interactive Click Area
    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.toggle()
            root.clicked()
        }
    }
}
