// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * \class Compass
 * \brief Heading indicator: a rotating compass card or a fixed card with a rotating needle.
 *
 * Full Qt Quick implementation matching QtIndustrialWidgets::Compass:
 * - Dual operating modes:
 *   - HeadingUp: Rotating compass card where vessel/aircraft heading is at 12 o'clock (lubber line).
 *   - NorthUp: Fixed compass rose with a rotating two-color magnetic needle (red North, slate South).
 * - Target Heading Bug: Adjustable course/autopilot heading index with interactive mouse drag and wheel.
 * - courseDeviation: Signed angular deviation of the heading from the target heading [-180, +180].
 * - 360° graduation marks with cardinal (N, E, S, W) and intercardinal (NE, SE, SW, NW) indices.
 * - 8-point nautical star compass rose watermark.
 * - 12 o'clock lubber reference marker.
 * - Central digital readout pod with 3-digit zero-padded heading (e.g. "045°").
 * - Value state handling: NaN/non-finite heading triggers Invalid state, "HDG" red failure flag, and "---°" readout.
 */
Item {
    id: root

    activeFocusOnTab: true

    enum DisplayMode {
        HeadingUp = 0,
        NorthUp = 1
    }

    enum ValueState {
        Valid = 0,
        Invalid = 3
    }

    // --- Core Heading & Mode Properties ---
    property real heading: 0.0
    property real targetHeading: 0.0
    property int displayMode: Compass.DisplayMode.HeadingUp
    property bool headingBugVisible: true
    property bool headingBugInteractive: true
    property bool lubberLineVisible: true
    property bool digitalReadoutVisible: true
    property int valueState: Compass.ValueState.Valid

    // --- Styling Colors ---
    property color dialColor: "#141820"       // Deep naval slate
    property color bezelColor: "#303846"      // Machined metallic rim
    property color textColor: "#e1e7ec"       // Card ticks and labels
    property color readoutColor: "#e1e7ec"    // Digital heading readout
    property color cardinalColor: "#00e5ff"   // Cyan highlights for E/S/W
    property color needleColor: "#eb3b5a"     // Vivid red North arrow
    property color needleTailColor: "#a0afc3" // Slate South arrow
    property color bugColor: "#fe8228"        // High-visibility orange bug
    property color lubberColor: "#fed330"     // Safety amber lubber line

    // --- Animation Options ---
    property bool animated: true
    property real animationVelocity: 360.0 // deg/s

    // --- Signals ---
    signal appearanceChanged()

    // --- Size Hint & Geometry ---
    implicitWidth: 260
    implicitHeight: 260
    width: implicitWidth
    height: implicitHeight

    // --- Status & Computed Properties ---
    readonly property bool isInvalid: valueState === Compass.ValueState.Invalid || isNaN(heading) || !isFinite(heading)
    readonly property real cardRotation: isInvalid ? 0.0 : heading

    readonly property real courseDeviation: {
        if (isInvalid) return NaN
        return (((heading - targetHeading + 540.0) % 360.0) + 360.0) % 360.0 - 180.0
    }

    // --- Continuous Heading for Shortest-Path Smooth Animation ---
    property real _continuousHeading: 0.0
    property real _targetContinuousHeading: 0.0

    function _updateTargetContinuousHeading() {
        const target = root.isInvalid ? 0.0 : root.heading
        if (!root.animated) {
            _targetContinuousHeading = target
            _continuousHeading = target
            return
        }
        const current = _continuousHeading
        const delta = (((target - (current % 360.0) + 540.0) % 360.0) + 360.0) % 360.0 - 180.0
        _targetContinuousHeading = current + delta
        _continuousHeading = _targetContinuousHeading
    }

    onHeadingChanged: {
        if (isNaN(heading) || !isFinite(heading)) {
            if (valueState !== Compass.ValueState.Invalid) {
                valueState = Compass.ValueState.Invalid
            }
        } else {
            const norm = normalizeDegrees(heading)
            if (Math.abs(heading - norm) > 0.0001) {
                heading = norm
                return
            }
            if (valueState !== Compass.ValueState.Valid) {
                valueState = Compass.ValueState.Valid
            }
        }
        _updateTargetContinuousHeading()
    }

    onTargetHeadingChanged: {
        if (!isNaN(targetHeading) && isFinite(targetHeading)) {
            const norm = normalizeDegrees(targetHeading)
            if (Math.abs(targetHeading - norm) > 0.0001) {
                targetHeading = norm
            }
        }
    }

    onIsInvalidChanged: _updateTargetContinuousHeading()
    onAnimatedChanged: _updateTargetContinuousHeading()

    Behavior on _continuousHeading {
        enabled: root.animated
        SmoothedAnimation {
            velocity: root.animationVelocity
            reversingMode: SmoothedAnimation.Immediate
        }
    }

    // --- API Functions ---
    function normalizeDegrees(deg) {
        if (isNaN(deg) || !isFinite(deg)) return 0.0
        var r = deg % 360.0
        if (r < 0.0) r += 360.0
        return r
    }

    function setHeading(val) {
        if (isNaN(val) || !isFinite(val)) {
            if (root.valueState === Compass.ValueState.Invalid) return
            root.heading = NaN
            root.valueState = Compass.ValueState.Invalid
            return
        }
        const norm = normalizeDegrees(val)
        const wasInvalid = (root.valueState === Compass.ValueState.Invalid)
        if (wasInvalid || Math.abs(root.heading - norm) > 0.001) {
            root.heading = norm
            root.valueState = Compass.ValueState.Valid
        }
    }

    function setTargetHeading(target) {
        if (isNaN(target) || !isFinite(target)) return
        const norm = normalizeDegrees(target)
        if (Math.abs(root.targetHeading - norm) > 0.001) {
            root.targetHeading = norm
        }
    }

    function setDisplayMode(mode) {
        if (root.displayMode !== mode) {
            root.displayMode = mode
        }
    }

    // --- Geometry Computations ---
    readonly property real side: Math.min(width, height)
    readonly property real cx: width * 0.5
    readonly property real cy: height * 0.5
    readonly property real radius: Math.max(5.0, (side * 0.5) - 6.0)

    readonly property real bugR: radius - 2.0
    readonly property real bugW: Math.min(18.0, Math.max(8.0, radius * 0.12))
    readonly property real bugH: Math.min(15.0, Math.max(6.0, radius * 0.10))

    readonly property real lubberR: radius + 2.0
    readonly property real lubberW: Math.min(14.0, Math.max(6.0, radius * 0.08))
    readonly property real lubberH: Math.min(18.0, Math.max(8.0, radius * 0.12))

    readonly property real needleLen: radius * 0.68
    readonly property real needleW: Math.min(16.0, Math.max(6.0, radius * 0.08))

    readonly property real podW: Math.min(110.0, Math.max(48.0, radius * 0.52))
    readonly property real podH: Math.min(50.0, Math.max(24.0, radius * 0.26))

    readonly property real flagW: Math.min(90.0, Math.max(34.0, radius * 0.42))
    readonly property real flagH: Math.min(30.0, Math.max(14.0, radius * 0.17))

    onWidthChanged: {
        bezelCanvas.requestPaint()
        cardCanvas.requestPaint()
    }
    onHeightChanged: {
        bezelCanvas.requestPaint()
        cardCanvas.requestPaint()
    }
    onBezelColorChanged: {
        bezelCanvas.requestPaint()
        appearanceChanged()
    }
    onDialColorChanged: {
        cardCanvas.requestPaint()
        appearanceChanged()
    }
    onTextColorChanged: {
        cardCanvas.requestPaint()
        appearanceChanged()
    }
    onCardinalColorChanged: {
        cardCanvas.requestPaint()
        appearanceChanged()
    }
    onNeedleColorChanged: {
        cardCanvas.requestPaint()
        appearanceChanged()
    }
    onNeedleTailColorChanged: appearanceChanged()
    onBugColorChanged: appearanceChanged()
    onLubberColorChanged: appearanceChanged()
    onReadoutColorChanged: appearanceChanged()
    onHeadingBugVisibleChanged: appearanceChanged()
    onHeadingBugInteractiveChanged: appearanceChanged()
    onLubberLineVisibleChanged: appearanceChanged()
    onDigitalReadoutVisibleChanged: appearanceChanged()

    Component.onCompleted: {
        _continuousHeading = root.isInvalid ? 0.0 : root.heading
        _targetContinuousHeading = _continuousHeading
    }

    // ========================================================================
    // LAYER 1: Static Outer Bezel Ring (Machined metal chamfer + inner groove)
    // ========================================================================
    Canvas {
        id: bezelCanvas
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

            // Outer machined bezel ring
            const bezelGrad = ctx.createRadialGradient(cx - r * 0.3, cy - r * 0.3, 0, cx, cy, r + 5.0)
            bezelGrad.addColorStop(0.0, Qt.lighter(root.bezelColor, 1.40).toString())
            bezelGrad.addColorStop(0.7, root.bezelColor.toString())
            bezelGrad.addColorStop(1.0, Qt.darker(root.bezelColor, 1.70).toString())

            ctx.beginPath()
            ctx.arc(cx, cy, r + 5.0, 0, 2 * Math.PI)
            ctx.fillStyle = bezelGrad
            ctx.fill()
            ctx.strokeStyle = Qt.darker(root.bezelColor, 2.0).toString()
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Bezel inner groove
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.strokeStyle = "#0f1219"
            ctx.lineWidth = 2.0
            ctx.stroke()
        }
    }

    // ========================================================================
    // LAYER 2: Compass Card Item (Dial face + Watermark + Ticks + Bug)
    // In HeadingUp: Rotates by -_continuousHeading around center
    // In NorthUp: Static (rotation = 0)
    // ========================================================================
    Item {
        id: cardContainer
        anchors.fill: parent
        z: 1
        rotation: (root.displayMode === Compass.DisplayMode.HeadingUp) ? -root._continuousHeading : 0.0
        transformOrigin: Item.Center

        Canvas {
            id: cardCanvas
            anchors.fill: parent

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

                // A. Dial Face Background
                const dialGrad = ctx.createRadialGradient(cx, cy - r * 0.25, 0, cx, cy, r)
                dialGrad.addColorStop(0.0, Qt.lighter(root.dialColor, 1.25).toString())
                dialGrad.addColorStop(0.8, root.dialColor.toString())
                dialGrad.addColorStop(1.0, Qt.darker(root.dialColor, 1.40).toString())

                ctx.beginPath()
                ctx.arc(cx, cy, r - 1.0, 0, 2 * Math.PI)
                ctx.fillStyle = dialGrad
                ctx.fill()

                // B. Central 8-Point Nautical Star Watermark
                const starRadius = r * 0.32
                for (let pt = 0; pt < 8; ++pt) {
                    ctx.save()
                    ctx.translate(cx, cy)
                    ctx.rotate(pt * 45.0 * Math.PI / 180.0)

                    const baseC = (pt % 2 === 0) ? root.cardinalColor : root.textColor

                    // Light half
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(0, -starRadius)
                    ctx.lineTo(starRadius * 0.25, -starRadius * 0.3)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(baseC.r, baseC.g, baseC.b, 38 / 255.0).toString()
                    ctx.fill()

                    // Dark half
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(0, -starRadius)
                    ctx.lineTo(-starRadius * 0.25, -starRadius * 0.3)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(baseC.r, baseC.g, baseC.b, 18 / 255.0).toString()
                    ctx.fill()

                    ctx.restore()
                }

                // C. Dial Graduation Scale & Tick Marks
                const outerTickR = r - 3.0
                const minorTickR = r - 3.0 - (r * 0.045)
                const medTickR   = r - 3.0 - (r * 0.08)
                const majorTickR = r - 3.0 - (r * 0.12)
                const textR      = r - 3.0 - (r * 0.22)

                const cardFontPt = Math.max(8.0, Math.min(22.0, r * 0.13))
                const interFontPt = Math.max(6.5, Math.min(14.0, r * 0.08))
                const numFontPt = Math.max(6.0, Math.min(12.0, r * 0.07))

                // Track circle lines
                ctx.beginPath()
                ctx.arc(cx, cy, outerTickR, 0, 2 * Math.PI)
                ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 60 / 255.0).toString()
                ctx.lineWidth = 1.0
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, majorTickR, 0, 2 * Math.PI)
                ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 60 / 255.0).toString()
                ctx.lineWidth = 1.0
                ctx.stroke()

                for (let deg = 0; deg < 360; deg += 5) {
                    ctx.save()
                    ctx.translate(cx, cy)
                    ctx.rotate(deg * Math.PI / 180.0)

                    // Tick lines
                    ctx.beginPath()
                    ctx.moveTo(0, -outerTickR)
                    if (deg % 30 === 0) {
                        ctx.lineTo(0, -majorTickR)
                        ctx.strokeStyle = root.textColor.toString()
                        ctx.lineWidth = 1.8
                    } else if (deg % 10 === 0) {
                        ctx.lineTo(0, -medTickR)
                        ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 180 / 255.0).toString()
                        ctx.lineWidth = 1.2
                    } else {
                        ctx.lineTo(0, -minorTickR)
                        ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 100 / 255.0).toString()
                        ctx.lineWidth = 0.8
                    }
                    ctx.stroke()

                    // Labels
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"

                    if (deg === 0) {
                        ctx.font = "bold " + Math.round(cardFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.needleColor.toString()
                        ctx.fillText("N", 0, -textR)
                    } else if (deg === 90) {
                        ctx.font = "bold " + Math.round(cardFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.cardinalColor.toString()
                        ctx.fillText("E", 0, -textR)
                    } else if (deg === 180) {
                        ctx.font = "bold " + Math.round(cardFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.cardinalColor.toString()
                        ctx.fillText("S", 0, -textR)
                    } else if (deg === 270) {
                        ctx.font = "bold " + Math.round(cardFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.cardinalColor.toString()
                        ctx.fillText("W", 0, -textR)
                    } else if (deg === 45) {
                        ctx.font = "bold " + Math.round(interFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.textColor.toString()
                        ctx.fillText("NE", 0, -textR)
                    } else if (deg === 135) {
                        ctx.font = "bold " + Math.round(interFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.textColor.toString()
                        ctx.fillText("SE", 0, -textR)
                    } else if (deg === 225) {
                        ctx.font = "bold " + Math.round(interFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.textColor.toString()
                        ctx.fillText("SW", 0, -textR)
                    } else if (deg === 315) {
                        ctx.font = "bold " + Math.round(interFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.textColor.toString()
                        ctx.fillText("NW", 0, -textR)
                    } else if (deg % 30 === 0) {
                        ctx.font = Math.round(numFontPt) + "pt sans-serif"
                        ctx.fillStyle = root.textColor.toString()
                        const strDeg = String(deg).padStart(3, '0')
                        ctx.fillText(strDeg, 0, -textR)
                    }

                    ctx.restore()
                }
            }
        }

        // --- Target Heading Bug Chevron (Rotates with the card to targetHeading) ---
        Item {
            id: bugItem
            anchors.centerIn: parent
            width: 0
            height: 0
            rotation: root.targetHeading
            visible: root.headingBugVisible

            Shape {
                anchors.centerIn: parent
                width: 0
                height: 0
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeColor: Qt.darker(root.bugColor, 1.4)
                    strokeWidth: 1.2
                    fillColor: root.bugColor

                    startX: -root.bugW
                    startY: -root.bugR
                    PathLine { x: -root.bugW * 0.6; y: -root.bugR + root.bugH }
                    PathLine { x: 0.0; y: -root.bugR + root.bugH * 0.4 }
                    PathLine { x: root.bugW * 0.6; y: -root.bugR + root.bugH }
                    PathLine { x: root.bugW; y: -root.bugR }
                    PathLine { x: 0.0; y: -root.bugR - 2.0 }
                    PathLine { x: -root.bugW; y: -root.bugR }
                }
            }
        }
    }

    // ========================================================================
    // LAYER 3: HeadingUp Invalid State Veil
    // In HeadingUp mode, an invalid heading veils the card and bug with dialColor
    // ========================================================================
    Rectangle {
        id: invalidVeil
        anchors.centerIn: parent
        width: (root.radius + 1.0) * 2.0
        height: width
        radius: width * 0.5
        color: Qt.rgba(root.dialColor.r, root.dialColor.g, root.dialColor.b, 0.67)
        visible: root.displayMode === Compass.DisplayMode.HeadingUp && root.isInvalid
        z: 2
    }

    // ========================================================================
    // LAYER 4: Rotating Two-Tone Magnetic Needle (NorthUp mode only)
    // Points to _continuousHeading (red North half, slate South half)
    // ========================================================================
    Item {
        id: needleItem
        anchors.centerIn: parent
        width: 0
        height: 0
        z: 3
        visible: root.displayMode === Compass.DisplayMode.NorthUp && !root.isInvalid
        rotation: root._continuousHeading

        Shape {
            anchors.centerIn: parent
            width: 0
            height: 0
            layer.enabled: true
            layer.samples: 4

            // North Half Light
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.needleColor

                startX: 0.0
                startY: 0.0
                PathLine { x: 0.0; y: -root.needleLen }
                PathLine { x: root.needleW * 0.5; y: -root.needleLen * 0.2 }
                PathLine { x: 0.0; y: 0.0 }
            }

            // North Half Dark
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.darker(root.needleColor, 1.4)

                startX: 0.0
                startY: 0.0
                PathLine { x: 0.0; y: -root.needleLen }
                PathLine { x: -root.needleW * 0.5; y: -root.needleLen * 0.2 }
                PathLine { x: 0.0; y: 0.0 }
            }

            // South Half Light
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.needleTailColor

                startX: 0.0
                startY: 0.0
                PathLine { x: 0.0; y: root.needleLen * 0.85 }
                PathLine { x: root.needleW * 0.5; y: root.needleLen * 0.2 }
                PathLine { x: 0.0; y: 0.0 }
            }

            // South Half Dark
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.darker(root.needleTailColor, 1.4)

                startX: 0.0
                startY: 0.0
                PathLine { x: 0.0; y: root.needleLen * 0.85 }
                PathLine { x: -root.needleW * 0.5; y: root.needleLen * 0.2 }
                PathLine { x: 0.0; y: 0.0 }
            }
        }

        // Center needle pivot cap
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(6.0, root.needleW * 0.9)
            height: width
            radius: width * 0.5
            color: "#273142"
            border.color: "#718093"
            border.width: 1.5
        }
    }

    // ========================================================================
    // LAYER 5: Static 12 o'clock Lubber Reference Line
    // ========================================================================
    Item {
        id: lubberItem
        anchors.centerIn: parent
        width: 0
        height: 0
        z: 4
        visible: root.lubberLineVisible && (root.displayMode === Compass.DisplayMode.NorthUp || !root.isInvalid)

        Shape {
            anchors.centerIn: parent
            width: 0
            height: 0
            layer.enabled: true
            layer.samples: 4

            // Top Triangle pointer
            ShapePath {
                strokeColor: "#141414"
                strokeWidth: 1.0
                fillColor: root.lubberColor

                startX: 0.0
                startY: -root.lubberR + root.lubberH
                PathLine { x: -root.lubberW * 0.5; y: -root.lubberR }
                PathLine { x: root.lubberW * 0.5; y: -root.lubberR }
                PathLine { x: 0.0; y: -root.lubberR + root.lubberH }
            }

            // Vertical guide line
            ShapePath {
                strokeColor: root.lubberColor
                strokeWidth: 2.0
                fillColor: "transparent"

                startX: 0.0
                startY: -root.lubberR
                PathLine { x: 0.0; y: -root.lubberR + root.radius * 0.16 }
            }
        }
    }

    // ========================================================================
    // LAYER 6: Central Digital Readout Pod
    // Recessed dark bezel displaying 3-digit padded heading (e.g. "045°")
    // ========================================================================
    Rectangle {
        id: readoutPod
        anchors.centerIn: parent
        width: root.podW
        height: root.podH
        radius: 4
        z: 5
        visible: root.digitalReadoutVisible

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0e1218" }
            GradientStop { position: 1.0; color: "#181e28" }
        }

        border.color: Qt.darker(root.bezelColor, 1.5)
        border.width: 1.5

        Text {
            anchors.centerIn: parent
            font.bold: true
            font.pixelSize: Math.max(8, Math.floor(root.podH * 0.48))
            color: root.readoutColor
            text: {
                if (root.isInvalid) return "---°"
                var intHdg = Math.round(root.heading) % 360
                if (intHdg < 0) intHdg += 360
                return String(intHdg).padStart(3, '0') + "°"
            }
        }
    }

    // ========================================================================
    // LAYER 7: HDG Failure Flag
    // Red flag displayed above readout pod on invalid heading (NaN / ±Inf)
    // ========================================================================
    Rectangle {
        id: failureFlag
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy - root.radius * 0.45 - (root.flagH * 0.5)
        width: root.flagW
        height: root.flagH
        radius: 2
        z: 6
        visible: root.isInvalid
        color: "#e11d2e"
        border.color: "#141414"
        border.width: 1.0

        Text {
            anchors.centerIn: parent
            text: "HDG"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: Math.max(7, Math.floor(root.flagH * 0.6))
        }
    }

    // ========================================================================
    // LAYER 8: Interactive Heading Bug Drag & Wheel Controller
    // ========================================================================
    MouseArea {
        id: dragArea
        anchors.fill: parent
        z: 7
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        property bool isDragging: false

        function angleFromPos(px, py) {
            const dx = px - root.cx
            const dy = py - root.cy
            const rad = Math.atan2(dx, -dy)
            const deg = rad * 180.0 / Math.PI
            return root.normalizeDegrees(deg)
        }

        function isOverBugRing(px, py) {
            const dist = Math.hypot(px - root.cx, py - root.cy)
            return dist > root.radius * 0.35 && dist <= root.radius * 1.15
        }

        cursorShape: (root.headingBugInteractive && isOverBugRing(mouseX, mouseY)) ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: (mouse) => {
            if (!root.headingBugInteractive) {
                mouse.accepted = false
                return
            }
            if (isOverBugRing(mouse.x, mouse.y)) {
                isDragging = true
                root.forceActiveFocus()
                const angle = angleFromPos(mouse.x, mouse.y)
                if (root.displayMode === Compass.DisplayMode.HeadingUp) {
                    const currentCardAngle = root.animated ? (((root._continuousHeading % 360.0) + 360.0) % 360.0) : root.cardRotation
                    root.setTargetHeading(root.normalizeDegrees(angle + currentCardAngle))
                } else {
                    root.setTargetHeading(angle)
                }
            } else {
                mouse.accepted = false
            }
        }

        onPositionChanged: (mouse) => {
            if (isDragging) {
                const angle = angleFromPos(mouse.x, mouse.y)
                if (root.displayMode === Compass.DisplayMode.HeadingUp) {
                    const currentCardAngle = root.animated ? (((root._continuousHeading % 360.0) + 360.0) % 360.0) : root.cardRotation
                    root.setTargetHeading(root.normalizeDegrees(angle + currentCardAngle))
                } else {
                    root.setTargetHeading(angle)
                }
            }
        }

        onReleased: (mouse) => {
            isDragging = false
        }

        onCanceled: {
            isDragging = false
        }

        onWheel: (wheel) => {
            if (!root.headingBugInteractive) {
                wheel.accepted = false
                return
            }
            const step = (wheel.modifiers & Qt.ShiftModifier) ? 5.0 : 1.0
            const delta = wheel.angleDelta.y > 0 ? step : -step
            root.setTargetHeading(root.targetHeading + delta)
            wheel.accepted = true
        }
    }

    // Keyboard navigation when focused
    Keys.onLeftPressed: (event) => {
        if (headingBugInteractive) {
            setTargetHeading(targetHeading - 1.0)
            event.accepted = true
        }
    }
    Keys.onRightPressed: (event) => {
        if (headingBugInteractive) {
            setTargetHeading(targetHeading + 1.0)
            event.accepted = true
        }
    }
    Keys.onUpPressed: (event) => {
        if (headingBugInteractive) {
            setTargetHeading(targetHeading + 1.0)
            event.accepted = true
        }
    }
    Keys.onDownPressed: (event) => {
        if (headingBugInteractive) {
            setTargetHeading(targetHeading - 1.0)
            event.accepted = true
        }
    }
    Keys.onPressed: (event) => {
        if (!headingBugInteractive) return
        if (event.key === Qt.Key_PageUp) {
            setTargetHeading(targetHeading + 10.0)
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            setTargetHeading(targetHeading - 10.0)
            event.accepted = true
        }
    }
}
