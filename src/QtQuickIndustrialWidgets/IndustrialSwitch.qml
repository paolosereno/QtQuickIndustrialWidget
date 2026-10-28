// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * \class IndustrialSwitch
 * \brief High-performance toggle lever and rocker switch with flip-up safety guard in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::IndustrialSwitch:
 * - Bat-handle toggle lever or curved rocker switch styles
 * - 2-position (OFF/ON) or 3-position (OFF/AUTO/ON) selector modes
 * - Optional industrial crimson flip-up safety guard with hazard stripes and viewing window
 * - Integrated pilot status LED with realistic lens refraction and halo glow
 * - Brushed dark metal faceplate with chamfered border and 4 corner screws
 * - Animated throw and guard transitions (Easing.OutBack and Easing.OutCubic)
 * - Interactive mouse clicks, dragging, wheel, and keyboard navigation
 */
Item {
    id: root

    activeFocusOnTab: true

    enum SwitchType {
        ToggleLever = 0,
        Rocker = 1
    }

    enum Orientation {
        Vertical = 1,
        Horizontal = 2
    }

    // --- Configuration Properties ---
    property int switchType: IndustrialSwitch.SwitchType.ToggleLever
    property int positionCount: 2
    property int position: 0
    property bool checked: position === (positionCount - 1)
    property int orientation: IndustrialSwitch.Orientation.Vertical
    property bool hasSafetyGuard: false
    property bool isGuardOpen: false
    property bool animated: true
    property bool hasLed: true

    // --- Text Labels ---
    property string label: ""
    property string labelOff: "OFF"
    property string labelOn: "ON"
    property string labelCenter: "AUTO"

    // --- Colors (Matching QtIndustrialWidgets palette) ---
    property color plateColor: "#2a2d34"
    property color leverColor: "#dce1e6"
    property color ledColor: "#2ecc71"
    property color textColor: "#c8cdd7"
    property color guardColor: "#dc3545"

    // --- Signals ---
    signal toggled(bool checked)
    signal guardToggled(bool isOpen)
    signal appearanceChanged()

    // --- Size Hints ---
    implicitWidth: (orientation === IndustrialSwitch.Orientation.Vertical) ? 75 : 125
    implicitHeight: (orientation === IndustrialSwitch.Orientation.Vertical) ? 125 : 75
    width: implicitWidth
    height: implicitHeight

    // --- Position & Guard Animations ---
    property real currentPos: position
    Behavior on currentPos {
        enabled: root.animated && !mouseArea.dragActive
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutBack
        }
    }

    property real guardOpenFactor: isGuardOpen ? 1.0 : 0.0
    Behavior on guardOpenFactor {
        enabled: root.animated
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Synchronize external changes
    onPositionChanged: {
        const isNowChecked = (position === (positionCount - 1))
        if (root.checked !== isNowChecked) {
            root.checked = isNowChecked
        }
    }

    onCheckedChanged: {
        const target = checked ? (positionCount - 1) : 0
        if (position !== target) {
            setPosition(target)
        }
    }

    onIsGuardOpenChanged: {
        guardToggled(isGuardOpen)
    }

    // Request dynamic repaint on animation steps
    onCurrentPosChanged: dynamicCanvas.requestPaint()
    onGuardOpenFactorChanged: dynamicCanvas.requestPaint()

    // Request static background repaint on layout/visual property changes
    onWidthChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }
    onHeightChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint() }
    onOrientationChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onSwitchTypeChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onPositionCountChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onHasSafetyGuardChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onHasLedChanged: { staticBgCanvas.requestPaint(); dynamicCanvas.requestPaint(); appearanceChanged() }
    onLabelChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onLabelOffChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onLabelOnChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onLabelCenterChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onPlateColorChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onLeverColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onLedColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }
    onTextColorChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onGuardColorChanged: { dynamicCanvas.requestPaint(); appearanceChanged() }

    // --- API Methods ---
    function setPosition(newPos) {
        const clamped = Math.max(0, Math.min(positionCount - 1, newPos))
        if (position === clamped) return
        position = clamped
        toggled(checked)
    }

    function setChecked(check) {
        setPosition(check ? (positionCount - 1) : 0)
    }

    function toggle() {
        if (positionCount === 2) {
            setPosition(position === 0 ? 1 : 0)
        } else {
            const next = (position + 1) % positionCount
            setPosition(next)
        }
    }

    function setGuardOpen(open) {
        if (isGuardOpen === open) return
        isGuardOpen = open
    }

    // --- Geometry & Layout Engine ---
    readonly property var layout: {
        const w = width
        const h = height
        const isVert = (orientation === IndustrialSwitch.Orientation.Vertical)

        const plate = {
            x: 3,
            y: 3,
            width: Math.max(0, w - 6),
            height: Math.max(0, h - 6)
        }

        const r = {
            x: 10,
            y: 10,
            width: Math.max(0, w - 20),
            height: Math.max(0, h - 20)
        }

        let naturalX = 0, naturalY = 0, naturalW = 0, naturalH = 0
        if (isVert) {
            const sh = r.height * 0.55
            const sw = Math.min(r.width * 0.7, sh * 0.65)
            naturalW = sw
            naturalH = sh
            naturalX = r.x + (r.width - sw) * 0.5
            naturalY = r.y + (r.height - sh) * 0.52
        } else {
            const sw = r.width * 0.55
            const sh = Math.min(r.height * 0.7, sw * 0.65)
            naturalW = sw
            naturalH = sh
            naturalX = r.x + (r.width - sw) * 0.52
            naturalY = r.y + (r.height - sh) * 0.5
        }

        const switchRect = {
            x: naturalX,
            y: naturalY,
            width: naturalW,
            height: naturalH,
            cx: naturalX + naturalW * 0.5,
            cy: naturalY + naturalH * 0.5
        }

        const guard = hasSafetyGuard ? {
            x: switchRect.x - 8,
            y: switchRect.y - 12,
            width: switchRect.width + 16,
            height: switchRect.height + 24
        } : switchRect

        const guardOuter = hasSafetyGuard ? {
            x: guard.x - 4,
            y: guard.y - 2,
            width: guard.width + 8,
            height: guard.height + 8
        } : switchRect

        let openGuard = { x: 0, y: 0, width: 0, height: 0 }
        if (isVert) {
            const space = guard.x - (plate.x + 2.0)
            const t = Math.max(3.0, Math.min(0.17 * guard.width, Math.max(3.0, space)))
            openGuard = { x: Math.max(plate.x + 2.0, guard.x - t), y: guard.y, width: t, height: guard.height }
        } else {
            const top = guard.y + guard.height + 2.0
            const space = (plate.y + plate.height) - 2.0 - top
            const t = Math.max(3.0, Math.min(0.17 * guard.height, Math.max(3.0, space)))
            openGuard = { x: guard.x, y: top, width: guard.width, height: t }
        }

        let titleRect = { x: 0, y: 0, width: 0, height: 0 }
        let onRect = { x: 0, y: 0, width: 0, height: 0 }
        let offRect = { x: 0, y: 0, width: 0, height: 0 }
        let centerRect = { x: 0, y: 0, width: 0, height: 0 }
        let ledPos = { x: 0, y: 0 }

        if (isVert) {
            titleRect = { x: plate.x, y: plate.y + 6, width: plate.width, height: 16 }
            onRect = { x: plate.x, y: guardOuter.y - 16, width: plate.width, height: 14 }
            offRect = { x: plate.x, y: guardOuter.y + guardOuter.height + 3, width: plate.width, height: 14 }
            centerRect = { x: guardOuter.x + guardOuter.width + 4, y: switchRect.cy - 7, width: Math.max(10, (plate.x + plate.width) - (guardOuter.x + guardOuter.width) - 6), height: 14 }
            ledPos = { x: plate.x + plate.width * 0.5 - 24, y: onRect.y + onRect.height * 0.5 }
        } else {
            titleRect = { x: plate.x + 6, y: plate.y + 6, width: plate.width - 12, height: 14 }
            offRect = { x: plate.x + 4, y: switchRect.y, width: Math.max(10, guardOuter.x - plate.x - 6), height: switchRect.height }
            onRect = { x: guardOuter.x + guardOuter.width + 6, y: switchRect.y, width: Math.max(10, (plate.x + plate.width) - (guardOuter.x + guardOuter.width) - 8), height: switchRect.height }
            centerRect = { x: switchRect.cx - 24, y: guardOuter.y + guardOuter.height + 2, width: 48, height: 14 }
            ledPos = { x: onRect.x + onRect.width * 0.5, y: onRect.y - 8 }
        }

        return {
            plate: plate,
            switchRect: switchRect,
            guard: guard,
            guardOuter: guardOuter,
            openGuard: openGuard,
            titleRect: titleRect,
            onRect: onRect,
            offRect: offRect,
            centerRect: centerRect,
            led: ledPos
        }
    }

    // Helper: Rounded Rectangle
    function drawRoundedRect(ctx, x, y, w, h, r) {
        if (w <= 0 || h <= 0) return
        r = Math.min(r, Math.min(w * 0.5, h * 0.5))
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.lineTo(x + w - r, y)
        ctx.arcTo(x + w, y, x + w, y + r, r)
        ctx.lineTo(x + w, y + h - r)
        ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
        ctx.lineTo(x + r, y + h)
        ctx.arcTo(x, y + h, x, y + h - r, r)
        ctx.lineTo(x, y + r)
        ctx.arcTo(x, y, x + r, y, r)
        ctx.closePath()
    }

    // Helper: Corner Screw
    function drawScrew(ctx, cx, cy, radius) {
        ctx.save()
        const grad = ctx.createRadialGradient(cx - radius * 0.3, cy - radius * 0.3, 0, cx, cy, radius)
        grad.addColorStop(0.0, "rgb(220, 222, 225)")
        grad.addColorStop(0.7, "rgb(130, 135, 140)")
        grad.addColorStop(1.0, "rgb(60, 65, 70)")
        ctx.fillStyle = grad
        ctx.beginPath()
        ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
        ctx.fill()

        ctx.strokeStyle = "rgba(30, 32, 35, 0.7)"
        ctx.lineWidth = 0.7
        ctx.stroke()

        ctx.strokeStyle = "rgba(40, 42, 45, 0.9)"
        ctx.lineWidth = Math.max(1.0, radius * 0.35)
        ctx.lineCap = "round"
        ctx.beginPath()
        ctx.moveTo(cx - radius * 0.6, cy)
        ctx.lineTo(cx + radius * 0.6, cy)
        ctx.moveTo(cx, cy - radius * 0.6)
        ctx.lineTo(cx, cy + radius * 0.6)
        ctx.stroke()
        ctx.restore()
    }

    // --- 1. Static Background Canvas ---
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

            const l = root.layout
            const p = l.plate
            const r = 6.0

            // Drop shadow
            ctx.fillStyle = "rgba(15, 15, 18, 0.63)"
            root.drawRoundedRect(ctx, p.x + 1.5, p.y + 2.0, p.width, p.height, r)
            ctx.fill()

            // Plate Body (Brushed dark metal)
            const plateGrad = ctx.createLinearGradient(p.x, p.y, p.x + p.width, p.y + p.height)
            plateGrad.addColorStop(0.0, Qt.lighter(root.plateColor, 1.2).toString())
            plateGrad.addColorStop(0.5, root.plateColor.toString())
            plateGrad.addColorStop(1.0, Qt.darker(root.plateColor, 1.3).toString())
            root.drawRoundedRect(ctx, p.x, p.y, p.width, p.height, r)
            ctx.fillStyle = plateGrad
            ctx.fill()

            // Plate Chamfer / Bevel Border
            const borderGrad = ctx.createLinearGradient(p.x, p.y, p.x, p.y + p.height)
            borderGrad.addColorStop(0.0, "rgba(180, 185, 195, 0.7)")
            borderGrad.addColorStop(0.5, "rgba(90, 95, 105, 0.6)")
            borderGrad.addColorStop(1.0, "rgba(40, 42, 48, 0.78)")
            ctx.strokeStyle = borderGrad
            ctx.lineWidth = 1.5
            ctx.stroke()

            // 4 Corner Screws
            const screwRadius = Math.max(3.0, Math.min(5.0, Math.min(width, height) * 0.04))
            const screwMargin = screwRadius * 2.2
            root.drawScrew(ctx, p.x + screwMargin, p.y + screwMargin, screwRadius)
            root.drawScrew(ctx, p.x + p.width - screwMargin, p.y + screwMargin, screwRadius)
            root.drawScrew(ctx, p.x + screwMargin, p.y + p.height - screwMargin, screwRadius)
            root.drawScrew(ctx, p.x + p.width - screwMargin, p.y + p.height - screwMargin, screwRadius)

            // Title Label
            if (root.label.length > 0) {
                const titleFontPx = Math.max(8, Math.floor(Math.min(width, height) * 0.09))
                ctx.font = "bold " + titleFontPx + "px sans-serif"
                ctx.fillStyle = root.textColor.toString()
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(root.label, l.titleRect.x + l.titleRect.width * 0.5, l.titleRect.y + l.titleRect.height * 0.5)
            }

            // Position Labels
            const labelFontPx = Math.max(7, Math.floor(Math.min(width, height) * 0.08))
            ctx.font = "bold " + labelFontPx + "px sans-serif"

            if (root.orientation === IndustrialSwitch.Orientation.Vertical) {
                // ON label
                ctx.fillStyle = Qt.lighter(root.textColor, 1.1).toString()
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                const onX = l.onRect.x + l.onRect.width * 0.5 + (root.hasLed ? 4 : 0)
                ctx.fillText(root.labelOn, onX, l.onRect.y + l.onRect.height * 0.5)

                // OFF label
                ctx.fillStyle = Qt.darker(root.textColor, 1.1).toString()
                ctx.fillText(root.labelOff, l.offRect.x + l.offRect.width * 0.5, l.offRect.y + l.offRect.height * 0.5)

                // Center label (3-pos)
                if (root.positionCount === 3) {
                    ctx.fillStyle = root.textColor.toString()
                    ctx.textAlign = "left"
                    ctx.fillText(root.labelCenter, l.centerRect.x, l.centerRect.y + l.centerRect.height * 0.5)
                }
            } else {
                // Horizontal labels
                ctx.textBaseline = "middle"
                // OFF label (left)
                ctx.fillStyle = Qt.darker(root.textColor, 1.1).toString()
                ctx.textAlign = "right"
                ctx.fillText(root.labelOff, l.offRect.x + l.offRect.width, l.offRect.y + l.offRect.height * 0.5)

                // ON label (right)
                ctx.fillStyle = Qt.lighter(root.textColor, 1.1).toString()
                ctx.textAlign = "left"
                ctx.fillText(root.labelOn, l.onRect.x, l.onRect.y + l.onRect.height * 0.5)

                // Center label (below)
                if (root.positionCount === 3) {
                    ctx.fillStyle = root.textColor.toString()
                    ctx.textAlign = "center"
                    ctx.fillText(root.labelCenter, l.centerRect.x + l.centerRect.width * 0.5, l.centerRect.y + l.centerRect.height * 0.5)
                }
            }

            // Switch Socket Base
            const sr = l.switchRect
            if (root.switchType === IndustrialSwitch.SwitchType.ToggleLever) {
                const scx = sr.cx
                const scy = sr.cy
                const socketRadius = Math.min(sr.width, sr.height) * 0.44

                // Dark cavity
                ctx.fillStyle = "rgb(18, 20, 22)"
                ctx.beginPath()
                ctx.arc(scx, scy, socketRadius, 0, 2 * Math.PI)
                ctx.fill()

                // Metallic collar ring
                const collarGrad = ctx.createRadialGradient(scx - socketRadius * 0.3, scy - socketRadius * 0.3, 0, scx, scy, socketRadius * 1.1)
                collarGrad.addColorStop(0.0, "rgb(240, 245, 250)")
                collarGrad.addColorStop(0.4, "rgb(160, 165, 172)")
                collarGrad.addColorStop(0.7, "rgb(80, 85, 92)")
                collarGrad.addColorStop(1.0, "rgb(40, 42, 45)")
                ctx.fillStyle = collarGrad
                ctx.beginPath()
                ctx.arc(scx, scy, socketRadius * 0.9, 0, 2 * Math.PI)
                ctx.fill()
                ctx.strokeStyle = "rgb(30, 32, 35)"
                ctx.lineWidth = 1.2
                ctx.stroke()

                // Inner pivot well
                const wellGrad = ctx.createRadialGradient(scx, scy, 0, scx, scy, socketRadius * 0.6)
                wellGrad.addColorStop(0.0, "rgb(25, 25, 28)")
                wellGrad.addColorStop(0.8, "rgb(45, 48, 52)")
                wellGrad.addColorStop(1.0, "rgb(15, 15, 18)")
                ctx.fillStyle = wellGrad
                ctx.beginPath()
                ctx.arc(scx, scy, socketRadius * 0.55, 0, 2 * Math.PI)
                ctx.fill()
            } else {
                // Rocker switch recessed rectangular bezel
                root.drawRoundedRect(ctx, sr.x, sr.y, sr.width, sr.height, 4.0)
                ctx.fillStyle = "rgb(22, 23, 26)"
                ctx.fill()
                ctx.strokeStyle = "rgb(25, 26, 30)"
                ctx.lineWidth = 1.5
                ctx.stroke()

                root.drawRoundedRect(ctx, sr.x + 1, sr.y + 1, sr.width - 2, sr.height - 2, 3.0)
                ctx.strokeStyle = "rgba(100, 105, 115, 0.55)"
                ctx.lineWidth = 1.0
                ctx.stroke()
            }
        }
    }

    // --- 2. Dynamic Canvas (Actuator, LED, Safety Guard) ---
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

            const l = root.layout
            const sr = l.switchRect

            // 1. Draw Actuator Mechanism
            if (root.switchType === IndustrialSwitch.SwitchType.ToggleLever) {
                drawToggleLever(ctx, sr, root.currentPos)
            } else {
                drawRocker(ctx, sr, root.currentPos)
            }

            // 2. Draw Status Pilot LED
            if (root.hasLed) {
                drawPilotLed(ctx, l.led.x, l.led.y, 4.5, root.checked)
            }

            // 3. Draw Flip-up Safety Guard (if equipped)
            if (root.hasSafetyGuard) {
                drawSafetyGuard(ctx, l)
            }
        }

        // Draw Bat Handle Toggle Lever
        function drawToggleLever(ctx, switchArea, currentPos) {
            ctx.save()

            const pivotX = switchArea.cx
            const pivotY = switchArea.cy
            const length = Math.min(switchArea.width, switchArea.height) * 0.72
            const thickness = length * 0.28

            const normPos = (root.positionCount === 2) ? currentPos : (currentPos * 0.5)
            const angleDeg = -32.0 + normPos * 64.0

            ctx.translate(pivotX, pivotY)

            if (root.orientation === IndustrialSwitch.Orientation.Vertical) {
                ctx.rotate(angleDeg * Math.PI / 180.0)

                // Drop shadow
                ctx.save()
                ctx.translate(3.0, 4.0)
                ctx.fillStyle = "rgba(10, 12, 15, 0.51)"
                root.drawRoundedRect(ctx, -thickness * 0.45, -length, thickness * 0.9, length, thickness * 0.45)
                ctx.fill()
                ctx.beginPath()
                ctx.arc(0, -length, thickness * 0.65, 0, 2 * Math.PI)
                ctx.fill()
                ctx.restore()

                // Bat lever shaft (cylindrical brushed metallic gradient)
                const shaftGrad = ctx.createLinearGradient(-thickness * 0.4, 0, thickness * 0.4, 0)
                shaftGrad.addColorStop(0.0, Qt.darker(root.leverColor, 1.7).toString())
                shaftGrad.addColorStop(0.3, Qt.lighter(root.leverColor, 1.3).toString())
                shaftGrad.addColorStop(0.55, "rgba(255, 255, 255, 0.94)")
                shaftGrad.addColorStop(0.75, root.leverColor.toString())
                shaftGrad.addColorStop(1.0, Qt.darker(root.leverColor, 2.0).toString())

                root.drawRoundedRect(ctx, -thickness * 0.4, -length, thickness * 0.8, length, thickness * 0.3)
                ctx.fillStyle = shaftGrad
                ctx.fill()
                ctx.strokeStyle = "rgba(60, 65, 70, 0.8)"
                ctx.lineWidth = 0.8
                ctx.stroke()

                // Spherical knob tip
                const tipRadius = thickness * 0.62
                const tipGrad = ctx.createRadialGradient(-tipRadius * 0.3, -length - tipRadius * 0.3, 0, 0, -length, tipRadius * 1.3)
                tipGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.98)")
                tipGrad.addColorStop(0.25, Qt.lighter(root.leverColor, 1.2).toString())
                tipGrad.addColorStop(0.65, root.leverColor.toString())
                tipGrad.addColorStop(0.9, Qt.darker(root.leverColor, 1.6).toString())
                tipGrad.addColorStop(1.0, Qt.darker(root.leverColor, 2.2).toString())

                ctx.fillStyle = tipGrad
                ctx.beginPath()
                ctx.arc(0, -length, tipRadius, 0, 2 * Math.PI)
                ctx.fill()
                ctx.strokeStyle = "rgba(50, 55, 60, 0.8)"
                ctx.lineWidth = 0.8
                ctx.stroke()

                // Chrome hemisphere hub at pivot
                const hubGrad = ctx.createRadialGradient(-thickness * 0.2, -thickness * 0.2, 0, 0, 0, thickness * 0.8)
                hubGrad.addColorStop(0.0, "rgb(250, 252, 255)")
                hubGrad.addColorStop(0.4, root.leverColor.toString())
                hubGrad.addColorStop(0.85, Qt.darker(root.leverColor, 1.8).toString())
                hubGrad.addColorStop(1.0, "rgb(35, 38, 42)")
                ctx.fillStyle = hubGrad
                ctx.beginPath()
                ctx.arc(0, 0, thickness * 0.55, 0, 2 * Math.PI)
                ctx.fill()
            } else {
                // Horizontal orientation
                ctx.rotate((angleDeg + 90.0) * Math.PI / 180.0)

                const shaftGrad = ctx.createLinearGradient(-thickness * 0.4, 0, thickness * 0.4, 0)
                shaftGrad.addColorStop(0.0, Qt.darker(root.leverColor, 1.7).toString())
                shaftGrad.addColorStop(0.3, Qt.lighter(root.leverColor, 1.3).toString())
                shaftGrad.addColorStop(0.55, "rgba(255, 255, 255, 0.94)")
                shaftGrad.addColorStop(0.75, root.leverColor.toString())
                shaftGrad.addColorStop(1.0, Qt.darker(root.leverColor, 2.0).toString())

                root.drawRoundedRect(ctx, -thickness * 0.4, -length, thickness * 0.8, length, thickness * 0.3)
                ctx.fillStyle = shaftGrad
                ctx.fill()
                ctx.strokeStyle = "rgba(60, 65, 70, 0.8)"
                ctx.lineWidth = 0.8
                ctx.stroke()

                const tipRadius = thickness * 0.62
                const tipGrad = ctx.createRadialGradient(-tipRadius * 0.3, -length - tipRadius * 0.3, 0, 0, -length, tipRadius * 1.3)
                tipGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.98)")
                tipGrad.addColorStop(0.25, Qt.lighter(root.leverColor, 1.2).toString())
                tipGrad.addColorStop(0.65, root.leverColor.toString())
                tipGrad.addColorStop(0.9, Qt.darker(root.leverColor, 1.6).toString())
                tipGrad.addColorStop(1.0, Qt.darker(root.leverColor, 2.2).toString())

                ctx.fillStyle = tipGrad
                ctx.beginPath()
                ctx.arc(0, -length, tipRadius, 0, 2 * Math.PI)
                ctx.fill()
            }

            ctx.restore()
        }

        // Draw Rocker Switch
        function drawRocker(ctx, switchArea, currentPos) {
            ctx.save()
            const p = {
                x: switchArea.x + 2,
                y: switchArea.y + 2,
                width: switchArea.width - 4,
                height: switchArea.height - 4
            }

            const normPos = (root.positionCount === 2) ? currentPos : (currentPos * 0.5)
            const tilt = (normPos - 0.5) * 2.0

            if (root.orientation === IndustrialSwitch.Orientation.Vertical) {
                const halfH = p.height * 0.5
                const topHalf = { x: p.x, y: p.y, width: p.width, height: halfH }
                const botHalf = { x: p.x, y: p.y + halfH, width: p.width, height: halfH }

                // Top paddle
                const topGrad = ctx.createLinearGradient(topHalf.x, topHalf.y, topHalf.x, topHalf.y + topHalf.height)
                if (tilt > 0) {
                    topGrad.addColorStop(0.0, "rgb(35, 37, 42)")
                    topGrad.addColorStop(1.0, "rgb(50, 53, 60)")
                } else {
                    topGrad.addColorStop(0.0, "rgb(80, 85, 95)")
                    topGrad.addColorStop(0.8, "rgb(60, 64, 72)")
                    topGrad.addColorStop(1.0, "rgb(48, 51, 58)")
                }
                root.drawRoundedRect(ctx, topHalf.x, topHalf.y, topHalf.width, topHalf.height, 3.0)
                ctx.fillStyle = topGrad
                ctx.fill()

                // Bottom paddle
                const botGrad = ctx.createLinearGradient(botHalf.x, botHalf.y, botHalf.x, botHalf.y + botHalf.height)
                if (tilt < 0) {
                    botGrad.addColorStop(0.0, "rgb(50, 53, 60)")
                    botGrad.addColorStop(1.0, "rgb(35, 37, 42)")
                } else {
                    botGrad.addColorStop(0.0, "rgb(52, 56, 64)")
                    botGrad.addColorStop(0.3, "rgb(75, 80, 90)")
                    botGrad.addColorStop(1.0, "rgb(45, 48, 55)")
                }
                root.drawRoundedRect(ctx, botHalf.x, botHalf.y, botHalf.width, botHalf.height, 3.0)
                ctx.fillStyle = botGrad
                ctx.fill()

                // Center seam line
                ctx.strokeStyle = "rgb(25, 27, 30)"
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.moveTo(p.x + 3, p.y + halfH)
                ctx.lineTo(p.x + p.width - 3, p.y + halfH)
                ctx.stroke()

                // Traction ribs
                ctx.strokeStyle = "rgba(30, 32, 36, 0.63)"
                ctx.lineWidth = 1.0
                ctx.beginPath()
                for (let i = 1; i <= 2; ++i) {
                    const yTop = topHalf.y + (halfH / 3.0) * i
                    ctx.moveTo(topHalf.x + 6, yTop)
                    ctx.lineTo(topHalf.x + topHalf.width - 6, yTop)

                    const yBot = botHalf.y + (halfH / 3.0) * i
                    ctx.moveTo(botHalf.x + 6, yBot)
                    ctx.lineTo(botHalf.x + botHalf.width - 6, yBot)
                }
                ctx.stroke()

                // Illuminated status indicator line on ON half
                const ledW = Math.min(10, p.width * 0.4)
                const ledBar = {
                    x: p.x + (p.width - ledW) * 0.5,
                    y: topHalf.y + 6,
                    width: ledW,
                    height: 4
                }
                const active = (root.position > 0)
                if (active) {
                    const gc = Qt.color(root.ledColor)
                    ctx.fillStyle = Qt.rgba(gc.r, gc.g, gc.b, 0.4).toString()
                    root.drawRoundedRect(ctx, ledBar.x - 2, ledBar.y - 2, ledBar.width + 4, ledBar.height + 4, 2.5)
                    ctx.fill()

                    ctx.fillStyle = root.ledColor.toString()
                    root.drawRoundedRect(ctx, ledBar.x, ledBar.y, ledBar.width, ledBar.height, 1.5)
                    ctx.fill()
                } else {
                    ctx.fillStyle = "rgb(40, 42, 46)"
                    root.drawRoundedRect(ctx, ledBar.x, ledBar.y, ledBar.width, ledBar.height, 1.5)
                    ctx.fill()
                }
            } else {
                // Horizontal orientation
                const halfW = p.width * 0.5
                const leftHalf = { x: p.x, y: p.y, width: halfW, height: p.height }
                const rightHalf = { x: p.x + halfW, y: p.y, width: halfW, height: p.height }

                const leftGrad = ctx.createLinearGradient(leftHalf.x, leftHalf.y, leftHalf.x + halfW, leftHalf.y)
                const rightGrad = ctx.createLinearGradient(rightHalf.x, rightHalf.y, rightHalf.x + halfW, rightHalf.y)

                if (tilt < 0) {
                    leftGrad.addColorStop(0.0, "rgb(35, 37, 42)")
                    leftGrad.addColorStop(1.0, "rgb(50, 53, 60)")
                    rightGrad.addColorStop(0.0, "rgb(52, 56, 64)")
                    rightGrad.addColorStop(1.0, "rgb(75, 80, 90)")
                } else {
                    leftGrad.addColorStop(0.0, "rgb(80, 85, 95)")
                    leftGrad.addColorStop(1.0, "rgb(48, 51, 58)")
                    rightGrad.addColorStop(0.0, "rgb(50, 53, 60)")
                    rightGrad.addColorStop(1.0, "rgb(35, 37, 42)")
                }

                root.drawRoundedRect(ctx, leftHalf.x, leftHalf.y, leftHalf.width, leftHalf.height, 3.0)
                ctx.fillStyle = leftGrad
                ctx.fill()

                root.drawRoundedRect(ctx, rightHalf.x, rightHalf.y, rightHalf.width, rightHalf.height, 3.0)
                ctx.fillStyle = rightGrad
                ctx.fill()

                ctx.strokeStyle = "rgb(25, 27, 30)"
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.moveTo(p.x + halfW, p.y + 3)
                ctx.lineTo(p.x + halfW, p.y + p.height - 3)
                ctx.stroke()
            }

            ctx.restore()
        }

        // Draw Pilot Status LED
        function drawPilotLed(ctx, cx, cy, radius, active) {
            ctx.save()

            // Outer bezel ring
            const bezelGrad = ctx.createRadialGradient(cx - radius * 0.3, cy - radius * 0.3, 0, cx, cy, radius * 1.5)
            bezelGrad.addColorStop(0.0, "rgb(200, 205, 210)")
            bezelGrad.addColorStop(0.6, "rgb(100, 105, 110)")
            bezelGrad.addColorStop(1.0, "rgb(50, 52, 55)")
            ctx.fillStyle = bezelGrad
            ctx.beginPath()
            ctx.arc(cx, cy, radius * 1.35, 0, 2 * Math.PI)
            ctx.fill()

            // Lens & Halo Glow
            const lensGrad = ctx.createRadialGradient(cx - radius * 0.25, cy - radius * 0.25, 0, cx, cy, radius)
            if (active) {
                const halo = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius * 2.5)
                const gc = Qt.color(root.ledColor)
                halo.addColorStop(0.0, Qt.rgba(gc.r, gc.g, gc.b, 0.47).toString())
                halo.addColorStop(1.0, Qt.rgba(gc.r, gc.g, gc.b, 0.0).toString())
                ctx.fillStyle = halo
                ctx.beginPath()
                ctx.arc(cx, cy, radius * 2.5, 0, 2 * Math.PI)
                ctx.fill()

                lensGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.94)")
                lensGrad.addColorStop(0.3, Qt.lighter(root.ledColor, 1.3).toString())
                lensGrad.addColorStop(0.8, root.ledColor.toString())
                lensGrad.addColorStop(1.0, Qt.darker(root.ledColor, 1.6).toString())
            } else {
                lensGrad.addColorStop(0.0, Qt.darker(root.ledColor, 2.8).toString())
                lensGrad.addColorStop(0.7, Qt.darker(root.ledColor, 3.5).toString())
                lensGrad.addColorStop(1.0, "rgb(25, 25, 25)")
            }

            ctx.fillStyle = lensGrad
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
            ctx.fill()

            // Specular reflection
            ctx.fillStyle = active ? "rgba(255, 255, 255, 0.63)" : "rgba(255, 255, 255, 0.27)"
            ctx.beginPath()
            const hx = cx - radius * 0.2
            const hy = cy - radius * 0.3
            const hrw = radius * 0.35
            const hrh = radius * 0.2
            ctx.save()
            ctx.translate(hx, hy)
            ctx.scale(hrw, hrh)
            ctx.arc(0, 0, 1, 0, 2 * Math.PI)
            ctx.restore()
            ctx.fill()

            ctx.restore()
        }

        // Draw Flip-Up Safety Guard
        function drawSafetyGuard(ctx, l) {
            const guardBase = l.guard
            const openFactor = root.guardOpenFactor

            // Open guard seen edge-on
            if (openFactor > 0.0) {
                const strip = l.openGuard
                ctx.save()
                ctx.globalAlpha = openFactor

                const stripGrad = (root.orientation === IndustrialSwitch.Orientation.Vertical)
                    ? ctx.createLinearGradient(strip.x, 0, strip.x + strip.width, 0)
                    : ctx.createLinearGradient(0, strip.y, 0, strip.y + strip.height)
                stripGrad.addColorStop(0.0, Qt.darker(root.guardColor, 1.5).toString())
                stripGrad.addColorStop(0.5, Qt.lighter(root.guardColor, 1.2).toString())
                stripGrad.addColorStop(1.0, root.guardColor.toString())

                root.drawRoundedRect(ctx, strip.x, strip.y, strip.width, strip.height, 2.0)
                ctx.fillStyle = stripGrad
                ctx.fill()
                ctx.strokeStyle = "rgb(40, 10, 15)"
                ctx.lineWidth = 1.0
                ctx.stroke()
                ctx.restore()
            }

            if (openFactor >= 1.0) {
                return
            }

            // Closed cover (fading out as it opens)
            ctx.save()
            ctx.globalAlpha = 0.9 * (1.0 - openFactor)

            // Drop shadow
            if (openFactor < 0.95) {
                ctx.fillStyle = "rgba(10, 10, 12, " + (0.47 * (1.0 - openFactor * 0.6)) + ")"
                root.drawRoundedRect(ctx, guardBase.x + 2, guardBase.y + 3, guardBase.width, guardBase.height, 6.0)
                ctx.fill()
            }

            // Outer crimson shell
            const guardGrad = ctx.createLinearGradient(guardBase.x, guardBase.y, guardBase.x + guardBase.width, guardBase.y + guardBase.height)
            guardGrad.addColorStop(0.0, Qt.lighter(root.guardColor, 1.3).toString())
            guardGrad.addColorStop(0.4, root.guardColor.toString())
            guardGrad.addColorStop(1.0, Qt.darker(root.guardColor, 1.5).toString())

            root.drawRoundedRect(ctx, guardBase.x, guardBase.y, guardBase.width, guardBase.height, 6.0)
            ctx.fillStyle = guardGrad
            ctx.fill()
            ctx.strokeStyle = "rgb(40, 10, 15)"
            ctx.lineWidth = 1.2
            ctx.stroke()

            // Warning Hazard Chevron Stripes across lower cover
            ctx.save()
            root.drawRoundedRect(ctx, guardBase.x, guardBase.y, guardBase.width, guardBase.height, 6.0)
            ctx.clip()

            ctx.strokeStyle = "rgba(245, 195, 35, 0.75)"
            ctx.lineWidth = 3.0
            ctx.beginPath()
            for (let x = guardBase.x - 20; x < guardBase.x + guardBase.width + 20; x += 12.0) {
                ctx.moveTo(x, guardBase.y + guardBase.height)
                ctx.lineTo(x + 16, guardBase.y + guardBase.height - 16)
            }
            ctx.stroke()

            // Inspection Viewing Window
            const winX = guardBase.x + 8
            const winY = guardBase.y + 12
            const winW = Math.max(4, guardBase.width - 16)
            const winH = Math.max(4, guardBase.height - 30)

            root.drawRoundedRect(ctx, winX, winY, winW, winH, 3.0)
            ctx.fillStyle = "rgba(30, 30, 35, 0.43)"
            ctx.fill()
            ctx.strokeStyle = "rgba(20, 20, 20, 0.75)"
            ctx.lineWidth = 1.0
            ctx.stroke()

            // Specular streak reflection
            ctx.strokeStyle = "rgba(255, 255, 255, 0.28)"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.moveTo(winX + 3, winY + 3)
            ctx.lineTo(winX + winW - 3, winY + winH - 3)
            ctx.stroke()

            ctx.restore() // restore clip

            // Metallic side hinge brackets
            ctx.save()
            ctx.strokeStyle = "rgba(40, 42, 45, 0.8)"
            ctx.lineWidth = 0.8

            const hingeLGrad = ctx.createLinearGradient(guardBase.x - 2, 0, guardBase.x + 2, 0)
            hingeLGrad.addColorStop(0.0, "rgb(220, 225, 230)")
            hingeLGrad.addColorStop(1.0, "rgb(90, 95, 100)")
            ctx.fillStyle = hingeLGrad
            ctx.fillRect(guardBase.x - 2, guardBase.y + 2, 4, 10)
            ctx.strokeRect(guardBase.x - 2, guardBase.y + 2, 4, 10)

            const hingeRGrad = ctx.createLinearGradient(guardBase.x + guardBase.width - 2, 0, guardBase.x + guardBase.width + 2, 0)
            hingeRGrad.addColorStop(0.0, "rgb(220, 225, 230)")
            hingeRGrad.addColorStop(1.0, "rgb(90, 95, 100)")
            ctx.fillStyle = hingeRGrad
            ctx.fillRect(guardBase.x + guardBase.width - 2, guardBase.y + 2, 4, 10)
            ctx.strokeRect(guardBase.x + guardBase.width - 2, guardBase.y + 2, 4, 10)
            ctx.restore()

            // Bottom Lift Tab
            const tabW = Math.min(24, guardBase.width * 0.6)
            const tabX = guardBase.x + (guardBase.width - tabW) * 0.5
            const tabY = guardBase.y + guardBase.height - 3
            root.drawRoundedRect(ctx, tabX, tabY, tabW, 7, 2.0)
            ctx.fillStyle = Qt.darker(root.guardColor, 1.2).toString()
            ctx.fill()
            ctx.strokeStyle = "rgba(40, 10, 15, 0.8)"
            ctx.lineWidth = 0.8
            ctx.stroke()

            ctx.restore()
        }
    }

    // --- Interactive Mouse & Touch Area ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        property bool dragActive: false

        onPressed: (mouse) => {
            root.forceActiveFocus()

            if (root.hasSafetyGuard) {
                if (!root.isGuardOpen) {
                    root.setGuardOpen(true)
                    return
                } else {
                    const og = root.layout.openGuard
                    const margin = 6
                    if (mouse.x >= og.x - margin && mouse.x <= og.x + og.width + margin &&
                        mouse.y >= og.y - margin && mouse.y <= og.y + og.height + margin) {
                        root.setGuardOpen(false)
                        return
                    }
                }
            }

            const sr = root.layout.switchRect
            if (root.positionCount === 2) {
                root.toggle()
            } else {
                if (root.orientation === IndustrialSwitch.Orientation.Vertical) {
                    const relY = (mouse.y - sr.y) / sr.height
                    if (relY < 0.35) root.setPosition(2)
                    else if (relY > 0.65) root.setPosition(0)
                    else root.setPosition(1)
                } else {
                    const relX = (mouse.x - sr.x) / sr.width
                    if (relX < 0.35) root.setPosition(0)
                    else if (relX > 0.65) root.setPosition(2)
                    else root.setPosition(1)
                }
            }

            dragActive = true
        }

        onPositionChanged: (mouse) => {
            if (!dragActive) return
            if (root.hasSafetyGuard && !root.isGuardOpen) return

            const sr = root.layout.switchRect
            if (root.orientation === IndustrialSwitch.Orientation.Vertical) {
                let relY = (mouse.y - sr.y) / sr.height
                relY = Math.max(0.0, Math.min(1.0, relY))
                if (root.positionCount === 2) {
                    root.setPosition(relY < 0.5 ? 1 : 0)
                } else {
                    if (relY < 0.33) root.setPosition(2)
                    else if (relY > 0.66) root.setPosition(0)
                    else root.setPosition(1)
                }
            } else {
                let relX = (mouse.x - sr.x) / sr.width
                relX = Math.max(0.0, Math.min(1.0, relX))
                if (root.positionCount === 2) {
                    root.setPosition(relX > 0.5 ? 1 : 0)
                } else {
                    if (relX < 0.33) root.setPosition(0)
                    else if (relX > 0.66) root.setPosition(2)
                    else root.setPosition(1)
                }
            }
        }

        onReleased: {
            dragActive = false
        }

        onWheel: (wheel) => {
            if (root.hasSafetyGuard && !root.isGuardOpen) return
            if (wheel.angleDelta.y > 0) {
                root.setPosition(Math.min(root.position + 1, root.positionCount - 1))
            } else if (wheel.angleDelta.y < 0) {
                root.setPosition(Math.max(root.position - 1, 0))
            }
        }
    }

    // --- Keyboard Navigation ---
    Keys.onPressed: (event) => {
        if (root.hasSafetyGuard && !root.isGuardOpen) {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                root.setGuardOpen(true)
                event.accepted = true
            }
            return
        }

        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
            root.toggle()
            event.accepted = true
            break
        case Qt.Key_Up:
        case Qt.Key_Right:
            root.setPosition(Math.min(root.position + 1, root.positionCount - 1))
            event.accepted = true
            break
        case Qt.Key_Down:
        case Qt.Key_Left:
            root.setPosition(Math.max(root.position - 1, 0))
            event.accepted = true
            break
        }
    }
}
