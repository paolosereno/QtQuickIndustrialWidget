// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes
import "NumberFormat.js" as NumberFormat

/**
 * \class RadialGauge
 * \brief High-performance circular dial gauge in Qt Quick.
 *
 * Equivalent to QtIndustrialWidgets::RadialGauge with GPU-accelerated needle rotation,
 * configurable angular span (default 270°), graduation ticks, warning and error
 * threshold arc bands, recessed digital readout pod, 3D faceted vector needle,
 * and realistic inertia/damping animations (SmoothedAnimation).
 */
Item {
    id: root

    // --- Range & Value Properties ---
    property real minimum: 0.0
    property real maximum: 100.0
    property real value: 0.0
    property int precision: 1
    property string unit: "bar"

    // --- Dial Geometry & Angles ---
    // 0° is at 12 o'clock, clockwise. Default: -135° to +135° (270° span)
    property real startAngle: -135.0
    property real spanAngle: 270.0
    property int majorTicks: 10
    property int minorTicks: 4

    // --- Thresholds ---
    property real warningThreshold: 70.0
    property real errorThreshold: 85.0
    property bool thresholdBandsVisible: true
    property bool digitalDisplayVisible: true

    // --- Animation ---
    property bool animated: true
    property real animationVelocity: 360.0 // deg/s

    // --- Colors (Palette matching C++ QtIndustrialWidgets) ---
    property color needleColor: "#eb3b5a"    // Industrial Crimson
    property color normalColor: "#26de81"    // Neon Emerald Green
    property color warningColor: "#fed330"   // Amber Gold
    property color errorColor: "#eb3b5a"     // Danger Red
    property color dialColor: "#181c24"      // Slate Black
    property color scaleColor: "#d2dae2"     // Light Silver
    property color textColor: "#f5f6fa"      // Crisp White
    property color bezelColor: "#353b48"     // Gunmetal Gray

    // --- Signals ---
    signal warningExceeded(bool exceeded)
    signal errorExceeded(bool exceeded)
    signal rangeChanged(real min, real max)
    signal appearanceChanged()

    // --- Size Hint & Default Geometry ---
    implicitWidth: 220
    implicitHeight: 220
    width: implicitWidth
    height: implicitHeight

    // --- Clamp & Threshold Tracking ---
    property bool _wasWarning: false
    property bool _wasError: false

    readonly property real clampedValue: {
        if (isNaN(value)) return minimum
        if (!isFinite(value)) return value > 0 ? maximum : minimum
        return Math.max(minimum, Math.min(maximum, value))
    }

    onClampedValueChanged: {
        const isWarn = (clampedValue >= warningThreshold && clampedValue < errorThreshold)
        const isErr = (clampedValue >= errorThreshold)
        if (isWarn !== _wasWarning) {
            _wasWarning = isWarn
            warningExceeded(isWarn)
        }
        if (isErr !== _wasError) {
            _wasError = isErr
            errorExceeded(isErr)
        }
    }

    // --- Functions ---
    function setValue(val) {
        if (isNaN(val)) return
        if (!isFinite(val)) {
            val = (val > 0.0) ? maximum : minimum
        }
        root.value = Math.max(minimum, Math.min(maximum, val))
    }

    function setRange(min, max) {
        if (!isFinite(min) || !isFinite(max) || min >= max) return
        if (root.minimum === min && root.maximum === max) return
        root.minimum = min
        root.maximum = max
        rangeChanged(root.minimum, root.maximum)
        appearanceChanged()
        staticDialCanvas.requestPaint()
    }

    function setMinimum(min) {
        setRange(min, root.maximum)
    }

    function setMaximum(max) {
        setRange(root.minimum, max)
    }

    function valueToAngle(val) {
        if (maximum <= minimum) return startAngle
        const factor = Math.max(0.0, Math.min(1.0, (val - minimum) / (maximum - minimum)))
        return startAngle + factor * spanAngle
    }

    // --- Geometry Computations ---
    readonly property real side: Math.min(width, height)
    readonly property real cx: width * 0.5
    readonly property real cy: height * 0.5
    readonly property real radius: Math.max(5.0, (side * 0.5) - 4.0)

    readonly property real arcRadius: radius * 0.82
    readonly property real arcWidth: Math.max(3.0, radius * 0.055)
    readonly property real tickOuter: arcRadius - arcWidth * 0.6
    readonly property real majorTickInner: tickOuter - radius * 0.09
    readonly property real minorTickInner: tickOuter - radius * 0.045
    readonly property real labelRadius: majorTickInner - radius * 0.12
    readonly property int labelFontPx: Math.max(7, Math.floor(radius * 0.082))

    readonly property real needleLen: radius * 0.76
    readonly property real needleTail: radius * 0.18
    readonly property real needleBaseW: Math.max(2.5, radius * 0.042)
    readonly property real pivotRadius: Math.max(4.0, radius * 0.11)

    // Digital Pod layout
    readonly property real podWidth: Math.min(radius * 0.72, Math.max(48.0, radius * 0.45))
    readonly property real podHeight: Math.max(16.0, radius * 0.22)
    readonly property real podX: cx - podWidth * 0.5
    readonly property real podY: cy + radius * 0.32
    readonly property int podFontPx: Math.max(8, Math.floor(radius * 0.13))
    readonly property int unitFontPx: Math.max(7, Math.floor(radius * 0.07))

    readonly property real targetAngle: valueToAngle(clampedValue)

    onWidthChanged: staticDialCanvas.requestPaint()
    onHeightChanged: staticDialCanvas.requestPaint()
    onStartAngleChanged: staticDialCanvas.requestPaint()
    onSpanAngleChanged: staticDialCanvas.requestPaint()
    onMajorTicksChanged: staticDialCanvas.requestPaint()
    onMinorTicksChanged: staticDialCanvas.requestPaint()
    onWarningThresholdChanged: staticDialCanvas.requestPaint()
    onErrorThresholdChanged: staticDialCanvas.requestPaint()
    onThresholdBandsVisibleChanged: staticDialCanvas.requestPaint()
    onDialColorChanged: staticDialCanvas.requestPaint()
    onScaleColorChanged: staticDialCanvas.requestPaint()
    onBezelColorChanged: staticDialCanvas.requestPaint()
    onTextColorChanged: staticDialCanvas.requestPaint()
    onUnitChanged: staticDialCanvas.requestPaint()

    // 1. Static Dial Face Cache (Bezel, Shadow, Ticks, Labels, Unit & Pod Frame)
    Canvas {
        id: staticDialCanvas
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
            if (r <= 5.0) return

            // --- A. Outer Machined Bezel Rim ---
            const bezelGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
            bezelGrad.addColorStop(0.0, Qt.lighter(root.dialColor, 1.10).toString())
            bezelGrad.addColorStop(0.85, root.dialColor.toString())
            bezelGrad.addColorStop(0.96, Qt.lighter(root.bezelColor, 1.30).toString())
            bezelGrad.addColorStop(1.0, Qt.darker(root.bezelColor, 1.40).toString())

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.fillStyle = bezelGrad
            ctx.fill()
            ctx.lineWidth = 1.5
            ctx.strokeStyle = Qt.darker(root.bezelColor, 1.6).toString()
            ctx.stroke()

            // --- B. Inner Shadow Ring ---
            const innerR = r * 0.95
            const dialGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, innerR)
            dialGrad.addColorStop(0.0, Qt.lighter(root.dialColor, 1.05).toString())
            dialGrad.addColorStop(0.70, root.dialColor.toString())
            dialGrad.addColorStop(1.0, Qt.darker(root.dialColor, 1.25).toString())

            ctx.beginPath()
            ctx.arc(cx, cy, innerR, 0, 2 * Math.PI)
            ctx.fillStyle = dialGrad
            ctx.fill()
            ctx.lineWidth = 1.0
            ctx.strokeStyle = Qt.darker(root.dialColor, 1.5).toString()
            ctx.stroke()

            // --- C. Threshold Bands (if visible) ---
            if (root.thresholdBandsVisible) {
                const drawArc = (v1, v2, col) => {
                    if (v1 >= v2) return
                    const a1 = (root.valueToAngle(v1) - 90.0) * Math.PI / 180.0
                    const a2 = (root.valueToAngle(v2) - 90.0) * Math.PI / 180.0
                    ctx.beginPath()
                    ctx.arc(cx, cy, root.arcRadius, a1, a2)
                    ctx.lineWidth = root.arcWidth
                    ctx.strokeStyle = col.toString()
                    ctx.lineCap = "butt"
                    ctx.stroke()
                }

                const vNormEnd = Math.min(root.warningThreshold, root.maximum)
                const vWarnEnd = Math.min(root.errorThreshold, root.maximum)

                if (root.warningThreshold > root.minimum) {
                    drawArc(root.minimum, vNormEnd, root.normalColor)
                }
                if (root.errorThreshold > root.warningThreshold && root.warningThreshold < root.maximum) {
                    drawArc(root.warningThreshold, vWarnEnd, root.warningColor)
                }
                if (root.errorThreshold < root.maximum) {
                    drawArc(root.errorThreshold, root.maximum, root.errorColor)
                }
            }

            // --- D. Minor Ticks ---
            if (root.minorTicks > 0 && root.majorTicks > 0) {
                const totalMinor = root.majorTicks * (root.minorTicks + 1)
                const range = root.maximum - root.minimum
                ctx.lineWidth = Math.max(1.0, r * 0.012)
                ctx.strokeStyle = Qt.darker(root.scaleColor, 1.2).toString()
                ctx.lineCap = "round"

                for (let i = 0; i <= totalMinor; ++i) {
                    if (i % (root.minorTicks + 1) === 0) continue
                    const frac = i / totalMinor
                    const val = root.minimum + frac * range
                    const ang = (root.valueToAngle(val) - 90.0) * Math.PI / 180.0
                    const cosA = Math.cos(ang)
                    const sinA = Math.sin(ang)

                    ctx.beginPath()
                    ctx.moveTo(cx + root.minorTickInner * cosA, cy + root.minorTickInner * sinA)
                    ctx.lineTo(cx + root.tickOuter * cosA, cy + root.tickOuter * sinA)
                    ctx.stroke()
                }
            }

            // --- E. Major Ticks & Scale Numbers ---
            if (root.majorTicks > 0) {
                const range = root.maximum - root.minimum
                ctx.lineWidth = Math.max(1.8, r * 0.022)
                ctx.strokeStyle = root.scaleColor.toString()
                ctx.lineCap = "round"
                ctx.fillStyle = root.textColor.toString()
                ctx.font = `bold ${root.labelFontPx}px sans-serif`
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"

                for (let i = 0; i <= root.majorTicks; ++i) {
                    const frac = i / root.majorTicks
                    const val = root.minimum + frac * range
                    const ang = (root.valueToAngle(val) - 90.0) * Math.PI / 180.0
                    const cosA = Math.cos(ang)
                    const sinA = Math.sin(ang)

                    // Major tick mark
                    ctx.beginPath()
                    ctx.moveTo(cx + root.majorTickInner * cosA, cy + root.majorTickInner * sinA)
                    ctx.lineTo(cx + root.tickOuter * cosA, cy + root.tickOuter * sinA)
                    ctx.stroke()

                    // Numeric label text
                    const labelText = NumberFormat.scaleLabelText(val, root.precision)
                    const lx = cx + root.labelRadius * cosA
                    const ly = cy + root.labelRadius * sinA
                    ctx.fillText(labelText, lx, ly)
                }
            }

            // --- F. Static Unit Text above pod ---
            if (root.digitalDisplayVisible && root.podWidth > 0 && root.unit.length > 0) {
                ctx.font = `${root.unitFontPx}px sans-serif`
                ctx.fillStyle = Qt.darker(root.scaleColor, 1.1).toString()
                ctx.textAlign = "center"
                ctx.textBaseline = "bottom"
                ctx.fillText(root.unit, cx, root.podY - 2.0)
            }
        }
    }

    // 2. Recessed Digital Readout Pod Background
    Rectangle {
        id: podBackground
        z: 1
        visible: root.digitalDisplayVisible && root.podWidth > 0
        x: root.podX
        y: root.podY
        width: root.podWidth
        height: root.podHeight
        radius: 4.0
        border.width: 1.2
        border.color: Qt.darker(root.bezelColor, 1.2)
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(10/255, 12/255, 16/255, 0.88) }
            GradientStop { position: 1.0; color: Qt.rgba(22/255, 26/255, 34/255, 0.88) }
        }
    }

    // 3. Dynamic Digital Readout Value (Over the cached pod)
    Text {
        id: digitalReadout
        z: 2
        visible: root.digitalDisplayVisible && root.podWidth > 0
        x: root.podX
        y: root.podY
        width: root.podWidth
        height: root.podHeight
        text: NumberFormat.formatFixed(root.clampedValue, root.precision)
        font.pixelSize: root.podFontPx
        font.bold: true
        font.family: "monospace, sans-serif"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: {
            if (root.clampedValue >= root.errorThreshold) {
                return root.errorColor
            } else if (root.clampedValue >= root.warningThreshold) {
                return root.warningColor
            } else {
                return root.textColor
            }
        }
    }

    // 4. Dynamic Vector Needle (GPU-transformed with fluid animation)
    Item {
        id: needleHub
        z: 3
        x: root.cx
        y: root.cy
        width: 1
        height: 1

        rotation: root.targetAngle

        Behavior on rotation {
            enabled: root.animated
            SmoothedAnimation {
                velocity: root.animationVelocity
                reversingMode: SmoothedAnimation.Immediate
            }
        }

        // Vector Needle Blade
        Shape {
            anchors.centerIn: parent

            // Left facet (Light tone)
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.lighter(root.needleColor, 1.25)
                PathMove { x: 0; y: -root.needleLen }
                PathLine { x: -root.needleBaseW; y: 0 }
                PathLine { x: -root.needleBaseW * 0.5; y: root.needleTail }
                PathLine { x: 0; y: root.needleTail }
                PathLine { x: 0; y: -root.needleLen }
            }

            // Right facet (Shaded tone)
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.darker(root.needleColor, 1.20)
                PathMove { x: 0; y: -root.needleLen }
                PathLine { x: 0; y: root.needleTail }
                PathLine { x: root.needleBaseW * 0.5; y: root.needleTail }
                PathLine { x: root.needleBaseW; y: 0 }
                PathLine { x: 0; y: -root.needleLen }
            }

            // Sharp central 3D specular ridge line
            ShapePath {
                strokeWidth: 1.0
                strokeColor: Qt.rgba(1, 1, 1, 0.63)
                PathMove { x: 0; y: -root.needleLen + 4.0 }
                PathLine { x: 0; y: root.needleTail - 2.0 }
            }
        }
    }

    // 5. Center Chrome Pivot Cap (Industrial Multi-stage Hub)
    Shape {
        id: pivotCap
        z: 4
        anchors.fill: parent

        // Outer Bezel Rim
        ShapePath {
            strokeWidth: 1.2
            strokeColor: Qt.darker(root.dialColor, 1.8)
            fillGradient: RadialGradient {
                centerX: root.cx
                centerY: root.cy
                centerRadius: root.pivotRadius
                GradientStop { position: 0.0; color: Qt.lighter(root.bezelColor, 1.5) }
                GradientStop { position: 0.7; color: Qt.darker(root.bezelColor, 1.1) }
                GradientStop { position: 1.0; color: Qt.darker(root.bezelColor, 1.8) }
            }
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.pivotRadius
                radiusY: root.pivotRadius
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Inner Brushed Cap
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.cx
                centerY: root.cy
                centerRadius: root.pivotRadius * 0.65
                GradientStop { position: 0.0; color: "#dce1e6" }
                GradientStop { position: 0.5; color: Qt.lighter(root.dialColor, 1.3) }
                GradientStop { position: 1.0; color: root.dialColor }
            }
            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.pivotRadius * 0.65
                radiusY: root.pivotRadius * 0.65
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Specular Reflection Highlight Dot
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Qt.rgba(1, 1, 1, 0.70)
            PathAngleArc {
                centerX: root.cx - root.pivotRadius * 0.65 * 0.3
                centerY: root.cy - root.pivotRadius * 0.65 * 0.3
                radiusX: root.pivotRadius * 0.65 * 0.25
                radiusY: root.pivotRadius * 0.65 * 0.25
                startAngle: 0
                sweepAngle: 360
            }
        }
    }
}
