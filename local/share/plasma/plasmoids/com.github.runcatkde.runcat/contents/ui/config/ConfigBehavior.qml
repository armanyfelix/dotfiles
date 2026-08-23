pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import "../../code/components.js" as Components
import "../../code/runners.js" as RunnerSelection

// This is a list-based settings page. ScrollViewKCM gives the ListView one
// bounded viewport and keeps the controls below it in a separate footer.
KCM.ScrollViewKCM {
    id: root

    property string cfg_components
    property string cfg_componentsDefault
    property int cfg_componentConfigVersion
    property int cfg_componentConfigVersionDefault

    // Kept while upgrading existing installations to the component model.
    property bool cfg_useIdleFrame
    property bool cfg_useIdleFrameDefault
    property int cfg_idleThreshold
    property int cfg_idleThresholdDefault
    property string cfg_runner
    property string cfg_runnerDefault
    property int cfg_speedPercent
    property int cfg_speedPercentDefault
    property bool cfg_flipHorizontally
    property bool cfg_flipHorizontallyDefault
    property bool cfg_showCpuUsage
    property bool cfg_showCpuUsageDefault
    property bool cfg_showCpuTemperature
    property bool cfg_showCpuTemperatureDefault
    property bool cfg_showMemoryUsage
    property bool cfg_showMemoryUsageDefault
    property bool cfg_showDiskUsage
    property bool cfg_showDiskUsageDefault
    property bool cfg_showNetworkRate
    property bool cfg_showNetworkRateDefault
    property bool cfg_showCodexTokenUsage
    property bool cfg_showCodexTokenUsageDefault
    property bool cfg_showClaudeTokenUsage
    property bool cfg_showClaudeTokenUsageDefault
    property bool cfg_showDailyTokenUsage
    property bool cfg_showDailyTokenUsageDefault
    property int cfg_claudeContextWindow
    property int cfg_claudeContextWindowDefault
    property int cfg_indicatorSpacing
    property int cfg_indicatorSpacingDefault
    property bool cfg_reverseSpeed
    property bool cfg_reverseSpeedDefault

    readonly property var runnerIds: RunnerSelection.availableRunnerIds()
    property bool initializing: true

    function titleFor(type) {
        switch (type) {
        case "runner": return i18n("Runner");
        case "memory": return i18n("Memory usage");
        case "disk": return i18n("Disk usage");
        case "network": return i18n("Network rate");
        case "gpu": return i18n("GPU usage");
        case "vram": return i18n("Video memory usage");
        case "diskio": return i18n("Disk I/O");
        case "codex": return i18n("Codex usage");
        case "claude": return i18n("Claude Code usage");
        }
        return type;
    }

    function descriptionFor(type) {
        switch (type) {
        case "runner": return i18n("Animated runner driven by CPU load");
        case "memory": return i18n("Physical memory usage ring");
        case "disk": return i18n("Combined disk usage ring");
        case "network": return i18n("Download and upload rates");
        case "gpu": return i18n("GPU load and temperature");
        case "vram": return i18n("Used and total video memory");
        case "diskio": return i18n("Disk read and write rates");
        case "codex": return i18n("Codex context and daily tokens");
        case "claude": return i18n("Claude Code context and daily tokens");
        }
        return "";
    }

    function iconFor(type) {
        switch (type) {
        case "runner": return "run-build";
        case "memory": return "media-flash-symbolic";
        case "disk": return "drive-harddisk-symbolic";
        case "network": return "network-wired-symbolic";
        case "gpu": return "video-display-symbolic";
        case "vram": return "video-display-symbolic";
        case "diskio": return "drive-harddisk-symbolic";
        case "codex": return "applications-science-symbolic";
        case "claude": return "applications-science-symbolic";
        }
        return "widget-alternatives";
    }

    function containsType(type) {
        for (let index = 0; index < componentModel.count; ++index) {
            if (componentModel.get(index).componentType === type) {
                return true;
            }
        }
        return false;
    }

    function loadModel() {
        let value;
        const migratingLegacy = cfg_componentConfigVersion < 1;
        if (migratingLegacy) {
            value = Components.migrateLegacy({
                runner: cfg_runner,
                useIdleFrame: cfg_useIdleFrame,
                idleThreshold: cfg_idleThreshold,
                speedPercent: cfg_speedPercent,
                flipHorizontally: cfg_flipHorizontally,
                reverseSpeed: cfg_reverseSpeed,
                showCpuUsage: cfg_showCpuUsage,
                showCpuTemperature: cfg_showCpuTemperature,
                showMemoryUsage: cfg_showMemoryUsage,
                showDiskUsage: cfg_showDiskUsage,
                showNetworkRate: cfg_showNetworkRate,
                showCodexTokenUsage: cfg_showCodexTokenUsage,
                showClaudeTokenUsage: cfg_showClaudeTokenUsage,
                showDailyTokenUsage: cfg_showDailyTokenUsage,
                claudeContextWindow: cfg_claudeContextWindow
            });
        } else {
            value = Components.normalize(cfg_components);
        }
        const serialized = Components.serialize(value);

        componentModel.clear();
        for (let index = 0; index < value.length; ++index) {
            componentModel.append({
                componentType: value[index].type,
                settingsJson: JSON.stringify(value[index].settings)
            });
        }
        initializing = false;
        if (cfg_components !== serialized) {
            cfg_components = serialized;
        }
        if (cfg_componentConfigVersion !== 7) {
            cfg_componentConfigVersion = 7;
        }
    }

    function replaceModel(value) {
        const serialized = Components.serialize(value);
        if (serialized === modelJson()) {
            return;
        }
        initializing = true;
        const components = Components.normalize(serialized);
        componentModel.clear();
        for (let index = 0; index < components.length; ++index) {
            componentModel.append({
                componentType: components[index].type,
                settingsJson: JSON.stringify(components[index].settings)
            });
        }
        initializing = false;
    }

    function modelJson() {
        const value = [];
        for (let index = 0; index < componentModel.count; ++index) {
            const item = componentModel.get(index);
            let settings = {};
            try {
                settings = JSON.parse(item.settingsJson);
            } catch (error) {
                settings = {};
            }
            value.push({type: item.componentType, settings: settings});
        }
        return Components.serialize(value);
    }

    function saveModel() {
        if (initializing) {
            return;
        }
        const serialized = modelJson();
        if (cfg_components !== serialized) {
            cfg_components = serialized;
        }
        if (cfg_componentConfigVersion !== 7) {
            cfg_componentConfigVersion = 7;
        }
    }

    function addComponent(type) {
        if (containsType(type)) {
            return;
        }
        componentModel.append({
            componentType: type,
            settingsJson: JSON.stringify(Components.defaultSettings(type))
        });
        saveModel();
    }

    function removeComponent(index) {
        if (componentModel.count <= 1) {
            return;
        }
        componentModel.remove(index);
        saveModel();
    }

    function moveComponent(from, to) {
        if (from < 0 || to < 0 || from === to
                || from >= componentModel.count || to >= componentModel.count) {
            return;
        }
        componentModel.move(from, to, 1);
        saveModel();
    }

    function updateSetting(index, key, value) {
        let settings = {};
        try {
            settings = JSON.parse(componentModel.get(index).settingsJson);
        } catch (error) {
            settings = {};
        }
        settings[key] = value;
        componentModel.setProperty(index, "settingsJson", JSON.stringify(settings));
        saveModel();
    }

    Component.onCompleted: loadModel()
    onCfg_componentsChanged: {
        if (!initializing) {
            replaceModel(cfg_components);
        }
    }

    ListModel {
        id: componentModel
    }

    header: Kirigami.InlineMessage {
        visible: componentModel.count === 0
        type: Kirigami.MessageType.Information
        text: i18n("No panel components are enabled. Add one below.")
    }

    view: ListView {
        id: componentList

        spacing: Kirigami.Units.smallSpacing
        model: componentModel
        leftMargin: Kirigami.Units.smallSpacing
        rightMargin: Kirigami.Units.smallSpacing
        topMargin: Kirigami.Units.smallSpacing
        bottomMargin: Kirigami.Units.smallSpacing

            delegate: Kirigami.AbstractCard {
                id: card

                required property int index
                required property string componentType
                required property string settingsJson
                readonly property var settings: {
                    try {
                        return JSON.parse(settingsJson);
                    } catch (error) {
                        return {};
                    }
                }

                contentItem: ColumnLayout {
                    id: contentColumn

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            source: root.iconFor(card.componentType)
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: implicitWidth
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                text: root.titleFor(card.componentType)
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.descriptionFor(card.componentType)
                                opacity: 0.7
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToolButton {
                            icon.name: "go-up-symbolic"
                            text: i18n("Move up")
                            display: AbstractButton.IconOnly
                            enabled: card.index > 0
                            onClicked: root.moveComponent(card.index, card.index - 1)
                            ToolTip.text: text
                            ToolTip.visible: hovered
                        }

                        ToolButton {
                            icon.name: "go-down-symbolic"
                            text: i18n("Move down")
                            display: AbstractButton.IconOnly
                            enabled: card.index + 1 < componentModel.count
                            onClicked: root.moveComponent(card.index, card.index + 1)
                            ToolTip.text: text
                            ToolTip.visible: hovered
                        }

                        ToolButton {
                            icon.name: "edit-delete-symbolic"
                            text: i18n("Remove")
                            display: AbstractButton.IconOnly
                            enabled: componentModel.count > 1
                            onClicked: root.removeComponent(card.index)
                            ToolTip.text: text
                            ToolTip.visible: hovered
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        visible: card.componentType === "runner"

                        Label { text: i18n("Runner:") }
                        ComboBox {
                            Layout.fillWidth: true
                            model: [
                                i18n("Cat"), i18n("Dog"), i18n("Slime"),
                                i18n("Drop"), i18n("Coffee"),
                                i18n("Newton's cradle"), i18n("Engine"),
                                i18n("Mochi")
                            ]
                            currentIndex: Math.max(0,
                                root.runnerIds.indexOf(card.settings.runner))
                            onActivated: root.updateSetting(
                                card.index, "runner", root.runnerIds[currentIndex]
                            )
                        }

                        Label { text: i18n("Running speed:") }
                        SpinBox {
                            from: 25
                            to: 200
                            stepSize: 25
                            value: Number(card.settings.speedPercent || 100)
                            textFromValue: function(value) { return i18n("%1%", value); }
                            valueFromText: function(text) { return parseInt(text, 10); }
                            onValueModified: root.updateSetting(
                                card.index, "speedPercent", value
                            )
                        }

                        Label { text: i18n("Idle threshold:") }
                        SpinBox {
                            from: 0
                            to: 25
                            value: Number(card.settings.idleThreshold || 0)
                            enabled: restCheck.checked
                            textFromValue: function(value) { return i18n("%1%", value); }
                            valueFromText: function(text) { return parseInt(text, 10); }
                            onValueModified: root.updateSetting(
                                card.index, "idleThreshold", value
                            )
                        }

                        Item { Layout.preferredWidth: 1; Layout.preferredHeight: 1 }
                        ColumnLayout {
                            CheckBox {
                                id: restCheck
                                text: i18n("Rest when the system is idle")
                                checked: Boolean(card.settings.useIdleFrame)
                                onClicked: root.updateSetting(
                                    card.index, "useIdleFrame", checked
                                )
                            }
                            CheckBox {
                                text: i18n("Flip runner horizontally")
                                checked: Boolean(card.settings.flipHorizontally)
                                onClicked: root.updateSetting(
                                    card.index, "flipHorizontally", checked
                                )
                            }
                            CheckBox {
                                text: i18n("Reverse speed response to CPU usage")
                                checked: Boolean(card.settings.reverseSpeed)
                                onClicked: root.updateSetting(
                                    card.index, "reverseSpeed", checked
                                )
                            }
                            CheckBox {
                                text: i18n("Show CPU usage percentage")
                                checked: Boolean(card.settings.showCpuUsage)
                                onClicked: root.updateSetting(
                                    card.index, "showCpuUsage", checked
                                )
                            }
                            CheckBox {
                                id: temperatureCheck
                                text: i18n("Show CPU temperature")
                                checked: Boolean(
                                    card.settings.showCpuTemperature
                                )
                                onClicked: root.updateSetting(
                                    card.index, "showCpuTemperature", checked
                                )
                            }
                        }

                        Label { text: i18n("Temperature unit:") }
                        ComboBox {
                            enabled: temperatureCheck.checked
                            model: [i18n("Celsius (°C)"), i18n("Fahrenheit (°F)")]
                            currentIndex: card.settings.temperatureUnit
                                === "fahrenheit" ? 1 : 0
                            onActivated: root.updateSetting(
                                card.index,
                                "temperatureUnit",
                                currentIndex === 1 ? "fahrenheit" : "celsius"
                            )
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        visible: card.componentType === "claude"

                        Label { text: i18n("Context window:") }
                        SpinBox {
                            from: 10000
                            to: 2000000
                            stepSize: 10000
                            value: Number(
                                card.settings.contextWindow || 200000
                            )
                            textFromValue: function(value) {
                                return i18n(
                                    "%1K tokens", Math.round(value / 1000)
                                );
                            }
                            valueFromText: function(text) {
                                return Math.max(
                                    10000, parseInt(text, 10) * 1000
                                );
                            }
                            onValueModified: root.updateSetting(
                                card.index, "contextWindow", value
                            )
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        visible: card.componentType === "gpu"

                        Label { text: i18n("Show:") }
                        ColumnLayout {
                            CheckBox {
                                text: i18n("GPU usage percentage")
                                checked: Boolean(card.settings.showText)
                                onClicked: root.updateSetting(
                                    card.index, "showText", checked
                                )
                            }
                            CheckBox {
                                id: gpuTemperatureCheck
                                text: i18n("GPU temperature")
                                checked: Boolean(
                                    card.settings.showGpuTemperature
                                )
                                onClicked: root.updateSetting(
                                    card.index, "showGpuTemperature", checked
                                )
                            }
                        }

                        Label { text: i18n("Temperature unit:") }
                        ComboBox {
                            enabled: gpuTemperatureCheck.checked
                            model: [i18n("Celsius (°C)"), i18n("Fahrenheit (°F)")]
                            currentIndex: card.settings.temperatureUnit
                                === "fahrenheit" ? 1 : 0
                            onActivated: root.updateSetting(
                                card.index,
                                "temperatureUnit",
                                currentIndex === 1 ? "fahrenheit" : "celsius"
                            )
                        }
                    }

                    CheckBox {
                        Layout.fillWidth: true
                        visible: card.componentType === "memory"
                            || card.componentType === "disk"
                            || card.componentType === "vram"
                            || card.componentType === "codex"
                            || card.componentType === "claude"
                        text: card.componentType === "codex"
                                || card.componentType === "claude"
                            ? i18n("Show context and today's tokens next to the ring")
                            : i18n("Show used and total capacity next to the ring")
                        checked: Boolean(card.settings.showText)
                        onClicked: root.updateSetting(
                            card.index, "showText", checked
                        )
                    }
                }
            }
    }

    footer: RowLayout {
        spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18n("Component spacing:")
            }

            SpinBox {
                from: 0
                to: 24
                value: root.cfg_indicatorSpacing
                textFromValue: function(value) {
                    return i18n("%1 px", value);
                }
                valueFromText: function(text) {
                    return parseInt(text, 10);
                }
                onValueModified: root.cfg_indicatorSpacing = value
            }

            Item { Layout.fillWidth: true }

            Button {
                text: i18n("Add component…")
                icon.name: "list-add-symbolic"
                onClicked: addMenu.open()

                Menu {
                    id: addMenu

                    Instantiator {
                        model: Components.componentTypes

                        delegate: MenuItem {
                            required property string modelData
                            text: root.titleFor(modelData)
                            icon.name: root.iconFor(modelData)
                            enabled: !root.containsType(modelData)
                            onTriggered: root.addComponent(modelData)
                        }

                        onObjectAdded: function(index, object) {
                            addMenu.insertItem(index, object);
                        }
                        onObjectRemoved: function(index, object) {
                            addMenu.removeItem(object);
                        }
                    }
                }
            }
    }
}
