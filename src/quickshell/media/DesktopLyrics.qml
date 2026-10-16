import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../singletons/system"
import "../singletons/theme"
import "../"

PanelWindow {
    id: root
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    property var defaultSettings: ({
        "enabled": true,
        "mode": "random",
        "x": 100,
        "y": 100,
        "fontFamily": "Georgia, serif",
        "fontSize": 52,
        "fontWeight": "Black",
        "fontItalic": false,
        "color": "#ffffff",
        "opacity": 85,
        "alignment": "center",
        "maxLines": 2,
        "shadow": true,
        "showTestLyric": false
    })

    property var lyricsSettings: {
        let s = (typeof Config !== "undefined" && Config.rawSettings) ? Config.rawSettings["desktopLyrics"] : undefined;
        if (s !== undefined && s !== null) return s;
        if (typeof Config !== "undefined" && typeof Config.getSetting === "function") {
            return Config.getSetting("desktopLyrics", defaultSettings);
        }
        return defaultSettings;
    }

    property bool enabled: {
        if (lyricsSettings && lyricsSettings.enabled !== undefined) return Boolean(lyricsSettings.enabled);
        let gen = (typeof Config !== "undefined" && Config.rawSettings) ? Config.rawSettings["general"] : undefined;
        if (gen && gen.desktopLyrics !== undefined) return Boolean(gen.desktopLyrics);
        return true;
    }

    property string mode: (lyricsSettings && lyricsSettings.mode) ? lyricsSettings.mode : "random"
    property string fontFamily: (lyricsSettings && lyricsSettings.fontFamily) ? lyricsSettings.fontFamily : "Georgia, serif"
    property int fontSize: (lyricsSettings && lyricsSettings.fontSize) ? parseInt(lyricsSettings.fontSize) : 52
    property int fontWeight: {
        let w = (lyricsSettings && lyricsSettings.fontWeight) ? lyricsSettings.fontWeight : "Black";
        switch (String(w).toLowerCase()) {
            case "thin": return Font.Thin;
            case "light": return Font.Light;
            case "normal": return Font.Normal;
            case "medium": return Font.Medium;
            case "demibold": return Font.DemiBold;
            case "bold": return Font.Bold;
            case "extrabold": return Font.ExtraBold;
            case "black": return Font.Black;
            default: return Font.Black;
        }
    }
    property bool fontItalic: (lyricsSettings && lyricsSettings.fontItalic !== undefined) ? Boolean(lyricsSettings.fontItalic) : false
    property color textColor: (lyricsSettings && lyricsSettings.color) ? lyricsSettings.color : "#ffffff"
    property real textOpacity: (lyricsSettings && lyricsSettings.opacity !== undefined) ? (Number(lyricsSettings.opacity) / 100.0) : 0.85
    property int textAlignment: {
        let a = (lyricsSettings && lyricsSettings.alignment) ? lyricsSettings.alignment : "center";
        switch (String(a).toLowerCase()) {
            case "left": return Text.AlignLeft;
            case "right": return Text.AlignRight;
            default: return Text.AlignHCenter;
        }
    }
    property int maxLines: {
        let m = (lyricsSettings && lyricsSettings.maxLines !== undefined) ? parseInt(lyricsSettings.maxLines) : 2;
        return m > 0 ? m : 999;
    }
    property bool dropShadow: (lyricsSettings && lyricsSettings.shadow !== undefined) ? Boolean(lyricsSettings.shadow) : true
    property bool showTestLyric: (lyricsSettings && lyricsSettings.showTestLyric !== undefined) ? Boolean(lyricsSettings.showTestLyric) : false

    property real savedX: (lyricsSettings && lyricsSettings.x !== undefined) ? Number(lyricsSettings.x) : 100
    property real savedY: (lyricsSettings && lyricsSettings.y !== undefined) ? Number(lyricsSettings.y) : 100

    property real randomX: root.width / 2 - 250
    property real randomY: root.height / 2 - 50

    property real targetX: mode === "cursor" ? savedX : randomX
    property real targetY: mode === "cursor" ? savedY : randomY

    property string currentLyric: ""
    readonly property string activeLyricText: (currentLyric !== "") ? currentLyric : (showTestLyric ? "♪ Desktop Lyrics (Rainmeter Mode - Drag to move) ♪" : "")

    visible: enabled

    mask: Region {
        item: (root.enabled && root.mode === "cursor" && root.activeLyricText !== "") ? dragContainer : null
    }

    Timer {
        interval: 1000
        running: root.enabled
        repeat: true
        onTriggered: lyricProc.running = true
    }

    Process {
        id: lyricProc
        command: ["python3", "/home/focarix/.config/serpantinum/src/scripts/lyrics_tracker.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== undefined) {
                    root.currentLyric = txt;
                }
            }
        }
    }

    function savePosition(newX, newY) {
        let s = (typeof Config !== "undefined" && typeof Config.getSetting === "function")
            ? Config.getSetting("desktopLyrics", defaultSettings)
            : defaultSettings;
        let current = JSON.parse(JSON.stringify(s || defaultSettings));
        current.x = Math.round(newX);
        current.y = Math.round(newY);
        if (typeof Config !== "undefined" && typeof Config.setSetting === "function") {
            Config.setSetting("desktopLyrics", current);
        }
        root.savedX = Math.round(newX);
        root.savedY = Math.round(newY);
    }

    Item {
        id: dragContainer
        x: root.targetX
        y: root.targetY
        width: lyricText.width
        height: lyricText.height

        Connections {
            target: root
            function onTargetXChanged() {
                if (!dragArea.drag.active) {
                    dragContainer.x = root.targetX;
                }
            }
            function onTargetYChanged() {
                if (!dragArea.drag.active) {
                    dragContainer.y = root.targetY;
                }
            }
        }

        Rectangle {
            id: dragHintBox
            anchors.fill: parent
            anchors.margins: -10
            radius: 8
            color: dragArea.containsMouse ? Qt.rgba(0, 0, 0, 0.4) : "transparent"
            border.color: dragArea.containsMouse ? Qt.rgba(1, 1, 1, 0.5) : "transparent"
            border.width: 1
            visible: root.mode === "cursor" && root.activeLyricText !== ""
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.bottom: parent.top
                anchors.left: parent.left
                anchors.bottomMargin: 4
                text: "󰆾 Drag to position"
                font.family: ThemeBackend.fontFamily
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.85)
                visible: dragArea.containsMouse && root.mode === "cursor"
            }
        }

        Text {
            id: lyricText
            text: root.activeLyricText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.weight: root.fontWeight
            font.italic: root.fontItalic
            opacity: text === "" ? 0 : root.textOpacity
            horizontalAlignment: root.textAlignment
            wrapMode: Text.WordWrap
            maximumLineCount: root.maxLines
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width * 0.85)

            style: root.dropShadow ? Text.Outline : Text.Normal
            styleColor: root.dropShadow ? Qt.rgba(0, 0, 0, 0.85) : "transparent"

            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }

            onTextChanged: {
                if (root.mode === "random" && text !== "") {
                    let curW = Math.min(implicitWidth, root.width * 0.85);
                    let curH = implicitHeight;
                    let maxX = Math.max(0, root.width - curW - 100);
                    let maxY = Math.max(0, root.height - curH - 100);
                    root.randomX = 50 + Math.random() * maxX;
                    root.randomY = 50 + Math.random() * maxY;
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -10
            enabled: root.mode === "cursor" && root.activeLyricText !== ""
            hoverEnabled: true
            cursorShape: enabled ? Qt.SizeAllCursor : Qt.ArrowCursor

            drag.target: dragContainer
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.maximumX: Math.max(0, root.width - dragContainer.width)
            drag.minimumY: 0
            drag.maximumY: Math.max(0, root.height - dragContainer.height)

            onReleased: {
                root.savePosition(dragContainer.x, dragContainer.y);
            }
        }
    }
}
