// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick
import "NumberFormat.js" as NumberFormat

/**
 * \class SevenSegmentDisplay
 * \brief High-performance multi-digit 7-segment digital display in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::SevenSegmentDisplay:
 * - Multi-digit vector 7-segment readouts for panel meters, counters, timers
 * - Beveled segment polygons with adjustable segment width and italic skew
 * - Unlit "ghost" segments with realistic faint shadow for authentic LED/LCD styling
 * - Decimal point placement, fixed-precision, and leading zero blanking or padding
 * - Text mode supporting numbers, dashes, underscores, and common 7-segment letter glyphs
 * - Color presets (Amber, Red, Green, Cyan, White, Blue) or custom active/inactive colors
 * - Recessed chassis bezel with inner shadow
 */
Item {
    id: root

    // --- Core Value & Text Properties ---
    property real value: 0.0
    property string text: "0.0"
    property int digitCount: 5
    property int decimalPlaces: 1
    property bool showLeadingZeros: false
    property bool showDecimalPoint: true
    property real skewAngle: 8.0              // Degrees italic forward slant
    property real segmentWidthRatio: 0.14     // Segment thickness relative to digit width

    // --- Styling & Colors ---
    property color activeSegmentColor: "#00e5ff"             // Neon Cyan LED
    property color inactiveSegmentColor: Qt.rgba(activeSegmentColor.r, activeSegmentColor.g, activeSegmentColor.b, 0.11) // Ghost segment
    property color backgroundColor: "#10141c"                // Dark LCD / LED backing panel
    property color bezelColor: "#28303c"                     // Outer metal bezel
    property bool bezelVisible: true
    property string colorPreset: ""

    // Internal state tracking
    property bool _isTextExplicit: false

    // Size Hints
    implicitWidth: Math.max(120, digitCount * 45 + 30)
    implicitHeight: 80
    width: implicitWidth
    height: implicitHeight

    // Color Preset Helper
    onColorPresetChanged: {
        const p = colorPreset.toLowerCase()
        if (p === "amber" || p === "orange") {
            activeSegmentColor = "#ffaa00"
        } else if (p === "red") {
            activeSegmentColor = "#eb3b5a"
        } else if (p === "green") {
            activeSegmentColor = "#2ecc71"
        } else if (p === "cyan" || p === "blue-light") {
            activeSegmentColor = "#00e5ff"
        } else if (p === "blue") {
            activeSegmentColor = "#3867d6"
        } else if (p === "white") {
            activeSegmentColor = "#f5f6fa"
        }
    }

    // --- Slots & API Functions ---
    function setValue(val) {
        _isTextExplicit = false
        if (isNaN(val) && isNaN(root.value)) return
        if (isFinite(val) && isFinite(root.value) && Math.abs(val - root.value) < 1e-9) return
        root.value = val
        updateFormattedText()
    }

    function setText(t) {
        _isTextExplicit = true
        root.text = String(t)
        displayCanvas.requestPaint()
    }

    function display(val) {
        if (typeof val === "number") {
            setValue(val)
        } else {
            setText(String(val))
        }
    }

    onValueChanged: {
        if (!_isTextExplicit) {
            updateFormattedText()
        }
    }

    onDigitCountChanged: {
        if (!_isTextExplicit) {
            updateFormattedText()
        } else {
            displayCanvas.requestPaint()
        }
    }

    onDecimalPlacesChanged: {
        if (!_isTextExplicit) {
            updateFormattedText()
        }
    }

    onShowLeadingZerosChanged: {
        if (!_isTextExplicit) {
            updateFormattedText()
        }
    }

    onShowDecimalPointChanged: displayCanvas.requestPaint()
    onSkewAngleChanged: displayCanvas.requestPaint()
    onSegmentWidthRatioChanged: displayCanvas.requestPaint()
    onActiveSegmentColorChanged: displayCanvas.requestPaint()
    onInactiveSegmentColorChanged: displayCanvas.requestPaint()
    onBackgroundColorChanged: displayCanvas.requestPaint()
    onBezelColorChanged: displayCanvas.requestPaint()
    onBezelVisibleChanged: displayCanvas.requestPaint()
    onTextChanged: displayCanvas.requestPaint()
    onWidthChanged: displayCanvas.requestPaint()
    onHeightChanged: displayCanvas.requestPaint()

    function updateFormattedText() {
        if (_isTextExplicit) return

        if (isNaN(root.value)) {
            root.text = " Err "
            return
        }
        if (!isFinite(root.value)) {
            root.text = (root.value > 0.0) ? " oFL " : "-oFL "
            return
        }

        let s = ""
        if (root.decimalPlaces >= 0) {
            s = NumberFormat.formatFixed(root.value, root.decimalPlaces)
        } else {
            s = String(root.value)
        }

        if (root.showLeadingZeros) {
            let intDigitsNeeded = root.digitCount - ((root.decimalPlaces > 0) ? (root.decimalPlaces + 1) : 0)
            if (root.value < 0.0) intDigitsNeeded--
            let parts = s.split('.')
            if (parts.length > 0) {
                let intPart = parts[0]
                const isNeg = intPart.startsWith('-')
                if (isNeg) intPart = intPart.substring(1)
                while (intPart.length < intDigitsNeeded) {
                    intPart = "0" + intPart
                }
                if (isNeg) intPart = "-" + intPart
                parts[0] = intPart
                s = parts.join('.')
            }
        }
        root.text = s
    }

    Component.onCompleted: {
        if (!_isTextExplicit) {
            updateFormattedText()
        }
        displayCanvas.requestPaint()
    }

    // --- 7-Segment Bitmask Encoding ---
    function encodeChar(c) {
        switch (c) {
            case '0': return 0x3F; // a,b,c,d,e,f
            case '1': return 0x06; // b,c
            case '2': return 0x5B; // a,b,d,e,g
            case '3': return 0x4F; // a,b,c,d,g
            case '4': return 0x66; // b,c,f,g
            case '5': return 0x6D; // a,c,d,f,g
            case '6': return 0x7D; // a,c,d,e,f,g
            case '7': return 0x07; // a,b,c
            case '8': return 0x7F; // a,b,c,d,e,f,g
            case '9': return 0x6F; // a,b,c,d,f,g
            case '-': return 0x40; // g
            case ' ': return 0x00;
            case '_': return 0x08; // d
            case '=': return 0x48; // d,g
            case 'A': case 'a': return 0x77;
            case 'B': case 'b': return 0x7C;
            case 'C': return 0x39;
            case 'c': return 0x58;
            case 'D': case 'd': return 0x5E;
            case 'E': case 'e': return 0x79;
            case 'F': case 'f': return 0x71;
            case 'H': case 'h': return 0x76;
            case 'L': case 'l': return 0x38;
            case 'P': case 'p': return 0x73;
            case 'O': case 'o': return 0x5C;
            case 'r': return 0x50;
            case 'U': case 'u': return 0x3E;
            default:  return 0x00;
        }
    }

    // --- Canvas Rendering ---
    Canvas {
        id: displayCanvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            if (typeof ctx.reset === "function") {
                ctx.reset()
            }
            ctx.clearRect(0, 0, width, height)

            const w = width
            const h = height
            if (w <= 10 || h <= 10) return

            // 1. Draw Outer Bezel & Inner Panel
            if (root.bezelVisible) {
                // Bezel Frame
                ctx.fillStyle = root.backgroundColor.toString()
                ctx.strokeStyle = Qt.darker(root.bezelColor, 1.5).toString()
                ctx.lineWidth = 1.5
                drawRoundedRect(ctx, 1.0, 1.0, w - 2.0, h - 2.0, 5.0)
                ctx.fill()
                ctx.stroke()

                // Subtle inner shadow highlight
                ctx.strokeStyle = "rgba(0, 0, 0, 0.45)"
                ctx.lineWidth = 1.2
                drawRoundedRect(ctx, 2.5, 2.5, w - 5.0, h - 5.0, 4.0)
                ctx.stroke()
            } else {
                ctx.fillStyle = root.backgroundColor.toString()
                ctx.fillRect(1.0, 1.0, w - 2.0, h - 2.0)
            }

            // 2. Parse Text into Digit Slots with Decimal Points
            const parsedDigits = []
            for (let i = 0; i < root.text.length; ++i) {
                const c = root.text.charAt(i)
                if (c === '.') {
                    if (parsedDigits.length > 0) {
                        parsedDigits[parsedDigits.length - 1].hasDp = true
                    } else {
                        parsedDigits.push({ ch: ' ', hasDp: true })
                    }
                } else {
                    parsedDigits.push({ ch: c, hasDp: false })
                }
            }

            // Align into digitCount slots (right aligned)
            const count = Math.max(1, root.digitCount)
            const displaySlots = []
            for (let i = 0; i < count; ++i) {
                displaySlots.push({ ch: ' ', hasDp: false })
            }

            const startIdx = count - parsedDigits.length
            for (let i = 0; i < parsedDigits.length; ++i) {
                const targetSlot = startIdx + i
                if (targetSlot >= 0 && targetSlot < count) {
                    displaySlots[targetSlot] = parsedDigits[i]
                }
            }

            // 3. Compute Digit Layout & Sizing
            const marginX = 14.0
            const marginY = 10.0
            const availW = Math.max(10.0, w - marginX * 2.0)
            const availH = Math.max(10.0, h - marginY * 2.0)

            let targetDigitH = availH
            let targetDigitW = targetDigitH * 0.52
            let spacing = targetDigitW * 0.35

            let totalNeededW = count * targetDigitW + (count - 1) * spacing
            if (totalNeededW > availW) {
                const scale = availW / totalNeededW
                targetDigitW *= scale
                targetDigitH *= scale
                spacing *= scale
                totalNeededW = availW
            }

            const startX = marginX + (availW - totalNeededW) * 0.5
            const startY = marginY + (availH - targetDigitH) * 0.5

            // 4. Render Each Digit Slot
            for (let i = 0; i < count; ++i) {
                const dx = startX + i * (targetDigitW + spacing)
                const dy = startY
                const mask = root.encodeChar(displaySlots[i].ch)
                renderSingleDigit(ctx, dx, dy, targetDigitW, targetDigitH, mask, displaySlots[i].hasDp)
            }
        }

        function drawRoundedRect(ctx, x, y, rw, rh, r) {
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

        function renderSingleDigit(ctx, rx, ry, dw, dh, mask, hasDp) {
            const t = dw * Math.max(0.08, Math.min(0.25, root.segmentWidthRatio))
            const gap = t * 0.18
            const yMid = dh * 0.5

            ctx.save()
            ctx.translate(rx, ry)

            // Italic Shear / Skew
            if (Math.abs(root.skewAngle) > 0.01) {
                const shear = -Math.tan(root.skewAngle * Math.PI / 180.0)
                ctx.translate(0, dh)
                ctx.transform(1, 0, shear, 1, 0, 0)
                ctx.translate(0, -dh)
            }

            // Segment 0 (a): top horizontal
            drawPoly(ctx, [
                [t + gap + t * 0.5, gap],
                [dw - t - gap - t * 0.5, gap],
                [dw - t - gap, gap + t * 0.5],
                [dw - t - gap - t * 0.5, gap + t],
                [t + gap + t * 0.5, gap + t],
                [t + gap, gap + t * 0.5]
            ], (mask & 0x01) !== 0)

            // Segment 1 (b): top-right vertical
            drawPoly(ctx, [
                [dw - gap - t + t * 0.5, gap + t],
                [dw - gap, gap + t + t * 0.5],
                [dw - gap, yMid - gap - t * 0.5],
                [dw - gap - t + t * 0.5, yMid - gap],
                [dw - gap - t, yMid - gap - t * 0.5],
                [dw - gap - t, gap + t + t * 0.5]
            ], (mask & 0x02) !== 0)

            // Segment 2 (c): bottom-right vertical
            drawPoly(ctx, [
                [dw - gap - t + t * 0.5, yMid + gap],
                [dw - gap, yMid + gap + t * 0.5],
                [dw - gap, dh - gap - t - t * 0.5],
                [dw - gap - t + t * 0.5, dh - gap - t],
                [dw - gap - t, dh - gap - t - t * 0.5],
                [dw - gap - t, yMid + gap + t * 0.5]
            ], (mask & 0x04) !== 0)

            // Segment 3 (d): bottom horizontal
            drawPoly(ctx, [
                [t + gap + t * 0.5, dh - gap - t],
                [dw - t - gap - t * 0.5, dh - gap - t],
                [dw - t - gap, dh - gap - t + t * 0.5],
                [dw - t - gap - t * 0.5, dh - gap],
                [t + gap + t * 0.5, dh - gap],
                [t + gap, dh - gap - t + t * 0.5]
            ], (mask & 0x08) !== 0)

            // Segment 4 (e): bottom-left vertical
            drawPoly(ctx, [
                [gap + t * 0.5, yMid + gap],
                [gap + t, yMid + gap + t * 0.5],
                [gap + t, dh - gap - t - t * 0.5],
                [gap + t * 0.5, dh - gap - t],
                [gap, dh - gap - t - t * 0.5],
                [gap, yMid + gap + t * 0.5]
            ], (mask & 0x10) !== 0)

            // Segment 5 (f): top-left vertical
            drawPoly(ctx, [
                [gap + t * 0.5, gap + t],
                [gap + t, gap + t + t * 0.5],
                [gap + t, yMid - gap - t * 0.5],
                [gap + t * 0.5, yMid - gap],
                [gap, yMid - gap - t * 0.5],
                [gap, gap + t + t * 0.5]
            ], (mask & 0x20) !== 0)

            // Segment 6 (g): middle horizontal
            drawPoly(ctx, [
                [t + gap + t * 0.5, yMid - t * 0.5],
                [dw - t - gap - t * 0.5, yMid - t * 0.5],
                [dw - t - gap, yMid],
                [dw - t - gap - t * 0.5, yMid + t * 0.5],
                [t + gap + t * 0.5, yMid + t * 0.5],
                [t + gap, yMid]
            ], (mask & 0x40) !== 0)

            // Decimal Point (DP)
            if (root.showDecimalPoint) {
                const dpSize = t * 0.95
                const dpX = dw + gap * 1.5
                const dpY = dh - t - gap
                ctx.fillStyle = hasDp ? root.activeSegmentColor.toString() : root.inactiveSegmentColor.toString()
                drawRoundedRect(ctx, dpX, dpY, dpSize, dpSize, 1.5)
                ctx.fill()
            }

            ctx.restore()
        }

        function drawPoly(ctx, pts, isActive) {
            ctx.beginPath()
            ctx.moveTo(pts[0][0], pts[0][1])
            for (let i = 1; i < pts.length; ++i) {
                ctx.lineTo(pts[i][0], pts[i][1])
            }
            ctx.closePath()
            ctx.fillStyle = isActive ? root.activeSegmentColor.toString() : root.inactiveSegmentColor.toString()
            ctx.fill()
        }
    }
}
