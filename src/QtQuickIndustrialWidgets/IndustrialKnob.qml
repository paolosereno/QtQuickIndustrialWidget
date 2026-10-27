// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes
import "NumberFormat.js" as NumberFormat

/**
 * \class IndustrialKnob
 * \brief High-performance rotary knob control in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::IndustrialKnob:
 * - Knurled CNC perimeter grip with machined serrations
 * - Brushed metallic rotary face with laser-etched pointer notch
 * - Surrounding graduation ticks and numeric scale
 * - Active illuminated tracking arc
 * - Recessed digital readout pod located at the bottom (below the dial)
 * - Continuous potentiometer mode or stepped discrete selector mode
 * - Polar rotary dragging, keyboard controls, and mouse wheel adjustments
 */
Item {
    id: root

    activeFocusOnTab: true

    Keys.onPressed: (event) => {
        const stepDelta = (root.mode === IndustrialKnob.Mode.Discrete && root.discreteSteps > 1)
            ? ((root.maximum - root.minimum) / (root.discreteSteps - 1))
            : root.step

        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.setValue(root.value - stepDelta)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.setValue(root.value + stepDelta)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.setValue(root.minimum)
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.setValue(root.maximum)
            event.accepted = true
        }
    }

    enum Mode {
        Continuous = 0,
        Discrete = 1
    }

    // --- Range & Value Properties ---
    property real minimum: 0.0
    property real maximum: 100.0
    property real value: 25.0
    property real step: 1.0
    property int precision: 0
    property string unit: "%"

    // --- Angles & Ticks (0° is 12 o'clock, clockwise) ---
    property real startAngle: -135.0
    property real spanAngle: 270.0
    property int majorTicks: 10
    property int minorTicks: 3

    // --- Mode & Features ---
    property int mode: IndustrialKnob.Mode.Continuous
    property int discreteSteps: 5
    property bool trackVisible: true
    property bool valueDisplayVisible: true
    property bool animated: true
    property real animationVelocity: 360.0 // deg/s

    // --- Colors (Matching C++ QtIndustrialWidgets palette) ---
    property color knobColor: "#2a303c"      // Dark Slate Metal
    property color pointerColor: "#00e5ff"   // High-contrast Neon Cyan
    property color scaleColor: "#bec8d7"     // Soft Silver Scale
    property color trackColor: "#00e5ff"     // Illuminated Neon Cyan
    property color textColor: "#f0f4fa"      // Crisp Off-White

    // --- Signals ---
    signal rangeChanged(real min, real max)
    signal appearanceChanged()

    // --- Size Hint & Defaults ---
    implicitWidth: 160
    implicitHeight: 180
    width: implicitWidth
    height: implicitHeight

    // --- Geometry Computations (Exact match to IndustrialKnob.cpp) ---
    readonly property real side: Math.min(width, height * 0.82)
    readonly property real cx: width * 0.5
    readonly property real cy: side * 0.5 + 4.0
    readonly property real radius: Math.max(10.0, (side * 0.5) - 4.0)
    readonly property real knobRadius: radius * 0.65
    readonly property real scaleRadius: radius * 0.92
    readonly property real tickLen: radius * 0.12
    readonly property real minorTickLen: tickLen * 0.55
    readonly property real labelRadius: scaleRadius + radius * 0.12
    readonly property real trackRadius: radius * 0.84

    // Dial Face & Pointer Proportions
    readonly property real faceRadius: knobRadius * 0.84
    readonly property real innerFace: faceRadius * 0.90
    readonly property real ptrInner: innerFace * 0.32
    readonly property real ptrOuter: innerFace * 0.92
    readonly property real ptrWidth: Math.max(2.5, knobRadius * 0.07)

    // Bottom Digital Pod Geometry
    readonly property real podW: Math.max(50.0, Math.min(110.0, width * 0.65))
    readonly property real podH: 22.0
    readonly property real podX: (width - podW) * 0.5
    readonly property real podY: height - podH - 2.0

    // Angle Mapping
    function valueToAngle(val) {
        if (maximum <= minimum) return startAngle
        const factor = Math.max(0.0, Math.min(1.0, (val - minimum) / (maximum - minimum)))
        return startAngle + factor * spanAngle
    }

    readonly property real targetAngle: valueToAngle(value)

    readonly property int currentStepIndex: {
        if (mode !== IndustrialKnob.Mode.Discrete || discreteSteps <= 1) return 0
        const stepVal = (maximum - minimum) / (discreteSteps - 1)
        return Math.round((value - minimum) / stepVal)
    }

    // --- Value Update & Step Clamping ---
    function setValue(val) {
        if (isNaN(val)) return
        if (!isFinite(val)) {
            val = (val > 0) ? maximum : minimum
        }
        let clamped = Math.max(minimum, Math.min(maximum, val))
        if (mode === IndustrialKnob.Mode.Discrete && discreteSteps > 1) {
            const stepVal = (maximum - minimum) / (discreteSteps - 1)
            const idx = Math.round((clamped - minimum) / stepVal)
            clamped = minimum + idx * stepVal
        } else if (step > 0) {
            const stepsCount = Math.round((clamped - minimum) / step)
            clamped = minimum + stepsCount * step
            clamped = Math.max(minimum, Math.min(maximum, clamped))
        }
        root.value = clamped
    }

    function updateValueFromPoint(px, py) {
        if (root.spanAngle <= 0.0) return

        const dx = px - root.cx
        const dy = py - root.cy
        if (Math.hypot(dx, dy) < 4.0) return

        // Standard polar coordinates where 0° is 12 o'clock, clockwise positive [-180, 180]
        const rad = Math.atan2(dx, -dy)
        const deg = rad * 180.0 / Math.PI

        // Compute angle clockwise from startAngle into [0, 360)
        let delta = deg - root.startAngle
        while (delta < 0.0) delta += 360.0
        while (delta >= 360.0) delta -= 360.0

        if (delta <= root.spanAngle) {
            // Inside the active graduation range
            const factor = delta / root.spanAngle
            setValue(root.minimum + factor * (root.maximum - root.minimum))
        } else {
            // In the dead zone at the bottom between spanAngle and 360:
            // Snap to maximum or minimum depending on which half of the dead zone the cursor is in
            const deadZone = 360.0 - root.spanAngle
            if (delta - root.spanAngle < deadZone * 0.5) {
                setValue(root.maximum)
            } else {
                setValue(root.minimum)
            }
        }
    }

    onWidthChanged: staticCanvas.requestPaint()
    onHeightChanged: staticCanvas.requestPaint()
    onStartAngleChanged: staticCanvas.requestPaint()
    onSpanAngleChanged: staticCanvas.requestPaint()
    onMajorTicksChanged: staticCanvas.requestPaint()
    onMinorTicksChanged: staticCanvas.requestPaint()
    onKnobColorChanged: staticCanvas.requestPaint()
    onScaleColorChanged: staticCanvas.requestPaint()
    onTrackColorChanged: staticCanvas.requestPaint()
    onTextColorChanged: staticCanvas.requestPaint()
    onModeChanged: staticCanvas.requestPaint()
    onDiscreteStepsChanged: staticCanvas.requestPaint()
    onValueDisplayVisibleChanged: staticCanvas.requestPaint()

    // ========================================================================
    // 1. Static Scale & Background Ticks (Rendered once on change)
    // ========================================================================
    Canvas {
        id: staticCanvas
        anchors.fill: parent
        z: 0

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            if (typeof ctx.reset === "function") {
                ctx.reset()
            }
            ctx.clearRect(0, 0, width, height)

            const cx = root.cx
            const cy = root.cy
            const r = root.radius
            if (r <= 10.0) return

            const scaleR = root.scaleRadius
            const tickL = root.tickLen
            const minorL = root.minorTickLen
            const labelR = root.labelRadius

            const isDiscrete = (root.mode === IndustrialKnob.Mode.Discrete)
            const totalTicks = isDiscrete ? Math.max(1, root.discreteSteps - 1) : Math.max(1, root.majorTicks)
            const totalMinor = isDiscrete ? 0 : root.minorTicks
            const totalDivisions = totalTicks * (totalMinor + 1)
            const valRange = root.maximum - root.minimum

            // Minor Ticks
            if (totalMinor > 0) {
                ctx.lineWidth = 1.0
                ctx.strokeStyle = Qt.darker(root.scaleColor, 1.30).toString()
                ctx.lineCap = "round"

                for (let i = 0; i <= totalDivisions; ++i) {
                    if (i % (totalMinor + 1) === 0) continue
                    const frac = i / totalDivisions
                    const val = root.minimum + frac * valRange
                    const ang = (root.valueToAngle(val) - 90.0) * Math.PI / 180.0
                    const cosA = Math.cos(ang)
                    const sinA = Math.sin(ang)

                    ctx.beginPath()
                    ctx.moveTo(cx + (scaleR - minorL) * cosA, cy + (scaleR - minorL) * sinA)
                    ctx.lineTo(cx + scaleR * cosA, cy + scaleR * sinA)
                    ctx.stroke()
                }
            }

            // Major Ticks & Aligned Numeric Labels
            const fontSize = Math.max(7, Math.min(11, Math.floor(r * 0.12)))
            ctx.lineWidth = 1.6
            ctx.strokeStyle = root.scaleColor.toString()
            ctx.lineCap = "round"
            ctx.fillStyle = root.textColor.toString()
            ctx.font = `bold ${fontSize}px sans-serif`
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            for (let i = 0; i <= totalTicks; ++i) {
                const frac = i / totalTicks
                const val = root.minimum + frac * valRange
                const ang = (root.valueToAngle(val) - 90.0) * Math.PI / 180.0
                const cosA = Math.cos(ang)
                const sinA = Math.sin(ang)

                // Tick mark
                ctx.beginPath()
                ctx.moveTo(cx + (scaleR - tickL) * cosA, cy + (scaleR - tickL) * sinA)
                ctx.lineTo(cx + scaleR * cosA, cy + scaleR * sinA)
                ctx.stroke()

                // Numeric Label
                let labelText = ""
                if (isDiscrete) {
                    labelText = String(i + 1)
                } else {
                    labelText = NumberFormat.scaleLabelText(val, root.precision)
                }

                ctx.fillText(labelText, cx + labelR * cosA, cy + labelR * sinA)
            }

            // Static Digital Pod at bottom
            if (root.valueDisplayVisible) {
                ctx.beginPath()
                const px = root.podX
                const py = root.podY
                const pw = root.podW
                const ph = root.podH
                const pr = 3.0

                ctx.moveTo(px + pr, py)
                ctx.lineTo(px + pw - pr, py)
                ctx.arcTo(px + pw, py, px + pw, py + pr, pr)
                ctx.lineTo(px + pw, py + ph - pr)
                ctx.arcTo(px + pw, py + ph, px + pw - pr, py + ph, pr)
                ctx.lineTo(px + pr, py + ph)
                ctx.arcTo(px, py + ph, px, py + ph - pr, pr)
                ctx.lineTo(px, py + pr)
                ctx.arcTo(px, py, px + pr, py, pr)
                ctx.closePath()

                ctx.fillStyle = "rgba(16, 20, 26, 0.88)"
                ctx.fill()
                ctx.lineWidth = 1.0
                ctx.strokeStyle = Qt.darker(root.knobColor, 1.6).toString()
                ctx.stroke()
            }
        }
    }

    // ========================================================================
    // 2. Active Illuminated Track Arc
    // ========================================================================
    Shape {
        id: dynamicTrack
        anchors.fill: parent
        z: 1
        visible: root.trackVisible && root.spanAngle > 0 && root.targetAngle > root.startAngle

        ShapePath {
            strokeWidth: Math.max(2.5, root.radius * 0.04)
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.trackRadius
                radiusY: root.trackRadius
                startAngle: root.startAngle - 90.0
                sweepAngle: (root.targetAngle - root.startAngle)
            }
        }
    }

    // ========================================================================
    // 3. Rotating CNC Knurled Metallic Knob Body
    // ========================================================================
    Item {
        id: knobBody
        z: 2
        x: root.cx
        y: root.cy
        width: 0
        height: 0
        rotation: root.targetAngle

        Behavior on rotation {
            enabled: root.animated && !dragArea.pressed
            SmoothedAnimation {
                velocity: root.animationVelocity
                reversingMode: SmoothedAnimation.Immediate
            }
        }

        // Layer A: Outer Knurled Grip Base Ring
        Shape {
            ShapePath {
                strokeWidth: 1.2
                strokeColor: Qt.darker(root.knobColor, 1.8)
                fillGradient: RadialGradient {
                    centerX: 0; centerY: 0; centerRadius: root.knobRadius
                    GradientStop { position: 0.0; color: Qt.lighter(root.knobColor, 1.30) }
                    GradientStop { position: 0.85; color: root.knobColor }
                    GradientStop { position: 1.0; color: Qt.darker(root.knobColor, 1.50) }
                }
                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: root.knobRadius; radiusY: root.knobRadius
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        // Layer B: CNC Knurled Serration Teeth (32 peripheral grip ridges)
        Repeater {
            model: 32
            delegate: Shape {
                readonly property real deg: index * (360.0 / 32)
                readonly property real rad: deg * Math.PI / 180.0
                readonly property real toothLen: root.knobRadius * 0.09
                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: Qt.darker(root.knobColor, 1.7)
                    PathMove {
                        x: (root.knobRadius - toothLen) * Math.cos(rad)
                        y: (root.knobRadius - toothLen) * Math.sin(rad)
                    }
                    PathLine {
                        x: root.knobRadius * Math.cos(rad)
                        y: root.knobRadius * Math.sin(rad)
                    }
                }
            }
        }

        // Layer C: Beveled Metallic Face Rim & Brushed Face
        Shape {
            ShapePath {
                strokeWidth: 1.0
                strokeColor: Qt.darker(root.knobColor, 1.8)
                fillGradient: LinearGradient {
                    x1: -root.faceRadius; y1: -root.faceRadius
                    x2: root.faceRadius; y2: root.faceRadius
                    GradientStop { position: 0.0; color: Qt.lighter(root.knobColor, 1.40) }
                    GradientStop { position: 0.5; color: Qt.lighter(root.knobColor, 1.05) }
                    GradientStop { position: 1.0; color: Qt.darker(root.knobColor, 1.40) }
                }
                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: root.faceRadius; radiusY: root.faceRadius
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        // Layer D: Inner Specular Disc
        Shape {
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: -root.innerFace * 0.3
                    centerY: -root.innerFace * 0.3
                    centerRadius: root.innerFace * 1.2
                    GradientStop { position: 0.0; color: Qt.lighter(root.knobColor, 1.50) }
                    GradientStop { position: 0.4; color: root.knobColor }
                    GradientStop { position: 1.0; color: Qt.darker(root.knobColor, 1.60) }
                }
                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: root.innerFace; radiusY: root.innerFace
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        // Layer E: Laser-Etched Pointer Indicator (High contrast pointer notch)
        Shape {
            ShapePath {
                strokeWidth: 0.8
                strokeColor: Qt.darker(root.pointerColor, 1.5)
                fillColor: root.pointerColor
                PathMove { x: -root.ptrWidth * 0.5; y: -root.ptrInner }
                PathLine { x: -root.ptrWidth * 0.5; y: -root.ptrOuter + 2.0 }
                PathLine { x: 0.0; y: -root.ptrOuter }
                PathLine { x: root.ptrWidth * 0.5; y: -root.ptrOuter + 2.0 }
                PathLine { x: root.ptrWidth * 0.5; y: -root.ptrInner }
                PathLine { x: -root.ptrWidth * 0.5; y: -root.ptrInner }
            }
        }

        // Layer F: Specular Center Dot
        Rectangle {
            x: -1.5
            y: -1.5
            width: 3.0
            height: 3.0
            radius: 1.5
            color: Qt.rgba(1, 1, 1, 0.55)
        }
    }

    // ========================================================================
    // 4. Dynamic Digital Value Readout (Bottom Pod, strictly below dial)
    // ========================================================================
    Text {
        id: podText
        z: 3
        visible: root.valueDisplayVisible
        x: root.podX
        y: root.podY
        width: root.podW
        height: root.podH
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 11
        font.bold: true
        font.family: "monospace, sans-serif"
        color: root.pointerColor

        text: {
            if (root.mode === IndustrialKnob.Mode.Discrete) {
                return "POS " + (root.currentStepIndex + 1)
            } else {
                return NumberFormat.formatFixed(root.value, root.precision) + (root.unit.length > 0 ? " " + root.unit : "")
            }
        }
    }

    // ========================================================================
    // 5. Interactive Touch / Mouse Rotary Drag & Wheel
    // ========================================================================
    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: (mouse) => {
            if (pressed) {
                root.updateValueFromPoint(mouse.x, mouse.y)
            }
        }

        onPressed: (mouse) => {
            root.forceActiveFocus()
            root.updateValueFromPoint(mouse.x, mouse.y)
        }

        onWheel: (wheel) => {
            const numSteps = wheel.angleDelta.y / 120.0
            const stepDelta = (root.mode === IndustrialKnob.Mode.Discrete && root.discreteSteps > 1)
                ? ((root.maximum - root.minimum) / (root.discreteSteps - 1))
                : root.step
            const delta = (numSteps !== 0 ? numSteps : (wheel.angleDelta.y > 0 ? 1 : -1)) * stepDelta
            root.setValue(root.value + delta)
        }
    }
}
