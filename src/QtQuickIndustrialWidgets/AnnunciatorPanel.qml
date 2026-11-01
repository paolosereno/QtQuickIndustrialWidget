// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * \class AnnunciatorPanel
 * \brief Alarm annunciator grid with automatic-reset and manual-reset sequences.
 *
 * Full Qt Quick implementation matching QtIndustrialWidgets::AnnunciatorPanel:
 * - Configurable rows x columns grid of alarm tiles, each with text legend and severity.
 * - ISA-18.1 compliant alarm sequences: SequenceA_AutomaticReset and SequenceM_ManualReset.
 * - Alarm tile states: Normal (unlit), Unacknowledged (fast flash, 2 Hz), Acknowledged (steady on),
 *   and Ringback (slow flash, 0.8 Hz).
 * - Severities and default colors: Critical (red), Warning (amber), Advisory (cyan).
 * - Global operations: Acknowledge (ACK), Silence (horn off), Reset, and Lamp Test (all tiles lit).
 * - Audible horn output signal (audibleHornChanged / audibleHornActive).
 * - Tile acknowledgement and reset by direct mouse click on each tile.
 * - Heavy industrial dark chassis with metallic hex corner bolts, divider channels, and acrylic gloss.
 */
Item {
    id: root

    activeFocusOnTab: true

    enum Severity {
        Critical = 0,
        Warning = 1,
        Advisory = 2
    }

    enum AlarmState {
        Normal = 0,
        Unacknowledged = 1,
        Acknowledged = 2,
        Ringback = 3
    }

    enum AnnunciatorSequence {
        SequenceA_AutomaticReset = 0,
        SequenceM_ManualReset = 1
    }

    // --- Grid Configuration Properties ---
    property int rows: 2
    property int columns: 4
    readonly property int tileCount: rows * columns
    property int sequence: AnnunciatorPanel.AnnunciatorSequence.SequenceA_AutomaticReset
    property bool lampTestActive: false

    // --- Alarm Summary & Horn Status ---
    property bool audibleHornActive: false
    property int activeAlarmsCount: 0
    property int unacknowledgedCount: 0
    property bool _hornSilenced: false

    // --- Styling Colors ---
    property color frameColor: "#1e242e"       // Heavy industrial dark chassis
    property color gridColor: "#374150"        // Metal grid divider bars
    property color criticalColor: "#eb3b5a"   // Crimson red alarm
    property color warningColor: "#fed330"    // Amber gold warning
    property color advisoryColor: "#00e5ff"   // Cyan advisory
    property color textColor: "#f0f4fa"       // White engraved text

    // --- Dimensions & Spacing ---
    property real panelMargin: 12.0
    property real tileSpacing: 4.0

    // --- Signals ---
    signal tileClicked(int index)
    signal tileStateChanged(int index, int newState)
    signal audibleHornChanged(bool active)
    signal appearanceChanged()

    // --- Size Hints ---
    implicitWidth: columns * 130 + 24
    implicitHeight: rows * 75 + 24
    width: implicitWidth
    height: implicitHeight

    // --- Flash Timers (Fast: 2 Hz, Slow: 0.8 Hz) ---
    property int _flashTickCounter: 0
    property bool _fastFlashPhase: true
    property bool _slowFlashPhase: true

    Timer {
        id: flashTimer
        interval: 125 // 8 Hz ticks
        running: true
        repeat: true
        onTriggered: {
            root._flashTickCounter++
            root._fastFlashPhase = ((Math.floor(root._flashTickCounter / 2)) % 2) === 0
            root._slowFlashPhase = ((Math.floor(root._flashTickCounter / 5)) % 2) === 0
        }
    }

    // --- Internal Model ---
    ListModel {
        id: tilesModel
    }

    function _rebuildModel() {
        const count = Math.max(1, root.rows) * Math.max(1, root.columns)
        const oldData = []
        for (let i = 0; i < tilesModel.count; ++i) {
            const item = tilesModel.get(i)
            oldData.push({
                text: item.text,
                severity: item.severity,
                state: item.state,
                alarmActive: item.alarmActive
            })
        }

        tilesModel.clear()
        for (let j = 0; j < count; ++j) {
            const prev = (j < oldData.length) ? oldData[j] : null
            tilesModel.append({
                text: prev ? prev.text : ("ALARM " + (j + 1)),
                severity: prev ? prev.severity : (j % 3 === 0 ? AnnunciatorPanel.Severity.Critical : (j % 3 === 1 ? AnnunciatorPanel.Severity.Warning : AnnunciatorPanel.Severity.Advisory)),
                state: prev ? prev.state : AnnunciatorPanel.AlarmState.Normal,
                alarmActive: prev ? prev.alarmActive : false
            })
        }
        updateHornAndSummary()
    }

    function updateHornAndSummary() {
        let activeCount = 0
        let unackCount = 0
        for (let i = 0; i < tilesModel.count; ++i) {
            const item = tilesModel.get(i)
            if (item.alarmActive || item.state !== AnnunciatorPanel.AlarmState.Normal) {
                activeCount++
            }
            if (item.state === AnnunciatorPanel.AlarmState.Unacknowledged) {
                unackCount++
            }
        }
        root.activeAlarmsCount = activeCount
        root.unacknowledgedCount = unackCount

        const shouldHorn = (unackCount > 0) && !root._hornSilenced
        if (root.audibleHornActive !== shouldHorn) {
            root.audibleHornActive = shouldHorn
            audibleHornChanged(root.audibleHornActive)
        }
    }

    // --- API Functions ---
    function setRows(newRows) {
        setGridSize(newRows, root.columns)
    }

    function setColumns(newCols) {
        setGridSize(root.rows, newCols)
    }

    function setGridSize(newRows, newCols) {
        const r = Math.max(1, newRows)
        const c = Math.max(1, newCols)
        if (r === root.rows && c === root.columns) return
        root.rows = r
        root.columns = c
        _rebuildModel()
        appearanceChanged()
    }

    function setSequence(seq) {
        if (root.sequence !== seq) {
            root.sequence = seq
            appearanceChanged()
        }
    }

    function tileText(index) {
        if (index >= 0 && index < tilesModel.count) {
            return tilesModel.get(index).text
        }
        return ""
    }

    function tileSeverity(index) {
        if (index >= 0 && index < tilesModel.count) {
            return tilesModel.get(index).severity
        }
        return AnnunciatorPanel.Severity.Critical
    }

    function tileState(index) {
        if (index >= 0 && index < tilesModel.count) {
            return tilesModel.get(index).state
        }
        return AnnunciatorPanel.AlarmState.Normal
    }

    function isAlarmActive(index) {
        if (index >= 0 && index < tilesModel.count) {
            return tilesModel.get(index).alarmActive
        }
        return false
    }

    function setTileText(indexOrRow, textOrCol, maybeText) {
        if (typeof maybeText !== "undefined") {
            const row = indexOrRow
            const col = textOrCol
            const text = maybeText
            if (row >= 0 && row < root.rows && col >= 0 && col < root.columns) {
                setTileText(row * root.columns + col, text)
            }
            return
        }
        const index = indexOrRow
        const txt = textOrCol
        if (index >= 0 && index < tilesModel.count) {
            tilesModel.setProperty(index, "text", txt)
        }
    }

    function setTileSeverity(indexOrRow, severityOrCol, maybeSeverity) {
        if (typeof maybeSeverity !== "undefined") {
            const row = indexOrRow
            const col = severityOrCol
            const sev = maybeSeverity
            if (row >= 0 && row < root.rows && col >= 0 && col < root.columns) {
                setTileSeverity(row * root.columns + col, sev)
            }
            return
        }
        const index = indexOrRow
        const severity = severityOrCol
        if (index >= 0 && index < tilesModel.count) {
            tilesModel.setProperty(index, "severity", severity)
        }
    }

    function setAlarmActive(indexOrRow, activeOrCol, maybeActive) {
        if (typeof maybeActive !== "undefined") {
            const row = indexOrRow
            const col = activeOrCol
            const act = maybeActive
            if (row >= 0 && row < root.rows && col >= 0 && col < root.columns) {
                setAlarmActive(row * root.columns + col, act)
            }
            return
        }
        const index = indexOrRow
        const active = activeOrCol
        if (index < 0 || index >= tilesModel.count) return

        const tile = tilesModel.get(index)
        if (tile.alarmActive === active) return

        tilesModel.setProperty(index, "alarmActive", active)

        if (active) {
            tilesModel.setProperty(index, "state", AnnunciatorPanel.AlarmState.Unacknowledged)
            root._hornSilenced = false
            tileStateChanged(index, AnnunciatorPanel.AlarmState.Unacknowledged)
        } else {
            if (tile.state === AnnunciatorPanel.AlarmState.Acknowledged) {
                const nextState = (root.sequence === AnnunciatorPanel.AnnunciatorSequence.SequenceA_AutomaticReset)
                    ? AnnunciatorPanel.AlarmState.Normal
                    : AnnunciatorPanel.AlarmState.Ringback
                tilesModel.setProperty(index, "state", nextState)
                tileStateChanged(index, nextState)
            }
        }
        updateHornAndSummary()
    }

    function triggerAlarm(index) {
        setAlarmActive(index, true)
    }

    function clearAlarm(index) {
        setAlarmActive(index, false)
    }

    function acknowledge(index) {
        if (index < 0 || index >= tilesModel.count) return
        const tile = tilesModel.get(index)
        if (tile.state === AnnunciatorPanel.AlarmState.Unacknowledged) {
            const nextState = tile.alarmActive ? AnnunciatorPanel.AlarmState.Acknowledged : AnnunciatorPanel.AlarmState.Normal
            tilesModel.setProperty(index, "state", nextState)
            tileStateChanged(index, nextState)
            updateHornAndSummary()
        }
    }

    function acknowledgeAll() {
        for (let i = 0; i < tilesModel.count; ++i) {
            const tile = tilesModel.get(i)
            if (tile.state === AnnunciatorPanel.AlarmState.Unacknowledged) {
                const nextState = tile.alarmActive ? AnnunciatorPanel.AlarmState.Acknowledged : AnnunciatorPanel.AlarmState.Normal
                tilesModel.setProperty(i, "state", nextState)
                tileStateChanged(i, nextState)
            }
        }
        root._hornSilenced = true
        updateHornAndSummary()
    }

    function silence() {
        if (!root._hornSilenced) {
            root._hornSilenced = true
            updateHornAndSummary()
        }
    }

    function reset(index) {
        if (index < 0 || index >= tilesModel.count) return
        const tile = tilesModel.get(index)
        if (!tile.alarmActive && (tile.state === AnnunciatorPanel.AlarmState.Ringback || tile.state === AnnunciatorPanel.AlarmState.Acknowledged)) {
            tilesModel.setProperty(index, "state", AnnunciatorPanel.AlarmState.Normal)
            tileStateChanged(index, AnnunciatorPanel.AlarmState.Normal)
            updateHornAndSummary()
        }
    }

    function resetAll() {
        for (let i = 0; i < tilesModel.count; ++i) {
            const tile = tilesModel.get(i)
            if (!tile.alarmActive && (tile.state === AnnunciatorPanel.AlarmState.Ringback || tile.state === AnnunciatorPanel.AlarmState.Acknowledged)) {
                tilesModel.setProperty(i, "state", AnnunciatorPanel.AlarmState.Normal)
                tileStateChanged(i, AnnunciatorPanel.AlarmState.Normal)
            }
        }
        updateHornAndSummary()
    }

    function setLampTest(active) {
        if (root.lampTestActive !== active) {
            root.lampTestActive = active
            appearanceChanged()
        }
    }

    function colorForSeverity(severity, lit) {
        let base
        switch (severity) {
        case AnnunciatorPanel.Severity.Critical: base = root.criticalColor; break
        case AnnunciatorPanel.Severity.Warning:  base = root.warningColor; break
        case AnnunciatorPanel.Severity.Advisory: base = root.advisoryColor; break
        default: base = root.criticalColor; break
        }

        if (lit) {
            return base
        } else {
            return Qt.rgba(base.r / 6.0, base.g / 6.0, base.b / 6.0, 0.86)
        }
    }

    onRowsChanged: _rebuildModel()
    onColumnsChanged: _rebuildModel()
    onFrameColorChanged: appearanceChanged()
    onGridColorChanged: appearanceChanged()
    onCriticalColorChanged: appearanceChanged()
    onWarningColorChanged: appearanceChanged()
    onAdvisoryColorChanged: appearanceChanged()
    onTextColorChanged: appearanceChanged()

    Component.onCompleted: {
        _rebuildModel()
    }

    // ========================================================================
    // CHASSIS BACKGROUND: Industrial Chassis Bevel + Metal Corner Bolts
    // ========================================================================
    Rectangle {
        id: chassisFrame
        anchors.fill: parent
        radius: 6
        color: root.frameColor
        border.color: Qt.rgba(0.04, 0.05, 0.08, 0.8)
        border.width: 1.5

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.frameColor, 1.35) }
            GradientStop { position: 0.4; color: root.frameColor }
            GradientStop { position: 1.0; color: Qt.darker(root.frameColor, 1.40) }
        }

        // Inner bevel highlight line
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 5
            color: "transparent"
            border.color: Qt.lighter(root.frameColor, 1.50)
            border.width: 1.0
        }

        // 4 Corner Hex Machined Bolts
        Repeater {
            model: [
                { cx: 6, cy: 6 },
                { cx: chassisFrame.width - 6, cy: 6 },
                { cx: 6, cy: chassisFrame.height - 6 },
                { cx: chassisFrame.width - 6, cy: chassisFrame.height - 6 }
            ]

            delegate: Item {
                x: modelData.cx - 3
                y: modelData.cy - 3
                width: 6
                height: 6

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: "#464e5a"
                    border.color: "#1e2228"
                    border.width: 0.8

                    // Inner slot / hex core
                    Rectangle {
                        anchors.centerIn: parent
                        width: 2.2
                        height: 2.2
                        radius: 1.1
                        color: "#8c96a5"
                    }
                }
            }
        }
    }

    // ========================================================================
    // TILES GRID CONTAINER: Dynamic Alarm Matrix Windows
    // ========================================================================
    Item {
        id: gridContainer
        anchors.fill: parent
        anchors.margins: root.panelMargin

        readonly property real tileWidth: Math.max(20.0, (width - (Math.max(1, root.columns) - 1) * root.tileSpacing) / Math.max(1, root.columns))
        readonly property real tileHeight: Math.max(15.0, (height - (Math.max(1, root.rows) - 1) * root.tileSpacing) / Math.max(1, root.rows))

        Repeater {
            model: tilesModel

            delegate: Item {
                id: tileDelegate
                readonly property int tileRow: Math.floor(index / root.columns)
                readonly property int tileCol: index % root.columns

                x: tileCol * (gridContainer.tileWidth + root.tileSpacing)
                y: tileRow * (gridContainer.tileHeight + root.tileSpacing)
                width: gridContainer.tileWidth
                height: gridContainer.tileHeight

                // Determine if this tile is currently illuminated
                readonly property bool isLit: {
                    if (root.lampTestActive) return true
                    if (model.state === AnnunciatorPanel.AlarmState.Normal) return false
                    if (model.state === AnnunciatorPanel.AlarmState.Unacknowledged) return root._fastFlashPhase
                    if (model.state === AnnunciatorPanel.AlarmState.Acknowledged) return true
                    if (model.state === AnnunciatorPanel.AlarmState.Ringback) return root._slowFlashPhase
                    return false
                }

                readonly property color activeColor: root.colorForSeverity(model.severity, isLit)

                // Sunk Cell Channel Bezel Frame
                Rectangle {
                    x: -1.5
                    y: -1.5
                    width: parent.width + 3.0
                    height: parent.height + 3.0
                    radius: 2.0
                    color: "transparent"
                    border.color: Qt.rgba(0.06, 0.08, 0.11, 0.86)
                    border.width: 1.0
                    z: 0
                }

                // Acrylic Faceplate Lens
                Rectangle {
                    id: faceplate
                    anchors.fill: parent
                    radius: 2.5
                    z: 1
                    color: tileDelegate.activeColor
                    border.color: tileDelegate.isLit ? Qt.lighter(tileDelegate.activeColor, 1.50) : Qt.darker(root.gridColor, 1.3)
                    border.width: tileDelegate.isLit ? 1.4 : 1.0

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: tileDelegate.isLit ? Qt.lighter(tileDelegate.activeColor, 1.30) : Qt.lighter(tileDelegate.activeColor, 1.20)
                        }
                        GradientStop {
                            position: 0.5
                            color: tileDelegate.activeColor
                        }
                        GradientStop {
                            position: 1.0
                            color: tileDelegate.isLit ? Qt.darker(tileDelegate.activeColor, 1.20) : Qt.darker(tileDelegate.activeColor, 1.40)
                        }
                    }

                    // Acrylic Glass Top Gloss Reflection
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1.0
                        height: Math.max(0, parent.height * 0.42)
                        radius: 2.0
                        visible: parent.height > 18.0

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(1.0, 1.0, 1.0, tileDelegate.isLit ? 0.35 : 0.14)
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(1.0, 1.0, 1.0, tileDelegate.isLit ? 0.06 : 0.02)
                            }
                        }
                    }

                    // Engraved Legend Text with subtle Drop Shadow when lit
                    Text {
                        id: shadowText
                        anchors.fill: parent
                        anchors.margins: 4.0
                        anchors.topMargin: 4.8
                        anchors.leftMargin: 4.6
                        text: model.text
                        font.bold: true
                        font.pointSize: Math.max(7, Math.min(13, Math.floor(parent.height * 0.22)))
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Qt.rgba(0.04, 0.04, 0.06, 0.55)
                        visible: tileDelegate.isLit
                    }

                    Text {
                        id: legendText
                        anchors.fill: parent
                        anchors.margins: 4.0
                        text: model.text
                        font.bold: true
                        font.pointSize: Math.max(7, Math.min(13, Math.floor(parent.height * 0.22)))
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: tileDelegate.isLit ? root.textColor : Qt.rgba(root.textColor.r * 0.5, root.textColor.g * 0.5, root.textColor.b * 0.5, 0.75)
                    }

                    // Interactive Touch / Click Area
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (model.state === AnnunciatorPanel.AlarmState.Unacknowledged || model.state === AnnunciatorPanel.AlarmState.Ringback) ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            root.tileClicked(index)
                            if (model.state === AnnunciatorPanel.AlarmState.Unacknowledged) {
                                root.acknowledge(index)
                            } else if (model.state === AnnunciatorPanel.AlarmState.Ringback) {
                                root.reset(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
