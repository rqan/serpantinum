import QtQuick
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

    property bool enabled: Config.getSetting("general", {}).desktopLyrics === true
    property string currentLyric: ""

    visible: enabled

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

    Text {
        id: lyricText
        property real currentX: root.width / 2 - width / 2
        property real currentY: root.height / 2 - height / 2

        x: currentX
        y: currentY
        text: root.currentLyric
        color: "#ffffff"
        font.family: "Georgia, serif"
        font.pixelSize: 52
        font.weight: Font.Black
        opacity: text === "" ? 0 : 0.85
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width * 0.8)

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        onTextChanged: {
            if (text !== "") {
                let curW = Math.min(implicitWidth, root.width * 0.8);
                let curH = implicitHeight;
                let maxX = Math.max(0, root.width - curW - 100);
                let maxY = Math.max(0, root.height - curH - 100);
                currentX = 50 + Math.random() * maxX;
                currentY = 50 + Math.random() * maxY;
            }
        }
    }
}
