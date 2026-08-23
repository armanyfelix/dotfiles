pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kitemmodels as KItemModels
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "../code/animation.js" as Animation
import "../code/components.js" as Components
import "../code/sensors.js" as SensorSelection

PlasmoidItem {
    id: root

    readonly property real defaultSmoothing: 0.4
    readonly property bool vertical:
        Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var panelComponents: Plasmoid.configuration.componentConfigVersion < 1
        ? Components.migrateLegacy(Plasmoid.configuration)
        : Components.normalize(Plasmoid.configuration.components)
    readonly property int componentSpacing: Math.max(
        0, Math.min(24, Number(Plasmoid.configuration.indicatorSpacing))
    )
    readonly property var runnerComponent: Components.find(
        panelComponents, "runner"
    )
    readonly property var memoryComponent: Components.find(
        panelComponents, "memory"
    )
    readonly property var diskComponent: Components.find(
        panelComponents, "disk"
    )
    readonly property var networkComponent: Components.find(
        panelComponents, "network"
    )
    readonly property var gpuComponent: Components.find(panelComponents, "gpu")
    readonly property var vramComponent: Components.find(panelComponents, "vram")
    readonly property var diskIoComponent: Components.find(
        panelComponents, "diskio"
    )
    readonly property var codexComponent: Components.find(
        panelComponents, "codex"
    )
    readonly property var claudeComponent: Components.find(
        panelComponents, "claude"
    )
    readonly property bool cpuTemperatureEnabled: runnerComponent
        && Boolean(runnerComponent.settings.showCpuTemperature)
    readonly property bool gpuTemperatureEnabled: gpuComponent
        && Boolean(gpuComponent.settings.showGpuTemperature)

    property real smoothedCpu: 0
    property real cpuUsage: 0
    property bool sensorReady: false
    property string cpuTemperatureSensorId: ""
    property real cpuTemperature: 0
    property bool temperatureReady: false
    property string gpuTemperatureSensorId: ""

    function updateCpu(rawValue) {
        const value = Number(rawValue);
        if (!Number.isFinite(value)) {
            return;
        }
        const bounded = Animation.clamp(value, 0, 100);
        cpuUsage = bounded;
        if (!sensorReady) {
            smoothedCpu = bounded;
            sensorReady = true;
            return;
        }
        smoothedCpu = Animation.smooth(smoothedCpu, bounded, defaultSmoothing);
    }

    function updateCpuTemperature(rawValue) {
        const value = Number(rawValue);
        if (!Number.isFinite(value)) {
            temperatureReady = false;
            return;
        }
        cpuTemperature = value;
        temperatureReady = true;
    }

    function discoverCpuTemperatureSensor() {
        let bestId = "";
        let bestScore = -1;
        for (let row = 0; row < flatSensorModel.rowCount(); ++row) {
            const index = flatSensorModel.index(row, 0);
            const sensorId = String(flatSensorModel.data(
                index, Sensors.SensorTreeModel.SensorId
            ) || "");
            if (sensorId.length === 0) continue;
            const name = String(flatSensorModel.data(index, Qt.DisplayRole) || "");
            const score = SensorSelection.cpuTemperatureSensorScore(
                sensorId, name
            );
            if (score > bestScore) {
                bestScore = score;
                bestId = sensorId;
            }
        }
        cpuTemperatureSensorId = bestId;
        if (bestId.length === 0) temperatureReady = false;
    }

    function discoverGpuTemperatureSensor() {
        let bestId = "";
        let bestScore = -1;
        for (let row = 0; row < flatSensorModel.rowCount(); ++row) {
            const index = flatSensorModel.index(row, 0);
            const sensorId = String(flatSensorModel.data(
                index, Sensors.SensorTreeModel.SensorId
            ) || "");
            if (sensorId.length === 0) continue;
            const name = String(flatSensorModel.data(index, Qt.DisplayRole) || "");
            const score = SensorSelection.gpuTemperatureSensorScore(
                sensorId, name
            );
            if (score > bestScore) {
                bestScore = score;
                bestId = sensorId;
            }
        }
        gpuTemperatureSensorId = bestId;
    }

    function discoverTemperatureSensors() {
        if (cpuTemperatureEnabled) discoverCpuTemperatureSensor();
        if (gpuTemperatureEnabled) discoverGpuTemperatureSensor();
    }

    function migrateConfiguration() {
        if (Plasmoid.configuration.componentConfigVersion >= 7) {
            return;
        }
        const value = Plasmoid.configuration.componentConfigVersion < 1
            ? Components.migrateLegacy(Plasmoid.configuration)
            : Components.normalize(Plasmoid.configuration.components);
        Plasmoid.configuration.components = Components.serialize(
            value
        );
        Plasmoid.configuration.componentConfigVersion = 7;
    }

    function visiblePanelComponentCount() {
        let count = 0;
        for (let index = 0; index < panelComponents.length; ++index) {
            ++count;
        }
        return count;
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.title: i18n("RunCat")
    // Component items provide their own tooltips. Keep the shell-level
    // tooltip empty so it does not overlap them.
    toolTipMainText: ""
    toolTipSubText: ""
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        id: representation

        readonly property int visibleComponentCount:
            root.visiblePanelComponentCount()
        readonly property real naturalHeight: Kirigami.Units.iconSizes.medium
        readonly property real minimumHeight: Kirigami.Units.iconSizes.small

        implicitWidth: componentRow.implicitWidth
        implicitHeight: naturalHeight
        Layout.minimumWidth: Math.max(1, componentRow.implicitWidth
            * minimumHeight / naturalHeight)
        Layout.minimumHeight: minimumHeight
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        Row {
            id: componentRow

            anchors.fill: parent
            spacing: representation.visibleComponentCount > 1
                ? root.componentSpacing : 0

            Repeater {
                model: root.panelComponents

                PanelComponent {
                    required property var modelData

                    componentType: String(modelData.type)
                    componentSettings: modelData.settings || ({})
                    cpuUsage: root.cpuUsage
                    smoothedCpu: root.smoothedCpu
                    sensorReady: root.sensorReady
                    cpuTemperature: root.cpuTemperature
                    temperatureReady: root.temperatureReady
                    metrics: metricsProvider
                    vertical: root.vertical
                    contentSpacing: root.componentSpacing
                    width: implicitWidth
                    height: componentRow.height
                }
            }
        }
    }

    // PlasmoidItem expects both representation slots to exist. This empty
    // representation is never activated; it only keeps Plasma's compact
    // representation layout valid after a shell restart.
    fullRepresentation: Item {}

    // Keep subscriptions outside compactRepresentation. Plasma may recreate
    // that representation while the settings dialog is open; the provider
    // must outlive those display-only items so their teardown cannot cancel
    // active sensor subscriptions.
    MetricsProvider {
        id: metricsProvider

        memoryEnabled: Boolean(root.memoryComponent)
        diskEnabled: Boolean(root.diskComponent)
        networkEnabled: Boolean(root.networkComponent)
        gpuEnabled: Boolean(root.gpuComponent)
        gpuTemperatureEnabled: root.gpuTemperatureEnabled
        vramEnabled: Boolean(root.vramComponent)
        diskIoEnabled: Boolean(root.diskIoComponent)
        gpuTemperatureSensorId: root.gpuTemperatureSensorId
        tokenUsageEnabled: Boolean(root.codexComponent)
            || Boolean(root.claudeComponent)
        claudeContextWindow: root.claudeComponent
            ? Number(root.claudeComponent.settings.contextWindow || 200000)
            : 200000
    }

    Sensors.SensorTreeModel { id: sensorTreeModel }

    KItemModels.KDescendantsProxyModel {
        id: flatSensorModel
        model: sensorTreeModel
        expandsByDefault: true
    }

    Timer {
        id: sensorDiscoveryTimer
        interval: 100
        onTriggered: root.discoverTemperatureSensors()
    }

    Connections {
        target: flatSensorModel
        enabled: root.cpuTemperatureEnabled || root.gpuTemperatureEnabled
        function onRowsInserted() { sensorDiscoveryTimer.restart(); }
        function onModelReset() { sensorDiscoveryTimer.restart(); }
        function onLayoutChanged() { sensorDiscoveryTimer.restart(); }
    }

    onCpuTemperatureEnabledChanged: {
        if (cpuTemperatureEnabled) {
            sensorDiscoveryTimer.restart();
        } else {
            cpuTemperatureSensorId = "";
            temperatureReady = false;
        }
    }

    onGpuTemperatureEnabledChanged: {
        if (gpuTemperatureEnabled) {
            sensorDiscoveryTimer.restart();
        } else {
            gpuTemperatureSensorId = "";
        }
    }

    Component.onCompleted: {
        migrateConfiguration();
        if (cpuTemperatureEnabled || gpuTemperatureEnabled) {
            sensorDiscoveryTimer.start();
        }
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        enabled: root.visible
        updateRateLimit: 1000
        onValueChanged: root.updateCpu(value)
    }

    Sensors.Sensor {
        id: cpuTemperatureSensor
        sensorId: root.cpuTemperatureSensorId
        enabled: root.visible && root.cpuTemperatureEnabled
            && sensorId.length > 0
        updateRateLimit: 1000
        onValueChanged: root.updateCpuTemperature(value)
        onStatusChanged: {
            if (status !== Sensors.Sensor.Ready) root.temperatureReady = false;
        }
    }
}
