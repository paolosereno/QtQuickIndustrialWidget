// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import "NumberFormat.js" as NumberFormat

/**
 * \class CircularBargraph
 * \brief Circular arc indicator composed of discrete curved LED segments in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::CircularBargraph:
 * - Adjustable angular sweep (startAngle and spanAngle, default 270°)
 * - Discrete curved LED segments (e.g. 16, 24, 32, 48)
 * - Operating modes: progressive LED stack (Bar) or single cursor (Dot)
 * - Color zones by angular position (Normal, Warning, Critical Error)
 * - Dimmed unlit ghost segments with subtle zone tint
 * - Floating peak-hold indicator with configurable dwell (peakHoldTimeMs) and linear decay (peakDecayRate)
 * - Central digital readout pod with unit label, precision, and out-of-range indicators (▲ / ▼ / "---")
 * - Blinking end segments for overrange / underrange states (~2 Hz)
 * - Interactive mouse dragging and wheel adjustment
 */
Item {
    id: root

    activeFocusOnTab: true

    enum DisplayMode {
        Bar = 0,
        Dot = 1
    }

    enum ValueState {
        Valid = 0,
        Underrange = 1,
        Overrange = 2,
        Invalid = 3
    }

    // --- Core Value Properties ---
    property real value: 0.0
    property real rawValue: 0.0
    property int valueState: CircularBargraph.ValueState.Valid
    property real minimum: 0.0
    property real maximum: 100.0

    // --- Geometry & Segments ---
    property int segmentCount: 24
    property real startAngle: -135.0 // 0° = 12 o'clock, clockwise
    property real spanAngle: 270.0
    property int displayMode: CircularBargraph.DisplayMode.Bar

    // --- Thresholds & Peak Hold ---
    property real warningThreshold: 70.0
    property real errorThreshold: 85.0
    property bool peakHoldEnabled: true
    property int peakHoldTimeMs: 1200
    property real peakDecayRate: 25.0
    property real peakValue: 0.0

    // --- Readout & Pod ---
    property bool digitalDisplayVisible: true
    property int precision: 1
    property string unit: "%"

    // --- Colors (Matching QtIndustrialWidgets palette) ---
    property color normalColor: "#2ecc71"   // Vivid Emerald Green
    property color warningColor: "#fed330"  // Amber Yellow
    property color errorColor: "#eb3b5a"    // Danger Red
    property color peakColor: "#ffffff"     // Bright White Peak
    property color ghostColor: "#262b35"    // Unlit LED segment
    property color dialColor: "#181c24"     // Deep Slate Chassis
    property color textColor: "#f5f6fa"     // Crisp Text
    property color bezelColor: "#353b48"    // Gunmetal Outer Rim

    // --- Signals ---
    signal rangeChanged(real newMin, real newMax)
    signal thresholdChanged(real warning, real error)
    signal appearanceChanged()

    // --- Size Hints ---
    implicitWidth: 200
    implicitHeight: 200
    width: implicitWidth
    height: implicitHeight

    // --- Geometry Computations ---
    readonly property real side: Math.min(width, height)
    readonly property real cx: width * 0.5
    readonly property real cy: height * 0.5
    readonly property real radius: Math.max(6.0, (side * 0.5) - 4.0)
    readonly property real rOuter: radius * 0.90
    readonly property real rInner: radius * 0.66
    readonly property real podRadius: rInner * 0.90

    // Internal state
    property bool _blinkOn: true
    property real _lastPeakTime: 0
    property real _lastDecayTime: 0

    // --- Value Classification Helper ---
    function classifyInput(raw, min, max) {
        if (isNaN(raw)) {
            return CircularBargraph.ValueState.Invalid
        }
        if (raw < min) {
            return CircularBargraph.ValueState.Underrange
        }
        if (raw > max) {
            return CircularBargraph.ValueState.Overrange
        }
        return CircularBargraph.ValueState.Valid
    }

    function setValue(val) {
        root.rawValue = val
        const newState = classifyInput(val, root.minimum, root.maximum)
        const newValue = (newState === CircularBargraph.ValueState.Invalid)
            ? NaN
            : Math.max(root.minimum, Math.min(root.maximum, val))

        const wasInvalid = (root.valueState === CircularBargraph.ValueState.Invalid)
        if (newState === CircularBargraph.ValueState.Invalid) {
            root.peakValue = NaN
            decayTimer.stop()
        } else {
            updatePeak(newValue, wasInvalid)
        }

        root.value = newValue
        root.valueState = newState

        if (newState === CircularBargraph.ValueState.Overrange || newState === CircularBargraph.ValueState.Underrange) {
            root._blinkOn = true
            blinkTimer.restart()
        } else {
            blinkTimer.stop()
            root._blinkOn = true
        }

        dynamicCanvas.requestPaint()
    }

    function updatePeak(newValue, wasInvalid) {
        if (!root.peakHoldEnabled) {
            root.peakValue = newValue
        } else if (wasInvalid || isNaN(root.peakValue) || newValue >= root.peakValue) {
            root.peakValue = newValue
            root._lastPeakTime = Date.now()
            decayTimer.stop()
        } else if (!decayTimer.running) {
            root._lastDecayTime = Date.now()
            decayTimer.start()
        }
    }

    function resetPeak() {
        root.peakValue = root.value
        decayTimer.stop()
        dynamicCanvas.requestPaint()
    }

    function setRange(min, max) {
        if (!isFinite(min) || !isFinite(max) || min >= max) return
        root.minimum = min
        root.maximum = max
        rangeChanged(min, max)
        setValue(root.rawValue)
        staticBgCanvas.requestPaint()
        dynamicCanvas.requestPaint()
    }

    function setWarningThreshold(warn) {
        if (!isFinite(warn)) return
        root.warningThreshold = warn
        if (warn > root.errorThreshold) {
            root.errorThreshold = warn
        }
        thresholdChanged(root.warningThreshold, root.errorThreshold)
        dynamicCanvas.requestPaint()
    }

    function setErrorThreshold(err) {
        if (!isFinite(err)) return
        root.errorThreshold = err
        if (err < root.warningThreshold) {
            root.warningThreshold = err
        }
        thresholdChanged(root.warningThreshold, root.errorThreshold)
        dynamicCanvas.requestPaint()
    }

    // --- Peak Decay Timer ---
    Timer {
        id: decayTimer
        interval: 33 // ~30 FPS
        repeat: true
        running: false
        onTriggered: {
            if (!root.peakHoldEnabled) {
                root.peakValue = root.value
                decayTimer.stop()
                dynamicCanvas.requestPaint()
                return
            }
            if (root.valueState === CircularBargraph.ValueState.Invalid) {
                decayTimer.stop()
                return
            }
            const now = Date.now()
            if (now - root._lastPeakTime < root.peakHoldTimeMs) {
                return
            }
            const dt = (root._lastDecayTime > 0) ? (now - root._lastDecayTime) / 1000.0 : 0.033
            root._lastDecayTime = now

            const drop = root.peakDecayRate * dt
            if (root.peakValue - root.value <= drop) {
                root.peakValue = root.value
                decayTimer.stop()
            } else {
                root.peakValue = Math.max(root.value, root.peakValue - drop)
            }
            dynamicCanvas.requestPaint()
        }
    }

    // --- Out-of-Range Blinking Timer (~2 Hz) ---
    Timer {
        id: blinkTimer
        interval: 250
        repeat: true
        running: false
        onTriggered: {
            root._blinkOn = !root._blinkOn
            dynamicCanvas.requestPaint()
        }
    }

    // --- Event Handlers & Repaints ---
    onValueChanged: dynamicCanvas.requestPaint()
    onMinimumChanged: { rangeChanged(minimum, maximum); setValue(rawValue); staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }
    onMaximumChanged: { rangeChanged(minimum, maximum); setValue(rawValue); staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }
    onSegmentCountChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onStartAngleChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onSpanAngleChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onDisplayModeChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onWarningThresholdChanged: { thresholdChanged(warningThreshold, errorThreshold); dynamicCanvas.requestPaint(); appearanceChanged() }
    onErrorThresholdChanged: { thresholdChanged(warningThreshold, errorThreshold); dynamicCanvas.requestPaint(); appearanceChanged() }
    onPeakHoldEnabledChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onDigitalDisplayVisibleChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onPrecisionChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onUnitChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onNormalColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onWarningColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onErrorColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onPeakColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onGhostColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onDialColorChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onTextColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onBezelColorChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onWidthChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }
    onHeightChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }

    Component.onCompleted: {
        setValue(value)
        staticBgCanvas.requestPaint()
        dynamicCanvas.requestPaint()
    }

    // --- Helper: Unlit Tint Blend ---
    function unlitTint(zoneCol, ghostCol) {
        const weight = 0.25
        const z = Qt.color(zoneCol)
        const g = Qt.color(ghostCol)
        return Qt.rgba(
            weight * z.r + (1.0 - weight) * g.r,
            weight * z.g + (1.0 - weight) * g.g,
            weight * z.b + (1.0 - weight) * g.b,
            1.0
        ).toString()
    }

    // --- 1. Static Dial Face Canvas ---
    Canvas {
        id: staticBgCanvas
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
            if (r <= 6.0) return

            // Outer Machined Bezel Rim
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

            // Dial Chassis Plate
            const innerR = r * 0.95
            const dialGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, innerR)
            dialGrad.addColorStop(0.0, Qt.lighter(root.dialColor, 1.05).toString())
            dialGrad.addColorStop(0.70, root.dialColor.toString())
            dialGrad.addColorStop(1.0, Qt.darker(root.dialColor, 1.30).toString())

            ctx.beginPath()
            ctx.arc(cx, cy, innerR, 0, 2 * Math.PI)
            ctx.fillStyle = dialGrad
            ctx.fill()
            ctx.lineWidth = 1.0
            ctx.strokeStyle = Qt.darker(root.dialColor, 1.5).toString()
            ctx.stroke()
        }
    }

    // --- 2. Dynamic LED Segments & Digital Pod Canvas ---
    Canvas {
        id: dynamicCanvas
        anchors.fill: parent
        z: 1

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
            if (r <= 6.0) return

            const rOut = root.rOuter
            const rIn = root.rInner
            const N = Math.max(4, root.segmentCount)
            const stepAngle = root.spanAngle / N

            let gapAngle = stepAngle * 0.18
            gapAngle = Math.max(0.4, Math.min(4.0, gapAngle))
            const segSpan = Math.max(0.2, stepAngle - gapAngle)

            // Segment Zones Computation
            const span = root.maximum - root.minimum
            function atOrAbove(i, threshold) {
                if (span === 0.0) {
                    return root.minimum >= threshold
                }
                const pos = (threshold - root.minimum) * N / span
                return (span > 0.0) ? (i + 0.5 >= pos) : (i + 0.5 <= pos)
            }

            const zones = new Array(N)
            for (let i = 0; i < N; ++i) {
                if (atOrAbove(i, root.errorThreshold)) {
                    zones[i] = 2 // Error
                } else if (atOrAbove(i, root.warningThreshold)) {
                    zones[i] = 1 // Warning
                } else {
                    zones[i] = 0 // Normal
                }
            }

            // Segment States Computation
            const states = new Array(N)
            if (root.valueState === CircularBargraph.ValueState.Invalid) {
                states.fill(3) // Ghost
            } else {
                states.fill(0) // Off
                if (span > 0.0) {
                    function litCount(v) {
                        let f = (v - root.minimum) / span
                        f = isFinite(f) ? Math.max(0.0, Math.min(1.0, f)) : 0.0
                        return Math.max(0, Math.min(N, Math.round(f * N)))
                    }

                    const n = litCount(root.value)
                    let topLit = n - 1

                    if (root.displayMode === CircularBargraph.DisplayMode.Dot) {
                        topLit = Math.max(0, n - 1)
                        states[topLit] = 1 // Lit
                    } else {
                        for (let i = 0; i < n; ++i) {
                            states[i] = 1 // Lit
                        }
                    }

                    if (root.peakHoldEnabled) {
                        const peakIndex = litCount(root.peakValue) - 1
                        if (peakIndex > topLit && peakIndex >= 0 && peakIndex < N) {
                            states[peakIndex] = 2 // Peak
                        }
                    }

                    let blinkIndex = -1
                    if (root.valueState === CircularBargraph.ValueState.Overrange) {
                        blinkIndex = N - 1
                    } else if (root.valueState === CircularBargraph.ValueState.Underrange) {
                        blinkIndex = 0
                    }

                    if (blinkIndex >= 0 && blinkIndex < N) {
                        states[blinkIndex] = root._blinkOn ? 1 : 0
                    }
                }
            }

            // Draw Curved LED Segments
            for (let i = 0; i < N; ++i) {
                const aStart = root.startAngle + i * stepAngle + (gapAngle * 0.5)
                const aEnd = aStart + segSpan

                // Convert clockwise 0° (12 o'clock) to Canvas radians
                const radStart = (aStart - 90.0) * Math.PI / 180.0
                const radEnd = (aEnd - 90.0) * Math.PI / 180.0

                ctx.beginPath()
                ctx.arc(cx, cy, rOut, radStart, radEnd, false)
                ctx.arc(cx, cy, rIn, radEnd, radStart, true)
                ctx.closePath()

                const z = zones[i]
                const segZoneColor = (z === 2) ? root.errorColor : (z === 1) ? root.warningColor : root.normalColor
                const st = states[i]

                if (st === 2) { // Peak
                    ctx.fillStyle = root.peakColor.toString()
                } else if (st === 1) { // Lit
                    ctx.fillStyle = segZoneColor.toString()
                } else if (st === 0) { // Off
                    ctx.fillStyle = root.unlitTint(segZoneColor, root.ghostColor)
                } else { // Ghost
                    ctx.fillStyle = root.ghostColor.toString()
                }

                ctx.fill()
            }

            // Draw Central Digital Readout Pod
            if (root.digitalDisplayVisible) {
                const podR = root.podRadius

                // Recessed well
                const podGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, podR)
                podGrad.addColorStop(0.0, Qt.darker(root.dialColor, 1.45).toString())
                podGrad.addColorStop(0.85, Qt.darker(root.dialColor, 1.30).toString())
                podGrad.addColorStop(1.0, Qt.darker(root.dialColor, 1.60).toString())

                ctx.beginPath()
                ctx.arc(cx, cy, podR, 0, 2 * Math.PI)
                ctx.fillStyle = podGrad
                ctx.fill()
                ctx.lineWidth = 1.0
                ctx.strokeStyle = Qt.darker(root.dialColor, 1.8).toString()
                ctx.stroke()

                // Specular highlight rim around inner pod
                ctx.beginPath()
                ctx.arc(cx, cy, podR, 0.75 * Math.PI, 1.75 * Math.PI)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.08)"
                ctx.lineWidth = 1.0
                ctx.stroke()

                // Text Formatting
                let textStr = ""
                const st = root.valueState
                if (st === CircularBargraph.ValueState.Valid) {
                    textStr = NumberFormat.formatFixed(root.value, root.precision)
                } else if (st === CircularBargraph.ValueState.Underrange) {
                    textStr = isFinite(root.rawValue)
                        ? NumberFormat.formatFixed(root.rawValue, root.precision)
                        : ("<" + NumberFormat.formatFixed(root.minimum, root.precision))
                } else if (st === CircularBargraph.ValueState.Overrange) {
                    textStr = isFinite(root.rawValue)
                        ? NumberFormat.formatFixed(root.rawValue, root.precision)
                        : (">" + NumberFormat.formatFixed(root.maximum, root.precision))
                } else {
                    textStr = "---"
                }

                const valuePt = Math.max(9, Math.floor(podR * 0.40))
                const unitPt = Math.max(7, Math.floor(valuePt * 0.52))
                const hasUnit = root.unit.length > 0 && st !== CircularBargraph.ValueState.Invalid

                ctx.font = "bold " + valuePt + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"

                const valY = hasUnit ? (cy - podR * 0.12) : cy
                const textCol = (st === CircularBargraph.ValueState.Overrange)
                    ? root.errorColor
                    : (st === CircularBargraph.ValueState.Underrange)
                        ? root.warningColor
                        : root.textColor

                ctx.fillStyle = textCol.toString()

                // Draw Out-of-Range Triangle Marker
                if (st === CircularBargraph.ValueState.Underrange || st === CircularBargraph.ValueState.Overrange) {
                    const triSize = valuePt * 0.7
                    const textW = ctx.measureText(textStr).width
                    const triX = cx - (textW * 0.5) - triSize * 0.6
                    const triY = valY

                    ctx.beginPath()
                    if (st === CircularBargraph.ValueState.Overrange) {
                        // Triangle Up ▲
                        ctx.moveTo(triX, triY - triSize * 0.5)
                        ctx.lineTo(triX + triSize * 0.45, triY + triSize * 0.4)
                        ctx.lineTo(triX - triSize * 0.45, triY + triSize * 0.4)
                    } else {
                        // Triangle Down ▼
                        ctx.moveTo(triX, triY + triSize * 0.5)
                        ctx.lineTo(triX + triSize * 0.45, triY - triSize * 0.4)
                        ctx.lineTo(triX - triSize * 0.45, triY - triSize * 0.4)
                    }
                    ctx.closePath()
                    ctx.fill()
                }

                ctx.fillText(textStr, cx, valY)

                // Draw Unit Label
                if (hasUnit) {
                    ctx.font = unitPt + "px sans-serif"
                    ctx.fillStyle = Qt.darker(root.textColor, 1.25).toString()
                    ctx.fillText(root.unit, cx, cy + podR * 0.42)
                }
            }
        }
    }

    // --- Interactive Mouse & Touch Control ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        function updateFromPos(px, py) {
            const dx = px - root.cx
            const dy = py - root.cy
            // Polar angle in degrees (0° = 12 o'clock, clockwise)
            let deg = Math.atan2(dx, -dy) * 180.0 / Math.PI

            // Normalize relative to startAngle
            let diff = deg - root.startAngle
            while (diff < 0.0) diff += 360.0
            while (diff >= 360.0) diff -= 360.0

            if (diff <= root.spanAngle) {
                const fraction = diff / root.spanAngle
                const targetVal = root.minimum + fraction * (root.maximum - root.minimum)
                root.setValue(targetVal)
            }
        }

        onPressed: (mouse) => {
            root.forceActiveFocus()
            updateFromPos(mouse.x, mouse.y)
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                updateFromPos(mouse.x, mouse.y)
            }
        }

        onWheel: (wheel) => {
            const step = (root.maximum - root.minimum) / Math.max(1, root.segmentCount)
            if (wheel.angleDelta.y > 0) {
                root.setValue(root.value + step)
            } else if (wheel.angleDelta.y < 0) {
                root.setValue(root.value - step)
            }
        }
    }

    // --- Keyboard Navigation ---
    Keys.onPressed: (event) => {
        const step = (root.maximum - root.minimum) / Math.max(1, root.segmentCount)
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.setValue(root.value - step)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.setValue(root.value + step)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.setValue(root.minimum)
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.setValue(root.maximum)
            event.accepted = true
        }
    }
}
