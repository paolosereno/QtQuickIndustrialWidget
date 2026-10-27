// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import "NumberFormat.js" as NumberFormat

/**
 * \class LinearGauge
 * \brief High-performance linear bar and bulb thermometer gauge in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::LinearGauge:
 * - Vertical and horizontal orientations
 * - Bulb thermometer or flat rectangular panel bar styles
 * - Major and minor graduation scales with intelligent collision-free numeric labels
 * - Dynamic liquid color shifting based on warning/error thresholds
 * - Continuous multi-color gradient liquid option
 * - Recessed dark glass trough with glossy specular highlight reflection
 * - High-contrast digital value readout pod
 * - Cached static background for 60 FPS GPU-accelerated liquid animation
 * - Interactive mouse drag and wheel adjustment
 */
Item {
    id: root

    // --- Enums & Orientation ---
    enum Orientation {
        Vertical = 1,
        Horizontal = 2
    }

    property int orientation: LinearGauge.Orientation.Vertical
    property bool thermometerMode: true

    // --- Range & Value Properties ---
    property real minimum: 0.0
    property real maximum: 100.0
    property real value: 36.6
    property int precision: 1
    property string unit: "°C"

    // --- Scale & Ticks ---
    property int majorTicks: 10
    property int minorTicks: 4
    property bool scaleVisible: true
    property bool digitalDisplayVisible: true

    // --- Thresholds & Liquid Color Behavior ---
    property real warningThreshold: 70.0
    property real errorThreshold: 90.0
    property bool dynamicLiquidColor: true
    property bool gradientLiquid: false

    // --- Colors (Exact match to QtIndustrialWidgets palette) ---
    property color liquidColor: "#eb3b5a"       // Classic Thermometer Red
    property color normalColor: "#2ecc71"       // Emerald Normal
    property color warningColor: "#f1c40f"      // Sun Yellow / Amber
    property color errorColor: "#e74c3c"        // Alizarin Red
    property color troughColor: "#1e242d"       // Dark Glass Trough
    property color scaleColor: "#c8d0da"        // Silver Scale Ticks
    property color textColor: "#f0f4f8"         // Crisp Off-White
    property color bezelColor: "#2c3540"        // Gunmetal Casing Bezel

    // --- Smooth Animation ---
    property bool animated: true
    property real animationVelocity: Math.max(10.0, (maximum - minimum) * 2.0) // Units per second
    property real animatedValue: value

    Behavior on animatedValue {
        enabled: root.animated && !dragArea.pressed
        SmoothedAnimation {
            velocity: root.animationVelocity
            reversingMode: SmoothedAnimation.Immediate
        }
    }

    // Signals
    signal rangeChanged(real min, real max)
    signal thresholdChanged(real warning, real error)
    signal appearanceChanged()

    // Default Size Hints
    implicitWidth: (orientation === LinearGauge.Orientation.Vertical) ? 100 : 320
    implicitHeight: (orientation === LinearGauge.Orientation.Vertical) ? 280 : 90
    width: implicitWidth
    height: implicitHeight

    // Active Liquid Color Determination
    readonly property color activeLiquidColor: {
        if (!dynamicLiquidColor) {
            return liquidColor
        }
        if (animatedValue >= errorThreshold) {
            return errorColor
        }
        if (animatedValue >= warningThreshold) {
            return warningColor
        }
        return normalColor
    }

    // Normalized Fill Factor [0.0, 1.0]
    readonly property real factor: {
        if (maximum <= minimum) return 0.0
        return Math.max(0.0, Math.min(1.0, (animatedValue - minimum) / (maximum - minimum)))
    }

    // --- Layout Computations (Exact match to LinearGaugeScale.cpp) ---
    readonly property bool isVert: (orientation === LinearGauge.Orientation.Vertical)

    // Tube & Bulb Dimensions
    readonly property real tubeThickness: isVert ? Math.max(10.0, Math.min(26.0, width * 0.16))
                                                 : Math.max(10.0, Math.min(26.0, height * 0.16))

    readonly property real bulbRadius: thermometerMode ? tubeThickness * 1.35 : 0.0

    readonly property real scaleLength: {
        if (isVert) {
            const top = digitalDisplayVisible ? 36.0 : 16.0
            const bottom = thermometerMode ? bulbRadius * 2.0 + 12.0 : 16.0
            return Math.max(10.0, (height - bottom) - top)
        } else {
            const left = thermometerMode ? bulbRadius * 2.0 + 12.0 : 16.0
            const right = digitalDisplayVisible ? 55.0 : 16.0
            return Math.max(10.0, (width - right) - left)
        }
    }

    readonly property real tubeX: {
        if (isVert) {
            return scaleVisible ? (width * 0.32 - tubeThickness * 0.5) : (width * 0.5 - tubeThickness * 0.5)
        } else {
            return thermometerMode ? bulbRadius * 2.0 + 12.0 : 16.0
        }
    }

    readonly property real tubeY: {
        if (isVert) {
            return digitalDisplayVisible ? 36.0 : 16.0
        } else {
            return scaleVisible ? (height * 0.40 - tubeThickness * 0.5) : (height * 0.5 - tubeThickness * 0.5)
        }
    }

    readonly property real tubeW: isVert ? tubeThickness : scaleLength
    readonly property real tubeH: isVert ? scaleLength : tubeThickness

    readonly property real bulbCenterX: isVert ? (tubeX + tubeThickness * 0.5) : (bulbRadius + 8.0)
    readonly property real bulbCenterY: isVert ? (height - bulbRadius - 8.0) : (tubeY + tubeThickness * 0.5)

    // Digital Pod Rect
    readonly property real podX: isVert ? 6.0 : (width - 55.0 + 4.0)
    readonly property real podY: 6.0
    readonly property real podW: isVert ? (width - 12.0) : (55.0 - 10.0)
    readonly property real podH: isVert ? 24.0 : (height - 12.0)

    // --- Interactive Mouse Updates ---
    function updateValueFromPos(px, py) {
        let f = 0.0
        if (isVert) {
            const bottom = tubeY + tubeH
            f = (bottom - py) / tubeH
        } else {
            f = (px - tubeX) / tubeW
        }
        f = Math.max(0.0, Math.min(1.0, f))
        root.value = root.minimum + f * (root.maximum - root.minimum)
    }

    // Trigger Static Scale Re-render on Structural Changes
    onWidthChanged: staticScaleCanvas.requestPaint()
    onHeightChanged: staticScaleCanvas.requestPaint()
    onOrientationChanged: staticScaleCanvas.requestPaint()
    onThermometerModeChanged: staticScaleCanvas.requestPaint()
    onMinimumChanged: staticScaleCanvas.requestPaint()
    onMaximumChanged: staticScaleCanvas.requestPaint()
    onPrecisionChanged: staticScaleCanvas.requestPaint()
    onMajorTicksChanged: staticScaleCanvas.requestPaint()
    onMinorTicksChanged: staticScaleCanvas.requestPaint()
    onScaleVisibleChanged: staticScaleCanvas.requestPaint()
    onDigitalDisplayVisibleChanged: staticScaleCanvas.requestPaint()
    onScaleColorChanged: staticScaleCanvas.requestPaint()
    onTextColorChanged: staticScaleCanvas.requestPaint()
    onTroughColorChanged: staticScaleCanvas.requestPaint()
    onBezelColorChanged: staticScaleCanvas.requestPaint()

    onFactorChanged: dynamicCanvas.requestPaint()
    onActiveLiquidColorChanged: dynamicCanvas.requestPaint()

    // ========================================================================
    // 1. Static Scale & Casing Canvas (Cached, rendered only on geometry change)
    // ========================================================================
    Canvas {
        id: staticScaleCanvas
        anchors.fill: parent
        z: 0

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            if (typeof ctx.reset === "function") {
                ctx.reset()
            }
            ctx.clearRect(0, 0, width, height)

            const w = width
            const h = height
            if (w <= 10 || h <= 10) return

            // 1. Outer Casing Bezel with Brushed Gunmetal Gradient
            const casingGrad = ctx.createLinearGradient(0, 0, w, h)
            casingGrad.addColorStop(0.0, Qt.lighter(root.bezelColor, 1.15).toString())
            casingGrad.addColorStop(1.0, Qt.darker(root.bezelColor, 1.35).toString())
            ctx.fillStyle = casingGrad
            ctx.strokeStyle = Qt.darker(root.bezelColor, 1.60).toString()
            ctx.lineWidth = 1.5

            drawRoundRect(ctx, 1.0, 1.0, w - 2.0, h - 2.0, 6.0)
            ctx.fill()
            ctx.stroke()

            // 2. Empty Glass Trough Background
            const tx = root.tubeX
            const ty = root.tubeY
            const tw = root.tubeW
            const th = root.tubeH

            const troughGrad = root.isVert ? ctx.createLinearGradient(tx, ty, tx + tw, ty)
                                           : ctx.createLinearGradient(tx, ty, tx, ty + th)
            troughGrad.addColorStop(0.0, Qt.darker(root.troughColor, 1.50).toString())
            troughGrad.addColorStop(0.3, Qt.darker(root.troughColor, 1.10).toString())
            troughGrad.addColorStop(0.7, root.troughColor.toString())
            troughGrad.addColorStop(1.0, Qt.darker(root.troughColor, 1.40).toString())

            ctx.fillStyle = troughGrad
            ctx.strokeStyle = Qt.darker(root.bezelColor, 1.80).toString()
            ctx.lineWidth = 1.2

            if (root.thermometerMode) {
                // Bulb Trough
                ctx.beginPath()
                ctx.arc(root.bulbCenterX, root.bulbCenterY, root.bulbRadius, 0, Math.PI * 2)
                ctx.fill()
                ctx.stroke()

                // Tube Trough
                drawRoundRect(ctx, tx, ty, tw, th, root.tubeThickness * 0.5)
                ctx.fill()
                ctx.stroke()
            } else {
                drawRoundRect(ctx, tx, ty, tw, th, 4.0)
                ctx.fill()
                ctx.stroke()
            }

            // 3. Graduation Ticks & Numeric Labels
            if (root.scaleVisible && root.maximum > root.minimum && root.majorTicks > 0) {
                const totalMinorDivisions = root.majorTicks * (root.minorTicks + 1)
                const valRange = root.maximum - root.minimum

                if (root.isVert) {
                    const tickStartX = tx + tw + 6.0
                    const majorTickLen = Math.max(6.0, w * 0.12)
                    const minorTickLen = majorTickLen * 0.55
                    const labelX = tickStartX + majorTickLen + 5.0

                    // Minor Ticks
                    if (root.minorTicks > 0) {
                        ctx.strokeStyle = Qt.darker(root.scaleColor, 1.30).toString()
                        ctx.lineWidth = 1.0
                        for (let i = 0; i <= totalMinorDivisions; ++i) {
                            if (i % (root.minorTicks + 1) === 0) continue
                            const frac = i / totalMinorDivisions
                            const y = ty + th - frac * th
                            ctx.beginPath()
                            ctx.moveTo(tickStartX, y)
                            ctx.lineTo(tickStartX + minorTickLen, y)
                            ctx.stroke()
                        }
                    }

                    // Major Ticks & Labels
                    const fontSize = Math.max(8, Math.min(11, Math.floor(h * 0.04)))
                    ctx.font = `bold ${fontSize}px sans-serif`
                    ctx.textAlign = "left"
                    ctx.textBaseline = "middle"

                    // Calculate label step to prevent overlapping
                    const labelHeight = fontSize + 4.0
                    const step = Math.max(1, Math.ceil((root.majorTicks + 1) * labelHeight / th))

                    for (let i = 0; i <= root.majorTicks; ++i) {
                        const frac = i / root.majorTicks
                        const y = ty + th - frac * th

                        // Tick
                        ctx.strokeStyle = root.scaleColor.toString()
                        ctx.lineWidth = 1.6
                        ctx.beginPath()
                        ctx.moveTo(tickStartX, y)
                        ctx.lineTo(tickStartX + majorTickLen, y)
                        ctx.stroke()

                        // Label
                        if (i % step === 0 || i === root.majorTicks) {
                            const val = root.minimum + frac * valRange
                            const text = NumberFormat.scaleLabelText(val, root.precision)
                            ctx.fillStyle = root.textColor.toString()
                            ctx.fillText(text, labelX, y)
                        }
                    }
                } else {
                    // Horizontal Scale
                    const tickStartY = ty + th + 6.0
                    const majorTickLen = Math.max(6.0, h * 0.12)
                    const minorTickLen = majorTickLen * 0.55
                    const labelY = tickStartY + majorTickLen + 7.0

                    // Minor Ticks
                    if (root.minorTicks > 0) {
                        ctx.strokeStyle = Qt.darker(root.scaleColor, 1.30).toString()
                        ctx.lineWidth = 1.0
                        for (let i = 0; i <= totalMinorDivisions; ++i) {
                            if (i % (root.minorTicks + 1) === 0) continue
                            const frac = i / totalMinorDivisions
                            const x = tx + frac * tw
                            ctx.beginPath()
                            ctx.moveTo(x, tickStartY)
                            ctx.lineTo(x, tickStartY + minorTickLen)
                            ctx.stroke()
                        }
                    }

                    // Major Ticks & Labels
                    const fontSize = Math.max(8, Math.min(11, Math.floor(h * 0.12)))
                    ctx.font = `bold ${fontSize}px sans-serif`
                    ctx.textAlign = "center"
                    ctx.textBaseline = "top"

                    const step = Math.max(1, Math.ceil((root.majorTicks + 1) * 32.0 / tw))

                    for (let i = 0; i <= root.majorTicks; ++i) {
                        const frac = i / root.majorTicks
                        const x = tx + frac * tw

                        // Major Tick
                        ctx.strokeStyle = root.scaleColor.toString()
                        ctx.lineWidth = 1.6
                        ctx.beginPath()
                        ctx.moveTo(x, tickStartY)
                        ctx.lineTo(x, tickStartY + majorTickLen)
                        ctx.stroke()

                        // Label
                        if (i % step === 0 || i === root.majorTicks) {
                            const val = root.minimum + frac * valRange
                            const text = NumberFormat.scaleLabelText(val, root.precision)
                            ctx.fillStyle = root.textColor.toString()
                            ctx.fillText(text, x, labelY)
                        }
                    }
                }
            }

            // 4. Digital Display Static Recessed Pod
            if (root.digitalDisplayVisible) {
                ctx.fillStyle = "rgba(16, 20, 26, 0.88)"
                ctx.strokeStyle = Qt.darker(root.bezelColor, 1.40).toString()
                ctx.lineWidth = 1.0
                drawRoundRect(ctx, root.podX, root.podY, root.podW, root.podH, 3.0)
                ctx.fill()
                ctx.stroke()
            }
        }

        function drawRoundRect(ctx, x, y, rw, rh, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + rw - r, y)
            ctx.arcTo(x + rw, y, x + rw, y + r, r)
            ctx.lineTo(x + rw, y + rh - r)
            ctx.arcTo(x + rw, y + rh, x + rw - r, y + rh, r)
            ctx.lineTo(x + r, y + rh)
            ctx.arcTo(x, y + rh, x, y + rh - r, r)
            ctx.lineTo(x, y + r)
            ctx.arcTo(x, y, x + r, y, r)
            ctx.closePath()
        }
    }

    // ========================================================================
    // 2. Dynamic Liquid Column & Specular Highlight Canvas
    // ========================================================================
    Canvas {
        id: dynamicCanvas
        anchors.fill: parent
        z: 1

        onPaint: {
            const ctx = getContext("2d")
            if (typeof ctx.reset === "function") {
                ctx.reset()
            }
            ctx.clearRect(0, 0, width, height)

            const tx = root.tubeX
            const ty = root.tubeY
            const tw = root.tubeW
            const th = root.tubeH
            const actColor = root.activeLiquidColor
            const f = root.factor

            // 1. Bulb Liquid Fill
            if (root.thermometerMode) {
                const bulbGrad = ctx.createRadialGradient(root.bulbCenterX, root.bulbCenterY, 0,
                                                          root.bulbCenterX, root.bulbCenterY, root.bulbRadius)
                bulbGrad.addColorStop(0.0, Qt.lighter(actColor, 1.30).toString())
                bulbGrad.addColorStop(0.7, actColor.toString())
                bulbGrad.addColorStop(1.0, Qt.darker(actColor, 1.30).toString())

                ctx.fillStyle = bulbGrad
                ctx.beginPath()
                ctx.arc(root.bulbCenterX, root.bulbCenterY, Math.max(1.0, root.bulbRadius - 1.0), 0, Math.PI * 2)
                ctx.fill()
            }

            // 2. Liquid Column Fill
            if (f > 0.0) {
                if (root.isVert) {
                    const fillHeight = th * f
                    const fillY = ty + th - fillHeight
                    const fillX = tx + 1.0
                    const fillW = tw - 2.0

                    let colGrad
                    if (root.gradientLiquid) {
                        colGrad = ctx.createLinearGradient(fillX, ty + th, fillX, ty)
                        colGrad.addColorStop(0.0, root.normalColor.toString())
                        colGrad.addColorStop(0.7, root.warningColor.toString())
                        colGrad.addColorStop(1.0, root.errorColor.toString())
                    } else {
                        colGrad = ctx.createLinearGradient(fillX, fillY, fillX + fillW, fillY)
                        colGrad.addColorStop(0.0, Qt.lighter(actColor, 1.25).toString())
                        colGrad.addColorStop(0.4, actColor.toString())
                        colGrad.addColorStop(1.0, Qt.darker(actColor, 1.20).toString())
                    }

                    ctx.fillStyle = colGrad
                    drawRoundRect(ctx, fillX, fillY, fillW, fillHeight, 2.0)
                    ctx.fill()
                } else {
                    const fillWidth = tw * f
                    const fillX = tx + 1.0
                    const fillY = ty + 1.0
                    const fillH = th - 2.0

                    let colGrad
                    if (root.gradientLiquid) {
                        colGrad = ctx.createLinearGradient(tx, fillY, tx + tw, fillY)
                        colGrad.addColorStop(0.0, root.normalColor.toString())
                        colGrad.addColorStop(0.7, root.warningColor.toString())
                        colGrad.addColorStop(1.0, root.errorColor.toString())
                    } else {
                        colGrad = ctx.createLinearGradient(fillX, fillY, fillX, fillY + fillH)
                        colGrad.addColorStop(0.0, Qt.lighter(actColor, 1.25).toString())
                        colGrad.addColorStop(0.4, actColor.toString())
                        colGrad.addColorStop(1.0, Qt.darker(actColor, 1.20).toString())
                    }

                    ctx.fillStyle = colGrad
                    drawRoundRect(ctx, fillX, fillY, fillWidth, fillH, 2.0)
                    ctx.fill()
                }
            }

            // 3. Specular Glass Highlight Reflection Line
            ctx.strokeStyle = "rgba(255, 255, 255, 0.40)"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            if (root.isVert) {
                ctx.moveTo(tx + 2.5, ty + 4.0)
                ctx.lineTo(tx + 2.5, ty + th - 2.0)
            } else {
                ctx.moveTo(tx + 4.0, ty + 2.5)
                ctx.lineTo(tx + tw - 2.0, ty + 2.5)
            }
            ctx.stroke()
        }

        function drawRoundRect(ctx, x, y, rw, rh, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + rw - r, y)
            ctx.arcTo(x + rw, y, x + rw, y + r, r)
            ctx.lineTo(x + rw, y + rh - r)
            ctx.arcTo(x + rw, y + rh, x + rw - r, y + rh, r)
            ctx.lineTo(x + r, y + rh)
            ctx.arcTo(x, y + rh, x, y + rh - r, r)
            ctx.lineTo(x, y + r)
            ctx.arcTo(x, y, x + r, y, r)
            ctx.closePath()
        }
    }

    // ========================================================================
    // 3. High-Contrast Digital Value Readout (Pod Text)
    // ========================================================================
    Text {
        id: podText
        z: 2
        visible: root.digitalDisplayVisible
        x: root.podX
        y: root.podY
        width: root.podW
        height: root.podH
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: root.isVert ? 12 : 11
        font.bold: true
        font.family: "monospace, sans-serif"
        color: root.activeLiquidColor

        text: NumberFormat.formatFixed(root.animatedValue, root.precision) + (root.unit.length > 0 ? " " + root.unit : "")
    }

    // ========================================================================
    // 4. Interactive Touch / Mouse Rotary Drag & Wheel
    // ========================================================================
    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: (mouse) => {
            if (pressed) {
                root.updateValueFromPos(mouse.x, mouse.y)
            }
        }

        onPressed: (mouse) => {
            root.updateValueFromPos(mouse.x, mouse.y)
        }

        onWheel: (wheel) => {
            const numSteps = wheel.angleDelta.y / 120.0
            const stepDelta = (root.maximum - root.minimum) * 0.02
            const delta = (numSteps !== 0 ? numSteps : (wheel.angleDelta.y > 0 ? 1 : -1)) * stepDelta
            root.value = Math.max(root.minimum, Math.min(root.maximum, root.value + delta))
        }
    }
}
