pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects

import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts

Item {
    id: root

    required property real size
    required property url iconSource
    required property string title
    required property real percent
    required property bool available
    required property color color
    required property int todayTokens
    required property int contextTokens
    required property int contextWindow
    required property string updatedAt

    width: size
    height: size
    Accessible.name: toolTipText

    readonly property string toolTipText: available
        ? i18n(
            "%1\nToday: %2 tokens\nRecent context: %3 / %4 tokens (%5%)\nLast activity: %6",
            title,
            todayTokens,
            contextTokens,
            contextWindow,
            Math.round(percent),
            updatedAt
        )
        : i18n("%1: no local usage data", title)

    Charts.PieChart {
        anchors.fill: parent

        valueSources: Charts.SingleValueSource {
            value: root.percent
        }
        colorSource: Charts.ArraySource {
            array: [root.color]
        }
        nameSource: Charts.ArraySource {
            array: [root.title]
        }
        range.from: 0
        range.to: 100
        range.automatic: false
        thickness: Math.max(2, root.size * 0.12)
        smoothEnds: true
        backgroundColor: Kirigami.ColorUtils.linearInterpolation(
            Kirigami.Theme.backgroundColor,
            Kirigami.Theme.textColor,
            0.16
        )
        opacity: root.available ? 1 : 0.45
    }

    Image {
        anchors.centerIn: parent
        width: Math.round(root.size * 0.42)
        height: width
        source: root.iconSource
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.available ? 1 : 0.45
        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: Kirigami.Theme.textColor
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    QQC2.ToolTip.visible: hoverHandler.hovered
    QQC2.ToolTip.text: root.toolTipText
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
