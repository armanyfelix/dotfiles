pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts

import "../code/value_format.js" as ValueFormat

Item {
    id: root

    required property real ringSize
    required property string title
    required property string iconName
    required property color color
    required property real usage
    required property string usedText
    required property string totalText
    required property bool usageAvailable
    required property bool detailAvailable
    property bool showText: false
    property real spacing: Kirigami.Units.smallSpacing
    property bool firstLineAvailable: detailAvailable
    property bool secondLineAvailable: detailAvailable
    property bool firstLineVisible: true
    property bool secondLineVisible: true
    property real reservedTextWidth: 0
    property color secondLineColor: Kirigami.Theme.textColor
    property real secondLineOpacity: 0.7

    readonly property string shownUsedText: firstLineAvailable
        && usedText.length > 0 ? usedText : i18n("Unavailable")
    readonly property string shownTotalText: secondLineAvailable
        && totalText.length > 0 ? totalText : i18n("Unavailable")
    readonly property string detailText: !detailAvailable
        ? i18n("Unavailable")
        : firstLineVisible && secondLineVisible
            ? i18n("%1 / %2", shownUsedText, shownTotalText)
            : firstLineVisible ? shownUsedText : shownTotalText
    readonly property string accessibleText: usageAvailable
        ? i18n("%1: %2%, %3", title, Math.round(usage), detailText)
        : detailAvailable
            ? i18n("%1: %2", title, detailText)
            : i18n("%1: unavailable", title)
    readonly property real textWidth: reservedTextWidth > 0
        ? reservedTextWidth
        : Math.ceil(valueTextMetrics.advanceWidth)

    implicitWidth: ringSize + (showText ? spacing + textWidth : 0)
    implicitHeight: ringSize
    Accessible.name: accessibleText

    TextMetrics {
        id: valueTextMetrics

        font: ValueFormat.tabularFont(Kirigami.Theme.smallFont)
        text: ValueFormat.widestBinaryText(false)
    }

    Row {
        anchors.fill: parent
        spacing: root.showText ? root.spacing : 0

        Item {
            width: root.ringSize
            height: root.ringSize
            anchors.verticalCenter: parent.verticalCenter

            Charts.PieChart {
                anchors.fill: parent

                valueSources: Charts.SingleValueSource {
                    value: root.usage
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
                thickness: Math.max(2, root.ringSize * 0.12)
                smoothEnds: true
                backgroundColor: Kirigami.ColorUtils.linearInterpolation(
                    Kirigami.Theme.backgroundColor,
                    Kirigami.Theme.textColor,
                    0.16
                )
                opacity: root.usageAvailable ? 1 : 0.45
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.round(root.ringSize * 0.42)
                height: width
                source: root.iconName
                color: Kirigami.Theme.textColor
                opacity: root.usageAvailable ? 1 : 0.45
            }
        }

        Column {
            width: root.showText ? root.textWidth : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            visible: root.showText
                && (root.firstLineVisible || root.secondLineVisible)

            QQC2.Label {
                width: parent.width
                visible: root.firstLineVisible
                font: ValueFormat.tabularFont(Kirigami.Theme.smallFont)
                elide: Text.ElideRight
                text: root.shownUsedText
                horizontalAlignment: Text.AlignLeft
            }

            QQC2.Label {
                width: parent.width
                visible: root.secondLineVisible
                font: ValueFormat.tabularFont(Kirigami.Theme.smallFont)
                elide: Text.ElideRight
                color: root.secondLineColor
                opacity: root.secondLineOpacity
                text: root.shownTotalText
                horizontalAlignment: Text.AlignLeft
            }
        }
    }

    HoverHandler { id: hoverHandler }

    QQC2.ToolTip.visible: hoverHandler.hovered
    QQC2.ToolTip.text: root.accessibleText
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
