// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * \class LevelMeter
 * \brief Multi-channel level meter (VU / dBFS, tank levels, channel amplitudes) in Qt Quick.
 *
 * Exact replication of QtIndustrialWidgets::LevelMeter:
 * - Single or multi-channel concurrent display (e.g. Stereo Left/Right, telemetry channels)
 * - Segmented LED ladder mode or solid continuous gradient fill mode
 * - Floating peak hold indicator with configurable dwell time (peakHoldTimeMs) and linear decay (peakDecayRate)
 * - 3-stage colored threshold bands (Normal / Warning / Overload Error)
 * - Logarithmic dB ladder (-60 dB to +6 dB with 0 dB reference) or evenly spaced linear scales
 * - Dynamic collision-free tick marks and label positioning
 * - Vertical and horizontal installation orientations
 */
Item {
    id: root

    activeFocusOnTab: true

    enum DisplayMode {
        Segmented = 0,
        Continuous = 1
    }

    enum Orientation {
        Vertical = 1,
        Horizontal = 2
    }

    // --- Configuration Properties ---
    property int channelCount: 2
    property real minimum: -60.0
    property real maximum: 6.0
    property real warningThreshold: -6.0
    property real errorThreshold: 0.0
    property int segmentCount: 24
    property int displayMode: LevelMeter.DisplayMode.Segmented
    property int orientation: LevelMeter.Orientation.Vertical

    // --- Peak Hold Properties ---
    property bool peakHoldEnabled: true
    property int peakHoldTimeMs: 1200
    property real peakDecayRate: 25.0

    // --- Scale & Labels ---
    property bool scaleVisible: true
    property string unit: "dB"
    property string title: ""
    property var channelLabels: ["L", "R"]

    // --- Values ---
    // Convenience property for channel 0
    property real value: minimum
    // Multi-channel values array
    property var values: [minimum, minimum]

    // --- Colors (Matching QtIndustrialWidgets palette) ---
    property color normalColor: "#2ecc71"       // Emerald Normal
    property color warningColor: "#fed330"      // Amber Yellow
    property color errorColor: "#eb3b5a"        // Overload Red
    property color peakColor: "#ffffff"         // White peak indicator
    property color backgroundColor: "#16191e"   // Dark chassis
    property color textColor: "#b4b9c3"         // Silver-gray scale lettering

    // --- Signals ---
    signal channelValueChanged(int channel, real value)
    signal overloadOccurred(int channel)
    signal rangeChanged(real min, real max)
    signal appearanceChanged()

    // --- Size Hints ---
    implicitWidth: (orientation === LevelMeter.Orientation.Vertical)
        ? Math.max(65, 24 + channelCount * 18 + (scaleVisible ? 40 : 0))
        : 220
    implicitHeight: (orientation === LevelMeter.Orientation.Vertical)
        ? 220
        : Math.max(65, 24 + channelCount * 18 + (scaleVisible ? 36 : 0))
    width: implicitWidth
    height: implicitHeight

    // --- Internal Channel Data Storage ---
    // Array of { value, peakValue, lastPeakTime, overloadState }
    property var _channelData: []

    function _initChannelData() {
        const list = []
        for (let i = 0; i < root.channelCount; ++i) {
            const currentVal = (root.values && i < root.values.length) ? root.values[i] : root.minimum
            const clamped = Math.max(root.minimum, Math.min(root.maximum, currentVal))
            list.push({
                value: clamped,
                peakValue: clamped,
                lastPeakTime: 0,
                overloadState: false
            })
        }
        root._channelData = list
    }

    Component.onCompleted: {
        _initChannelData()
        staticBgCanvas.requestPaint()
        dynamicBarsCanvas.requestPaint()
    }

    onChannelCountChanged: {
        _initChannelData()
        staticBgCanvas.requestPaint()
        dynamicBarsCanvas.requestPaint()
        appearanceChanged()
    }

    onMinimumChanged: {
        rangeChanged(minimum, maximum)
        _initChannelData()
        staticBgCanvas.requestPaint()
        dynamicBarsCanvas.requestPaint()
    }

    onMaximumChanged: {
        rangeChanged(minimum, maximum)
        _initChannelData()
        staticBgCanvas.requestPaint()
        dynamicBarsCanvas.requestPaint()
    }

    onWarningThresholdChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onErrorThresholdChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onSegmentCountChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onDisplayModeChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onOrientationChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onScaleVisibleChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onUnitChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onTitleChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onChannelLabelsChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onNormalColorChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onWarningColorChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onErrorColorChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onPeakColorChanged: { dynamicBarsCanvas.requestPaint(); appearanceChanged() }
    onBackgroundColorChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onTextColorChanged: { staticBgCanvas.requestPaint(); appearanceChanged() }
    onWidthChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint() }
    onHeightChanged: { staticBgCanvas.requestPaint(); dynamicBarsCanvas.requestPaint() }

    onValueChanged: {
        setValue(0, value)
    }

    onValuesChanged: {
        if (!values || !values.length) return
        const count = Math.min(values.length, channelCount)
        for (let i = 0; i < count; ++i) {
            setValue(i, values[i])
        }
    }

    // --- API Methods ---
    function setValue(channelOrValue, maybeValue) {
        let ch = 0
        let val = 0.0

        if (typeof maybeValue === "undefined") {
            val = Number(channelOrValue)
            ch = 0
        } else {
            ch = Number(channelOrValue)
            val = Number(maybeValue)
        }

        if (ch < 0 || ch >= channelCount) return
        if (isNaN(val) || !isFinite(val)) return

        if (!_channelData || _channelData.length <= ch) {
            _initChannelData()
        }

        const clamped = Math.max(minimum, Math.min(maximum, val))
        const d = _channelData[ch]
        if (!d) return
        if (Math.abs(d.value - clamped) < 1e-4) return

        d.value = clamped
        const now = Date.now()

        if (d.value >= d.peakValue) {
            d.peakValue = d.value
            d.lastPeakTime = now
            if (peakHoldEnabled && !decayTimer.running) {
                root._lastDecayTime = now
                decayTimer.start()
            }
        }

        if (d.value >= errorThreshold) {
            if (!d.overloadState) {
                d.overloadState = true
                overloadOccurred(ch)
            }
        } else {
            d.overloadState = false
        }

        if (ch === 0 && root.value !== d.value) {
            root.value = d.value
        }

        channelValueChanged(ch, d.value)
        dynamicBarsCanvas.requestPaint()
    }

    function setValues(valList) {
        if (!valList || !valList.length) return
        const count = Math.min(valList.length, channelCount)
        for (let i = 0; i < count; ++i) {
            setValue(i, valList[i])
        }
    }

    function setRange(min, max) {
        if (!isFinite(min) || !isFinite(max) || min >= max) return
        minimum = min
        maximum = max
    }

    function resetPeaks() {
        if (!_channelData) return
        for (let i = 0; i < _channelData.length; ++i) {
            _channelData[i].peakValue = _channelData[i].value
            _channelData[i].lastPeakTime = Date.now()
        }
        dynamicBarsCanvas.requestPaint()
    }

    function getChannelValue(channel) {
        const ch = (typeof channel === "number") ? channel : 0
        if (_channelData && ch >= 0 && ch < _channelData.length) {
            return _channelData[ch].value
        }
        return minimum
    }

    function getPeakValue(channel) {
        const ch = (typeof channel === "number") ? channel : 0
        if (_channelData && ch >= 0 && ch < _channelData.length) {
            return _channelData[ch].peakValue
        }
        return minimum
    }

    // --- Peak Hold Decay Engine ---
    property real _lastDecayTime: 0
    Timer {
        id: decayTimer
        interval: 33 // ~30 FPS
        repeat: true
        running: false
        onTriggered: {
            const now = Date.now()
            const dt = (root._lastDecayTime > 0) ? (now - root._lastDecayTime) / 1000.0 : 0.033
            root._lastDecayTime = now

            let anyActive = false
            for (let i = 0; i < root.channelCount; ++i) {
                const d = root._channelData[i]
                if (!d) continue
                if (d.peakValue > d.value) {
                    if (now - d.lastPeakTime >= root.peakHoldTimeMs) {
                        d.peakValue = Math.max(d.value, d.peakValue - root.peakDecayRate * dt)
                    }
                    anyActive = true
                } else {
                    d.peakValue = d.value
                }
            }

            if (!anyActive) {
                decayTimer.stop()
            }
            dynamicBarsCanvas.requestPaint()
        }
    }

    // --- Color Threshold Helper ---
    function colorForNormalizedValue(norm) {
        const val = minimum + norm * (maximum - minimum)
        if (val >= errorThreshold) {
            return errorColor
        }
        if (val >= warningThreshold) {
            return warningColor
        }
        return normalColor
    }

    // --- Geometry & Layout Engine ---
    function calculateBarRects(contentRect) {
        const rects = []
        if (channelCount <= 0) return rects

        const isVert = (orientation === LevelMeter.Orientation.Vertical)
        const labelMargin = (channelLabels && channelLabels.length > 0) ? 16.0 : 0.0
        const titleMargin = (title && title.length > 0) ? 18.0 : 0.0

        if (isVert) {
            const scaleMargin = scaleVisible ? 38.0 : 0.0
            const unitBand = (scaleVisible && unit && unit.length > 0) ? 14.0 : 0.0

            const areaLeft = contentRect.left
            const areaTop = contentRect.top + titleMargin + unitBand
            const areaRight = contentRect.right - scaleMargin
            const areaBottom = contentRect.bottom - labelMargin
            const totalW = areaRight - areaLeft
            const totalH = areaBottom - areaTop

            const gap = 4.0
            const barW = Math.max(6.0, (totalW - gap * (channelCount - 1)) / channelCount)
            let curX = areaLeft + (totalW - (barW * channelCount + gap * (channelCount - 1))) * 0.5

            for (let i = 0; i < channelCount; ++i) {
                rects.push({
                    x: curX,
                    y: areaTop,
                    width: barW,
                    height: totalH,
                    left: curX,
                    top: areaTop,
                    right: curX + barW,
                    bottom: areaTop + totalH
                })
                curX += barW + gap
            }
        } else {
            const scaleMargin = scaleVisible ? 32.0 : 0.0
            const insetsLeft = labelMargin
            const insetsRight = (scaleVisible && unit && unit.length > 0) ? 26.0 : 8.0

            const areaLeft = contentRect.left + insetsLeft
            const areaTop = contentRect.top + titleMargin
            const areaRight = contentRect.right - insetsRight
            const areaBottom = contentRect.bottom - scaleMargin
            const totalW = areaRight - areaLeft
            const totalH = areaBottom - areaTop

            const gap = 4.0
            const barH = Math.max(6.0, (totalH - gap * (channelCount - 1)) / channelCount)
            let curY = areaTop + (totalH - (barH * channelCount + gap * (channelCount - 1))) * 0.5

            for (let i = 0; i < channelCount; ++i) {
                rects.push({
                    x: areaLeft,
                    y: curY,
                    width: totalW,
                    height: barH,
                    left: areaLeft,
                    top: curY,
                    right: areaLeft + totalW,
                    bottom: curY + barH
                })
                curY += barH + gap
            }
        }

        return rects
    }

    // Helper: Scale Ticks Generation
    function getScaleTicks() {
        const isDb = (minimum < 0 && maximum > 0 && unit === "dB")
        const ticks = []
        if (isDb) {
            const ladder = [-60.0, -40.0, -30.0, -20.0, -12.0, -6.0, -3.0, 0.0, 3.0, 6.0]
            for (let i = 0; i < ladder.length; ++i) {
                const t = ladder[i]
                if (t >= minimum && t <= maximum) {
                    ticks.push(t)
                }
            }
        } else {
            const divisions = 6
            const step = (maximum - minimum) / divisions
            for (let i = 0; i <= divisions; ++i) {
                ticks.push(minimum + i * step)
            }
        }
        return ticks
    }

    function formatTickText(t) {
        if (unit === "dB") {
            return (t > 0 ? "+" : "") + Math.round(t).toString()
        }
        if (Math.abs(maximum - minimum) < 10) {
            return t.toFixed(1)
        }
        return Math.round(t).toString()
    }

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

            const chassis = {
                x: 3,
                y: 3,
                width: Math.max(0, width - 6),
                height: Math.max(0, height - 6),
                left: 3,
                top: 3,
                right: width - 3,
                bottom: height - 3
            }

            // Chassis Drop Shadow
            ctx.fillStyle = "rgba(12, 14, 18, 0.63)"
            root.drawRoundedRect(ctx, chassis.x + 1.5, chassis.y + 2.0, chassis.width, chassis.height, 6.0)
            ctx.fill()

            // Chassis Body
            const bodyGrad = ctx.createLinearGradient(chassis.x, chassis.y, chassis.x + chassis.width, chassis.y + chassis.height)
            bodyGrad.addColorStop(0.0, Qt.lighter(root.backgroundColor, 1.2).toString())
            bodyGrad.addColorStop(0.5, root.backgroundColor.toString())
            bodyGrad.addColorStop(1.0, Qt.darker(root.backgroundColor, 1.3).toString())
            root.drawRoundedRect(ctx, chassis.x, chassis.y, chassis.width, chassis.height, 6.0)
            ctx.fillStyle = bodyGrad
            ctx.fill()

            // Chassis Bevel Border
            const borderGrad = ctx.createLinearGradient(chassis.x, chassis.y, chassis.x, chassis.y + chassis.height)
            borderGrad.addColorStop(0.0, "rgba(140, 150, 165, 0.63)")
            borderGrad.addColorStop(0.5, "rgba(70, 75, 85, 0.47)")
            borderGrad.addColorStop(1.0, "rgba(30, 32, 38, 0.78)")
            ctx.strokeStyle = borderGrad
            ctx.lineWidth = 1.2
            ctx.stroke()

            const contentRect = {
                left: chassis.left + 8,
                top: chassis.top + 8,
                right: chassis.right - 8,
                bottom: chassis.bottom - 8,
                width: chassis.width - 16,
                height: chassis.height - 16
            }

            // Title
            if (root.title.length > 0) {
                const titleFontPx = Math.max(8, Math.floor(Math.min(width, height) * 0.08))
                ctx.font = "bold " + titleFontPx + "px sans-serif"
                ctx.fillStyle = Qt.lighter(root.textColor, 1.2).toString()
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(root.title, contentRect.left + contentRect.width * 0.5, contentRect.top + 7)
            }

            const barRects = root.calculateBarRects(contentRect)

            // Channel Labels
            const labelFontPx = Math.max(7, Math.floor(Math.min(width, height) * 0.075))
            ctx.font = "bold " + labelFontPx + "px sans-serif"
            ctx.fillStyle = root.textColor.toString()

            for (let i = 0; i < barRects.length; ++i) {
                const br = barRects[i]
                const lbl = (root.channelLabels && i < root.channelLabels.length) ? root.channelLabels[i] : (i + 1).toString()
                if (root.orientation === LevelMeter.Orientation.Vertical) {
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText(lbl, br.left + br.width * 0.5, br.bottom + 8)
                } else {
                    ctx.textAlign = "right"
                    ctx.textBaseline = "middle"
                    ctx.fillText(lbl, br.left - 4, br.top + br.height * 0.5)
                }
            }

            // Scale graduation ticks & labels
            if (root.scaleVisible && barRects.length > 0) {
                const refBar = barRects[barRects.length - 1]
                const scaleFontPx = Math.max(7, Math.floor(Math.min(width, height) * 0.07))
                ctx.font = scaleFontPx + "px sans-serif"

                const ticks = root.getScaleTicks()
                const span = root.maximum - root.minimum

                for (let i = 0; i < ticks.length; ++i) {
                    const t = ticks[i]
                    const norm = (span > 0) ? Math.max(0.0, Math.min(1.0, (t - root.minimum) / span)) : 0.0
                    const tColor = root.colorForNormalizedValue(norm)
                    const tickStr = root.formatTickText(t)

                    ctx.strokeStyle = tColor.toString()
                    ctx.lineWidth = (t === 0.0 || t === root.errorThreshold) ? 1.5 : 1.0

                    if (root.orientation === LevelMeter.Orientation.Vertical) {
                        const y = refBar.bottom - norm * refBar.height
                        const x1 = refBar.right + 3.0
                        const x2 = x1 + 4.0

                        ctx.beginPath()
                        ctx.moveTo(x1, y)
                        ctx.lineTo(x2, y)
                        ctx.stroke()

                        // Label
                        ctx.fillStyle = tColor.toString()
                        ctx.textAlign = "left"
                        ctx.textBaseline = "middle"
                        ctx.fillText(tickStr, x2 + 3.0, y)
                    } else {
                        const x = refBar.left + norm * refBar.width
                        const y1 = refBar.bottom + 3.0
                        const y2 = y1 + 4.0

                        ctx.beginPath()
                        ctx.moveTo(x, y1)
                        ctx.lineTo(x, y2)
                        ctx.stroke()

                        // Label
                        ctx.fillStyle = tColor.toString()
                        ctx.textAlign = "center"
                        ctx.textBaseline = "top"
                        ctx.fillText(tickStr, x, y2 + 2.0)
                    }
                }

                // Unit label
                if (root.unit.length > 0) {
                    ctx.fillStyle = Qt.darker(root.textColor, 1.1).toString()
                    if (root.orientation === LevelMeter.Orientation.Vertical) {
                        ctx.textAlign = "left"
                        ctx.textBaseline = "middle"
                        ctx.fillText(root.unit, refBar.right + 4.0, refBar.top - 8.0)
                    } else {
                        ctx.textAlign = "left"
                        ctx.textBaseline = "middle"
                        ctx.fillText(root.unit, refBar.right + 6.0, refBar.top + refBar.height * 0.5)
                    }
                }
            }

            // Recessed Trough & Unlit Ghost Segments
            for (let i = 0; i < barRects.length; ++i) {
                const br = barRects[i]
                ctx.fillStyle = "rgb(12, 14, 16)"
                ctx.strokeStyle = "rgb(15, 17, 20)"
                ctx.lineWidth = 1.0
                root.drawRoundedRect(ctx, br.left - 1, br.top - 1, br.width + 2, br.height + 2, 2.0)
                ctx.fill()
                ctx.stroke()

                // Ghost Unlit Segments in Segmented mode
                if (root.displayMode === LevelMeter.DisplayMode.Segmented) {
                    const segGap = 1.5
                    if (root.orientation === LevelMeter.Orientation.Vertical) {
                        const segH = (br.height - segGap * (root.segmentCount - 1)) / root.segmentCount
                        for (let s = 0; s < root.segmentCount; ++s) {
                            const norm = s / Math.max(1, root.segmentCount - 1)
                            const y = br.bottom - (s + 1) * segH - s * segGap
                            const unlit = Qt.color(root.colorForNormalizedValue(norm))

                            ctx.fillStyle = Qt.rgba(unlit.r, unlit.g, unlit.b, 0.14).toString()
                            ctx.strokeStyle = "rgba(25, 27, 30, 0.5)"
                            ctx.lineWidth = 0.5
                            root.drawRoundedRect(ctx, br.left, y, br.width, segH, 1.0)
                            ctx.fill()
                            ctx.stroke()
                        }
                    } else {
                        const segW = (br.width - segGap * (root.segmentCount - 1)) / root.segmentCount
                        for (let s = 0; s < root.segmentCount; ++s) {
                            const norm = s / Math.max(1, root.segmentCount - 1)
                            const x = br.left + s * segW + s * segGap
                            const unlit = Qt.color(root.colorForNormalizedValue(norm))

                            ctx.fillStyle = Qt.rgba(unlit.r, unlit.g, unlit.b, 0.14).toString()
                            ctx.strokeStyle = "rgba(25, 27, 30, 0.5)"
                            ctx.lineWidth = 0.5
                            root.drawRoundedRect(ctx, x, br.top, segW, br.height, 1.0)
                            ctx.fill()
                            ctx.stroke()
                        }
                    }
                }
            }
        }
    }

    // --- 2. Dynamic Bars & Peaks Canvas ---
    Canvas {
        id: dynamicBarsCanvas
        anchors.fill: parent
        z: 1

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            if (typeof ctx.reset === "function") {
                ctx.reset()
            }
            ctx.clearRect(0, 0, width, height)

            const chassis = {
                left: 3, top: 3, right: width - 3, bottom: height - 3,
                width: width - 6, height: height - 6
            }
            const contentRect = {
                left: chassis.left + 8, top: chassis.top + 8,
                right: chassis.right - 8, bottom: chassis.bottom - 8,
                width: chassis.width - 16, height: chassis.height - 16
            }

            const barRects = root.calculateBarRects(contentRect)
            const count = Math.min(barRects.length, root._channelData ? root._channelData.length : 0)

            for (let i = 0; i < count; ++i) {
                const ch = root._channelData[i]
                const br = barRects[i]
                if (root.displayMode === LevelMeter.DisplayMode.Segmented) {
                    drawSegmentedBar(ctx, ch.value, ch.peakValue, br)
                } else {
                    drawContinuousBar(ctx, ch.value, ch.peakValue, br)
                }
            }
        }

        // Draw Segmented LED Bar
        function drawSegmentedBar(ctx, val, peakVal, barRect) {
            ctx.save()

            const span = root.maximum - root.minimum
            const normVal = (span > 0) ? Math.max(0.0, Math.min(1.0, (val - root.minimum) / span)) : 0.0
            const normPeak = (span > 0) ? Math.max(0.0, Math.min(1.0, (peakVal - root.minimum) / span)) : 0.0

            const litCount = Math.round(normVal * root.segmentCount)
            const peakIndex = (root.peakHoldEnabled && normPeak > 0.0)
                ? Math.min(root.segmentCount - 1, Math.round(normPeak * (root.segmentCount - 1)))
                : -1

            const segGap = 1.5

            if (root.orientation === LevelMeter.Orientation.Vertical) {
                const segH = (barRect.height - segGap * (root.segmentCount - 1)) / root.segmentCount

                for (let s = 0; s < root.segmentCount; ++s) {
                    const norm = s / Math.max(1, root.segmentCount - 1)
                    const y = barRect.bottom - (s + 1) * segH - s * segGap
                    const isLit = (s < litCount)
                    const isPeak = (s === peakIndex)

                    if (isLit) {
                        const col = root.colorForNormalizedValue(norm)
                        const segGrad = ctx.createLinearGradient(barRect.left, y, barRect.left, y + segH)
                        segGrad.addColorStop(0.0, Qt.lighter(col, 1.35).toString())
                        segGrad.addColorStop(0.5, col.toString())
                        segGrad.addColorStop(1.0, Qt.darker(col, 1.2).toString())

                        ctx.fillStyle = segGrad
                        ctx.strokeStyle = Qt.darker(col, 1.4).toString()
                        ctx.lineWidth = 0.5
                        root.drawRoundedRect(ctx, barRect.left, y, barRect.width, segH, 1.0)
                        ctx.fill()
                        ctx.stroke()
                    }

                    if (isPeak && !isLit) {
                        const peakCol = (normPeak * span + root.minimum >= root.errorThreshold)
                            ? root.errorColor : root.peakColor
                        const peakGrad = ctx.createLinearGradient(barRect.left, y, barRect.left, y + segH)
                        peakGrad.addColorStop(0.0, "#ffffff")
                        peakGrad.addColorStop(0.4, peakCol.toString())
                        peakGrad.addColorStop(1.0, Qt.darker(peakCol, 1.2).toString())

                        ctx.fillStyle = peakGrad
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.78)"
                        ctx.lineWidth = 0.6
                        root.drawRoundedRect(ctx, barRect.left, y, barRect.width, segH, 1.0)
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            } else {
                const segW = (barRect.width - segGap * (root.segmentCount - 1)) / root.segmentCount

                for (let s = 0; s < root.segmentCount; ++s) {
                    const norm = s / Math.max(1, root.segmentCount - 1)
                    const x = barRect.left + s * segW + s * segGap
                    const isLit = (s < litCount)
                    const isPeak = (s === peakIndex)

                    if (isLit) {
                        const col = root.colorForNormalizedValue(norm)
                        const segGrad = ctx.createLinearGradient(x, barRect.top, x, barRect.top + barRect.height)
                        segGrad.addColorStop(0.0, Qt.lighter(col, 1.35).toString())
                        segGrad.addColorStop(0.5, col.toString())
                        segGrad.addColorStop(1.0, Qt.darker(col, 1.2).toString())

                        ctx.fillStyle = segGrad
                        ctx.strokeStyle = Qt.darker(col, 1.4).toString()
                        ctx.lineWidth = 0.5
                        root.drawRoundedRect(ctx, x, barRect.top, segW, barRect.height, 1.0)
                        ctx.fill()
                        ctx.stroke()
                    }

                    if (isPeak && !isLit) {
                        const peakCol = (normPeak * span + root.minimum >= root.errorThreshold)
                            ? root.errorColor : root.peakColor
                        ctx.fillStyle = peakCol.toString()
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.78)"
                        ctx.lineWidth = 0.6
                        root.drawRoundedRect(ctx, x, barRect.top, segW, barRect.height, 1.0)
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            }

            ctx.restore()
        }

        // Draw Solid Continuous Gradient Bar
        function drawContinuousBar(ctx, val, peakVal, barRect) {
            ctx.save()

            const span = root.maximum - root.minimum
            const normVal = (span > 0) ? Math.max(0.0, Math.min(1.0, (val - root.minimum) / span)) : 0.0
            const normPeak = (span > 0) ? Math.max(0.0, Math.min(1.0, (peakVal - root.minimum) / span)) : 0.0

            if (root.orientation === LevelMeter.Orientation.Vertical) {
                const filledH = normVal * barRect.height
                if (filledH > 0.5) {
                    const fillY = barRect.bottom - filledH
                    const grad = ctx.createLinearGradient(barRect.left, barRect.bottom, barRect.left, barRect.top)
                    grad.addColorStop(0.0, root.normalColor.toString())
                    const warnNorm = (span > 0) ? Math.max(0.0, Math.min(1.0, (root.warningThreshold - root.minimum) / span)) : 0.7
                    const errNorm = (span > 0) ? Math.max(0.0, Math.min(1.0, (root.errorThreshold - root.minimum) / span)) : 0.9
                    grad.addColorStop(warnNorm, root.warningColor.toString())
                    grad.addColorStop(errNorm, root.errorColor.toString())

                    ctx.fillStyle = grad
                    root.drawRoundedRect(ctx, barRect.left, fillY, barRect.width, filledH, 1.5)
                    ctx.fill()
                }

                // Floating Peak Indicator Line
                if (root.peakHoldEnabled && normPeak > 0.0) {
                    const peakY = barRect.bottom - normPeak * barRect.height
                    const peakCol = (normPeak * span + root.minimum >= root.errorThreshold)
                        ? root.errorColor : root.peakColor
                    ctx.strokeStyle = peakCol.toString()
                    ctx.lineWidth = 2.0
                    ctx.beginPath()
                    ctx.moveTo(barRect.left, peakY)
                    ctx.lineTo(barRect.right, peakY)
                    ctx.stroke()
                }
            } else {
                const filledW = normVal * barRect.width
                if (filledW > 0.5) {
                    const grad = ctx.createLinearGradient(barRect.left, barRect.top, barRect.right, barRect.top)
                    grad.addColorStop(0.0, root.normalColor.toString())
                    const warnNorm = (span > 0) ? Math.max(0.0, Math.min(1.0, (root.warningThreshold - root.minimum) / span)) : 0.7
                    const errNorm = (span > 0) ? Math.max(0.0, Math.min(1.0, (root.errorThreshold - root.minimum) / span)) : 0.9
                    grad.addColorStop(warnNorm, root.warningColor.toString())
                    grad.addColorStop(errNorm, root.errorColor.toString())

                    ctx.fillStyle = grad
                    root.drawRoundedRect(ctx, barRect.left, barRect.top, filledW, barRect.height, 1.5)
                    ctx.fill()
                }

                // Floating Peak Indicator Line
                if (root.peakHoldEnabled && normPeak > 0.0) {
                    const peakX = barRect.left + normPeak * barRect.width
                    const peakCol = (normPeak * span + root.minimum >= root.errorThreshold)
                        ? root.errorColor : root.peakColor
                    ctx.strokeStyle = peakCol.toString()
                    ctx.lineWidth = 2.0
                    ctx.beginPath()
                    ctx.moveTo(peakX, barRect.top)
                    ctx.lineTo(peakX, barRect.bottom)
                    ctx.stroke()
                }
            }

            ctx.restore()
        }
    }
}
