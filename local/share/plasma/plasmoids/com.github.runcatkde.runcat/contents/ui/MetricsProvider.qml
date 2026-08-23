pragma ComponentBehavior: Bound

import QtQuick

import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/value_format.js" as ValueFormat

QtObject {
    id: root

    property bool memoryEnabled: false
    property bool diskEnabled: false
    property bool networkEnabled: false
    property bool gpuEnabled: false
    property bool gpuTemperatureEnabled: false
    property bool vramEnabled: false
    property bool diskIoEnabled: false
    property string gpuTemperatureSensorId: ""
    property bool tokenUsageEnabled: false
    property int claudeContextWindow: 200000

    readonly property real memoryUsage: boundedPercent(memoryUsageSensor.value)
    readonly property string memoryUsed: formattedBytes(memoryUsedSensor)
    readonly property string memoryTotal: formattedBytes(memoryTotalSensor)
    readonly property bool memoryUsageAvailable:
        sensorReady(memoryUsageSensor)
        && Number.isFinite(Number(memoryUsageSensor.value))
    readonly property bool memoryDetailAvailable:
        sensorReady(memoryUsedSensor)
        && sensorReady(memoryTotalSensor)
        && memoryUsed.length > 0 && memoryTotal.length > 0

    readonly property real diskUsage: boundedPercent(diskUsageSensor.value)
    readonly property string diskUsed: formattedBytes(diskUsedSensor)
    readonly property string diskTotal: formattedBytes(diskTotalSensor)
    readonly property bool diskUsageAvailable:
        sensorReady(diskUsageSensor)
        && Number.isFinite(Number(diskUsageSensor.value))
    readonly property bool diskDetailAvailable:
        sensorReady(diskUsedSensor)
        && sensorReady(diskTotalSensor)
        && diskUsed.length > 0 && diskTotal.length > 0

    readonly property string downloadRate: formattedRate(downloadSensor)
    readonly property string uploadRate: formattedRate(uploadSensor)
    readonly property bool downloadAvailable: sensorReady(downloadSensor)
        && downloadRate.length > 0
    readonly property bool uploadAvailable: sensorReady(uploadSensor)
        && uploadRate.length > 0

    readonly property real gpuUsage: boundedPercent(gpuUsageSensor.value)
    readonly property bool gpuUsageAvailable: sensorReady(gpuUsageSensor)
        && Number.isFinite(Number(gpuUsageSensor.value))
    readonly property real gpuTemperature: Number(gpuTemperatureSensor.value)
    readonly property bool gpuTemperatureAvailable:
        sensorReady(gpuTemperatureSensor)
        && Number.isFinite(gpuTemperature)

    readonly property real vramUsedValue: Number(vramUsedSensor.value)
    readonly property real vramTotalValue: Number(vramTotalSensor.value)
    readonly property real vramUsage: vramTotalValue > 0
        ? boundedPercent(vramUsedValue / vramTotalValue * 100) : 0
    readonly property string vramUsed: formattedBytes(vramUsedSensor)
    readonly property string vramTotal: formattedBytes(vramTotalSensor)
    readonly property bool vramUsageAvailable: sensorReady(vramUsedSensor)
        && sensorReady(vramTotalSensor)
        && Number.isFinite(vramUsedValue) && Number.isFinite(vramTotalValue)
        && vramTotalValue > 0
    readonly property bool vramDetailAvailable: vramUsageAvailable
        && vramUsed.length > 0 && vramTotal.length > 0

    readonly property string diskReadRate: formattedRate(diskReadSensor)
    readonly property string diskWriteRate: formattedRate(diskWriteSensor)
    readonly property bool diskReadAvailable: sensorReady(diskReadSensor)
        && diskReadRate.length > 0
    readonly property bool diskWriteAvailable: sensorReady(diskWriteSensor)
        && diskWriteRate.length > 0

    property int codexTodayTokens: 0
    property int codexContextTokens: 0
    property int codexContextWindow: 0
    property int claudeTodayTokens: 0
    property int claudeContextTokens: 0
    // Treat the initial zero values as valid while the first asynchronous
    // token-usage query is still running. A completed query can still mark a
    // provider unavailable when no local usage data can be read.
    property bool codexAvailable: true
    property bool claudeAvailable: true
    property string codexUpdatedAt: ""
    property string claudeUpdatedAt: ""

    readonly property string tokenScriptPath: decodeURIComponent(
        Qt.resolvedUrl("../code/token_usage.py").toString()
            .replace(/^file:\/\//, "")
    )
    readonly property string tokenCommand: "/usr/bin/python3 "
        + shellQuote(tokenScriptPath)
        + " --claude-context-window " + claudeContextWindow

    function sensorReady(sensor) {
        return sensor.status === Sensors.Sensor.Ready;
    }

    function boundedPercent(rawValue) {
        const value = Number(rawValue);
        return Number.isFinite(value)
            ? Math.max(0, Math.min(100, value)) : 0;
    }

    function formattedBytes(sensor) {
        const value = Number(sensor.value);
        return sensorReady(sensor) && Number.isFinite(value)
            ? ValueFormat.formatBytes(value) : "";
    }

    function formattedRate(sensor) {
        const value = Number(sensor.value);
        return sensorReady(sensor) && Number.isFinite(value)
            ? ValueFormat.formatRate(value) : "";
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'";
    }

    function updateTokenUsage(rawOutput) {
        try {
            const value = JSON.parse(String(rawOutput).trim());
            const codex = value.codex || {};
            const claude = value.claude || {};
            codexAvailable = Boolean(codex.available);
            codexTodayTokens = Number(codex.todayTokens) || 0;
            codexContextTokens = Number(codex.contextTokens) || 0;
            codexContextWindow = Number(codex.contextWindow) || 0;
            codexUpdatedAt = String(codex.updatedAt || "");
            claudeAvailable = Boolean(claude.available);
            claudeTodayTokens = Number(claude.todayTokens) || 0;
            claudeContextTokens = Number(claude.contextTokens) || 0;
            claudeUpdatedAt = String(claude.updatedAt || "");
        } catch (error) {
            console.warn("RunCat could not parse token usage:", error);
        }
    }

    property Sensors.Sensor memoryUsageSensor: Sensors.Sensor {
        sensorId: "memory/physical/usedPercent"
        enabled: root.memoryEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor memoryUsedSensor: Sensors.Sensor {
        sensorId: "memory/physical/used"
        enabled: root.memoryEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor memoryTotalSensor: Sensors.Sensor {
        sensorId: "memory/physical/total"
        enabled: root.memoryEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor diskUsageSensor: Sensors.Sensor {
        sensorId: "disk/all/usedPercent"
        enabled: root.diskEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor diskUsedSensor: Sensors.Sensor {
        sensorId: "disk/all/used"
        enabled: root.diskEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor diskTotalSensor: Sensors.Sensor {
        sensorId: "disk/all/total"
        enabled: root.diskEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor downloadSensor: Sensors.Sensor {
        sensorId: "network/all/download"
        enabled: root.networkEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor uploadSensor: Sensors.Sensor {
        sensorId: "network/all/upload"
        enabled: root.networkEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor gpuUsageSensor: Sensors.Sensor {
        sensorId: "gpu/all/usage"
        enabled: root.gpuEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor gpuTemperatureSensor: Sensors.Sensor {
        sensorId: root.gpuTemperatureSensorId
        enabled: root.gpuTemperatureEnabled && sensorId.length > 0
        updateRateLimit: 1000
    }

    property Sensors.Sensor vramUsedSensor: Sensors.Sensor {
        sensorId: "gpu/all/usedVram"
        enabled: root.vramEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor vramTotalSensor: Sensors.Sensor {
        sensorId: "gpu/all/totalVram"
        enabled: root.vramEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor diskReadSensor: Sensors.Sensor {
        sensorId: "disk/all/read"
        enabled: root.diskIoEnabled
        updateRateLimit: 1000
    }

    property Sensors.Sensor diskWriteSensor: Sensors.Sensor {
        sensorId: "disk/all/write"
        enabled: root.diskIoEnabled
        updateRateLimit: 1000
    }

    property Plasma5Support.DataSource tokenSource:
        Plasma5Support.DataSource {
            engine: "executable"
            connectedSources: root.tokenUsageEnabled ? [root.tokenCommand] : []
            interval: 30000

            onNewData: function(sourceName, data) {
                if (sourceName === root.tokenCommand
                        && Number(data["exit code"]) === 0) {
                    root.updateTokenUsage(data["stdout"]);
                }
            }
        }
}
