import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../singletons/system"
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
    WlrLayershell.layer: WlrLayer.Background
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
        text: root.currentLyric
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
        color: "#ffffff"
        font.family: "Inter"
        font.pixelSize: 48
        font.bold: true
        style: Text.Outline
        styleColor: "#000000"
        opacity: text === "" ? 0 : 1
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: root.width * 0.8

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }
    }
}
