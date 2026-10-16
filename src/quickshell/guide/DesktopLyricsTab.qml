import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../"
import "../reusables"
import "theme"

Item {
    id: lyricsTabRoot
    required property var rootObj
    required property int tabIndex

    anchors.fill: parent
    visible: rootObj.currentTab === tabIndex
    opacity: visible ? 1.0 : 0.0
    property real slideY: visible ? 0 : rootObj.s(10)

    Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
    transform: Translate { y: slideY }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    property var defaultLyricsSettings: ({
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
            return Config.getSetting("desktopLyrics", defaultLyricsSettings);
        }
        return defaultLyricsSettings;
    }

    property bool currentEnabled: {
        if (lyricsSettings && lyricsSettings.enabled !== undefined) return Boolean(lyricsSettings.enabled);
        let gen = (typeof Config !== "undefined" && Config.rawSettings) ? Config.rawSettings["general"] : undefined;
        if (gen && gen.desktopLyrics !== undefined) return Boolean(gen.desktopLyrics);
        return true;
    }

    property string currentMode: (lyricsSettings && lyricsSettings.mode) ? lyricsSettings.mode : "random"
    property real currentX: (lyricsSettings && lyricsSettings.x !== undefined) ? Number(lyricsSettings.x) : 100
    property real currentY: (lyricsSettings && lyricsSettings.y !== undefined) ? Number(lyricsSettings.y) : 100
    property string currentFontFamily: (lyricsSettings && lyricsSettings.fontFamily) ? lyricsSettings.fontFamily : "Georgia, serif"
    property int currentFontSize: (lyricsSettings && lyricsSettings.fontSize) ? parseInt(lyricsSettings.fontSize) : 52
    property string currentFontWeight: (lyricsSettings && lyricsSettings.fontWeight) ? String(lyricsSettings.fontWeight) : "Black"
    property bool currentFontItalic: (lyricsSettings && lyricsSettings.fontItalic !== undefined) ? Boolean(lyricsSettings.fontItalic) : false
    property string currentColor: (lyricsSettings && lyricsSettings.color) ? lyricsSettings.color : "#ffffff"
    property int currentOpacity: (lyricsSettings && lyricsSettings.opacity !== undefined) ? parseInt(lyricsSettings.opacity) : 85
    property string currentAlignment: (lyricsSettings && lyricsSettings.alignment) ? lyricsSettings.alignment : "center"
    property int currentMaxLines: (lyricsSettings && lyricsSettings.maxLines !== undefined) ? parseInt(lyricsSettings.maxLines) : 2
    property bool currentShadow: (lyricsSettings && lyricsSettings.shadow !== undefined) ? Boolean(lyricsSettings.shadow) : true
    property bool currentShowTestLyric: (lyricsSettings && lyricsSettings.showTestLyric !== undefined) ? Boolean(lyricsSettings.showTestLyric) : false

    property var curatedFonts: ThemeBackend.bundledNames || []
    property var blockedFontPatterns: [".notdef", "cursor", "emoji", "symbol", "pcf"]
    property var availableFonts: []

    function loadAvailableFonts() {
        if (availableFonts.length > 0) return;
        let curated = lyricsTabRoot.curatedFonts || [];
        let dedupedCurated = [];
        let seen = new Set();

        for (let i = 0; i < curated.length; i++) {
            let f = curated[i];
            if (f && !seen.has(f)) {
                seen.add(f);
                dedupedCurated.push(f);
            }
        }

        let all = Qt.fontFamilies();
        let rest = [];
        for (let i = 0; i < all.length; i++) {
            let fam = all[i];
            if (!fam || seen.has(fam)) continue;

            let lower = fam.toLowerCase();
            let isBlocked = false;
            for (let b = 0; b < blockedFontPatterns.length; b++) {
                if (lower.indexOf(blockedFontPatterns[b]) !== -1) {
                    isBlocked = true;
                    break;
                }
            }
            if (!isBlocked) {
                seen.add(fam);
                rest.push(fam);
            }
        }

        rest.sort(function(a, b) { return a.localeCompare(b); });
        let combined = dedupedCurated.concat(rest);
        if (lyricsTabRoot.currentFontFamily && combined.indexOf(lyricsTabRoot.currentFontFamily) === -1) {
            combined.unshift(lyricsTabRoot.currentFontFamily);
        }
        lyricsTabRoot.availableFonts = combined;
    }

    function syncSettings() {
        let s = (typeof Config !== "undefined" && typeof Config.getSetting === "function")
            ? Config.getSetting("desktopLyrics", defaultLyricsSettings)
            : defaultLyricsSettings;
        lyricsTabRoot.lyricsSettings = s;
        lyricsTabRoot.currentEnabled = s.enabled !== undefined ? Boolean(s.enabled) : true;
        lyricsTabRoot.currentMode = s.mode || "random";
        lyricsTabRoot.currentX = s.x !== undefined ? Number(s.x) : 100;
        lyricsTabRoot.currentY = s.y !== undefined ? Number(s.y) : 100;
        lyricsTabRoot.currentFontFamily = s.fontFamily || "Georgia, serif";
        lyricsTabRoot.currentFontSize = s.fontSize !== undefined ? parseInt(s.fontSize) : 52;
        lyricsTabRoot.currentFontWeight = s.fontWeight || "Black";
        lyricsTabRoot.currentFontItalic = s.fontItalic !== undefined ? Boolean(s.fontItalic) : false;
        lyricsTabRoot.currentColor = s.color || "#ffffff";
        lyricsTabRoot.currentOpacity = s.opacity !== undefined ? parseInt(s.opacity) : 85;
        lyricsTabRoot.currentAlignment = s.alignment || "center";
        lyricsTabRoot.currentMaxLines = s.maxLines !== undefined ? parseInt(s.maxLines) : 2;
        lyricsTabRoot.currentShadow = s.shadow !== undefined ? Boolean(s.shadow) : true;
        lyricsTabRoot.currentShowTestLyric = s.showTestLyric !== undefined ? Boolean(s.showTestLyric) : false;
        loadAvailableFonts();
    }

    function updateLyricsSetting(key, value) {
        let base = (typeof Config !== "undefined" && typeof Config.getSetting === "function")
            ? Config.getSetting("desktopLyrics", defaultLyricsSettings)
            : defaultLyricsSettings;
        let current = JSON.parse(JSON.stringify(base || defaultLyricsSettings));
        current[key] = value;
        if (typeof Config !== "undefined" && typeof Config.setSetting === "function") {
            Config.setSetting("desktopLyrics", current);
            if (key === "enabled") {
                let gen = Config.getSetting("general", {});
                gen.desktopLyrics = value;
                Config.setSetting("general", gen);
            }
        }
        lyricsTabRoot.lyricsSettings = current;
    }

    Timer {
        id: debounceTimer
        interval: 120
        repeat: false
        property var pendingCallback: null
        onTriggered: {
            if (pendingCallback) {
                pendingCallback();
                pendingCallback = null;
            }
        }
    }

    function triggerDebounced(cb) {
        debounceTimer.pendingCallback = cb;
        debounceTimer.restart();
    }

    onVisibleChanged: {
        if (visible) syncSettings();
    }

    Component.onCompleted: syncSettings()

    Connections {
        target: typeof Config !== "undefined" ? Config : null
        function onSettingsLoaded() {
            lyricsTabRoot.syncSettings();
        }
    }

    FontPicker {
        id: fontPickerPopup
        rootObj: lyricsTabRoot.rootObj
        onFontSelected: function(filePath, fileName) {
            if (!filePath || filePath.trim() === "" || !fileName || fileName.trim() === "") return;
            let fam = fileName.replace(/\.[^.]+$/, "");
            lyricsTabRoot.currentFontFamily = fam;
            lyricsTabRoot.updateLyricsSetting("fontFamily", fam);
            if (lyricsTabRoot.availableFonts.indexOf(fam) === -1) {
                let arr = lyricsTabRoot.availableFonts.slice();
                arr.unshift(fam);
                lyricsTabRoot.availableFonts = arr;
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: rootObj.s(8)
        anchors.leftMargin: rootObj.s(8)
        anchors.rightMargin: rootObj.s(8)
        anchors.bottomMargin: rootObj.s(8)
        contentHeight: settingsCol.implicitHeight + rootObj.s(24)
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            active: parent.moving || parent.movingVertically
            width: rootObj.s(4)
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: rootObj.s(4)
                radius: rootObj.s(2)
                color: ThemeBackend.surface2
            }
        }

        ColumnLayout {
            id: settingsCol
            width: parent.width - (parent.contentHeight > parent.height ? rootObj.s(6) : 0)
            spacing: rootObj.s(6)

            // Card 1: Toggle Switch (Enable Desktop Lyrics)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: rowEnabledLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0

                RowLayout {
                    id: rowEnabledLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    IconButton {
                        enabled: false
                        size: rootObj.s(32)
                        Layout.preferredWidth: rootObj.s(32)
                        Layout.preferredHeight: rootObj.s(32)
                        Layout.alignment: Qt.AlignVCenter
                        cornerRadius: ThemeBackend.borderRadius
                        buttonIcon: "󰝚"
                        iconFontSize: rootObj.s(16)
                        accentColor: ThemeBackend.surface0
                        textColor: "#ffffff"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: rootObj.s(2)

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("guide.desktop_lyrics.enabled.title", "Enable desktop lyrics")
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(13)
                            color: ThemeBackend.text
                        }
                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("guide.desktop_lyrics.enabled.desc", "Tampilkan lirik mengambang yang tersinkronisasi di desktop")
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(11)
                            color: ThemeBackend.subtext0
                        }
                    }

                    Toggle {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        checked: lyricsTabRoot.currentEnabled
                        accentColor: ThemeBackend.mauve
                        baseColor: ThemeBackend.surface1
                        handleColor: ThemeBackend.crust
                        handleOffColor: ThemeBackend.text
                        onToggled: function(val) {
                            lyricsTabRoot.currentEnabled = val;
                            lyricsTabRoot.updateLyricsSetting("enabled", val);
                        }
                    }
                }
            }

            // Card 2: Layout / Position Mode (Acak vs By Cursor)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: colModeLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0
                visible: lyricsTabRoot.currentEnabled

                ColumnLayout {
                    id: colModeLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰆾"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.mode.title", "Tata letak posisi")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.mode.desc", "Pilih posisi acak otomatis atau atur manual dengan kursor (Rainmeter style)")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Dropdown {
                            id: modeDropdown
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitWidth: rootObj.s(220)
                            implicitHeight: rootObj.s(32)
                            options: [
                                "Acak (Random)",
                                "By Cursor (Rainmeter / Drag)"
                            ]
                            currentIndex: lyricsTabRoot.currentMode === "cursor" ? 1 : 0
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface0
                            hoverColor: ThemeBackend.surface1
                            dropdownColor: ThemeBackend.surface0
                            borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
                            textColor: ThemeBackend.text
                            activeTextColor: ThemeBackend.crust
                            fontPixelSize: rootObj.s(11)
                            onValueChanged: function(index, value) {
                                let m = (index === 1) ? "cursor" : "random";
                                lyricsTabRoot.currentMode = m;
                                lyricsTabRoot.updateLyricsSetting("mode", m);
                            }
                        }
                    }

                    // Sub-section for Cursor (Rainmeter) mode
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(10)
                        visible: lyricsTabRoot.currentMode === "cursor"

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.alpha(ThemeBackend.surface1, 0.3)
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: tipLayout.implicitHeight + rootObj.s(16)
                            radius: ThemeBackend.borderRadius
                            color: Qt.alpha(ThemeBackend.mauve, 0.12)
                            border.color: Qt.alpha(ThemeBackend.mauve, 0.25)
                            border.width: 1

                            RowLayout {
                                id: tipLayout
                                anchors.fill: parent
                                anchors.margins: rootObj.s(10)
                                spacing: rootObj.s(8)

                                Text {
                                    text: "󰋼"
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: rootObj.s(15)
                                    color: ThemeBackend.mauve
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Mode Kursor aktif! Anda dapat mengklik dan menggeser lirik di desktop secara bebas dengan mouse (drag-and-drop). Posisi akan disimpan otomatis."
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: rootObj.s(11)
                                    color: ThemeBackend.text
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: rootObj.s(12)

                            Text {
                                text: "Posisi X:"
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(12)
                                color: ThemeBackend.subtext0
                                Layout.preferredWidth: rootObj.s(60)
                            }

                            Draggable {
                                Layout.fillWidth: true
                                implicitHeight: rootObj.s(18)
                                from: 0
                                to: 2560
                                stepSize: 10
                                defaultValue: 100
                                showValueBubble: true
                                valueFormatter: function(v) { return Math.round(v) + " px"; }
                                value: lyricsTabRoot.currentX
                                backgroundColor: ThemeBackend.surface0
                                accentColor: ThemeBackend.mauve
                                handleColor: ThemeBackend.text
                                handleBorderColor: ThemeBackend.mantle
                                onMoved: function(val) {
                                    let rounded = Math.round(val);
                                    lyricsTabRoot.currentX = rounded;
                                    lyricsTabRoot.triggerDebounced(function() {
                                        lyricsTabRoot.updateLyricsSetting("x", rounded);
                                    });
                                }
                            }

                            Text {
                                text: Math.round(lyricsTabRoot.currentX) + " px"
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.mauve
                                Layout.preferredWidth: rootObj.s(50)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: rootObj.s(12)

                            Text {
                                text: "Posisi Y:"
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(12)
                                color: ThemeBackend.subtext0
                                Layout.preferredWidth: rootObj.s(60)
                            }

                            Draggable {
                                Layout.fillWidth: true
                                implicitHeight: rootObj.s(18)
                                from: 0
                                to: 1440
                                stepSize: 10
                                defaultValue: 100
                                showValueBubble: true
                                valueFormatter: function(v) { return Math.round(v) + " px"; }
                                value: lyricsTabRoot.currentY
                                backgroundColor: ThemeBackend.surface0
                                accentColor: ThemeBackend.mauve
                                handleColor: ThemeBackend.text
                                handleBorderColor: ThemeBackend.mantle
                                onMoved: function(val) {
                                    let rounded = Math.round(val);
                                    lyricsTabRoot.currentY = rounded;
                                    lyricsTabRoot.triggerDebounced(function() {
                                        lyricsTabRoot.updateLyricsSetting("y", rounded);
                                    });
                                }
                            }

                            Text {
                                text: Math.round(lyricsTabRoot.currentY) + " px"
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.mauve
                                Layout.preferredWidth: rootObj.s(50)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: rootObj.s(8)

                            ClickButton {
                                implicitHeight: rootObj.s(28)
                                cornerRadius: ThemeBackend.borderRadius
                                buttonText: "Pusatkan Layar"
                                buttonIcon: "󰍉"
                                iconFontSize: rootObj.s(12)
                                textFontSize: rootObj.s(11)
                                accentColor: ThemeBackend.surface1
                                textColor: ThemeBackend.text
                                onClicked: {
                                    lyricsTabRoot.currentX = 200;
                                    lyricsTabRoot.currentY = 200;
                                    lyricsTabRoot.updateLyricsSetting("x", 200);
                                    lyricsTabRoot.updateLyricsSetting("y", 200);
                                }
                            }

                            ClickButton {
                                implicitHeight: rootObj.s(28)
                                cornerRadius: ThemeBackend.borderRadius
                                buttonText: lyricsTabRoot.currentShowTestLyric ? "Sembunyikan Teks Uji" : "Tampilkan Teks Uji di Desktop"
                                buttonIcon: "󰈈"
                                iconFontSize: rootObj.s(12)
                                textFontSize: rootObj.s(11)
                                accentColor: lyricsTabRoot.currentShowTestLyric ? ThemeBackend.red : ThemeBackend.mauve
                                textColor: ThemeBackend.crust
                                onClicked: {
                                    lyricsTabRoot.currentShowTestLyric = !lyricsTabRoot.currentShowTestLyric;
                                    lyricsTabRoot.updateLyricsSetting("showTestLyric", lyricsTabRoot.currentShowTestLyric);
                                }
                            }
                        }
                    }
                }
            }

            // Card 3: Font Configuration (Family, Size, Weight, Italic)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: colFontLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0
                visible: lyricsTabRoot.currentEnabled

                ColumnLayout {
                    id: colFontLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    // Font Family
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰛖"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.font.title", "Font")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.font.desc", "Pilih jenis font untuk tampilan lirik desktop")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        IconButton {
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: rootObj.s(6)
                            buttonIcon: "󰐕"
                            iconFontSize: rootObj.s(14)
                            accentColor: ThemeBackend.surface0
                            textColor: ThemeBackend.text
                            onClicked: fontPickerPopup.openPicker()
                        }

                        Dropdown {
                            id: fontDropdown
                            Layout.preferredWidth: rootObj.s(200)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            options: lyricsTabRoot.availableFonts
                            currentIndex: Math.max(0, options.indexOf(lyricsTabRoot.currentFontFamily))
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface0
                            hoverColor: ThemeBackend.surface1
                            dropdownColor: ThemeBackend.surface0
                            borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
                            textColor: ThemeBackend.text
                            activeTextColor: ThemeBackend.crust
                            fontPixelSize: rootObj.s(11)
                            fontFamily: ThemeBackend.fontFamily
                            useOptionAsFontFamily: true
                            onValueChanged: function(index, value) {
                                lyricsTabRoot.currentFontFamily = value;
                                lyricsTabRoot.updateLyricsSetting("fontFamily", value);
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(ThemeBackend.surface1, 0.3)
                    }

                    // Font Size
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰬚"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.fontsize.title", "Ukuran font")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.fontsize.desc", "Atur ukuran teks lirik desktop (20px - 100px)")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Draggable {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitWidth: rootObj.s(180)
                            implicitHeight: rootObj.s(18)
                            from: 20
                            to: 100
                            stepSize: 2
                            defaultValue: 52
                            showValueBubble: true
                            valueFormatter: function(v) { return Math.round(v) + " px"; }
                            value: lyricsTabRoot.currentFontSize
                            backgroundColor: ThemeBackend.surface0
                            accentColor: ThemeBackend.mauve
                            handleColor: ThemeBackend.text
                            handleBorderColor: ThemeBackend.mantle
                            onMoved: function(val) {
                                let rounded = Math.round(val);
                                lyricsTabRoot.currentFontSize = rounded;
                                lyricsTabRoot.triggerDebounced(function() {
                                    lyricsTabRoot.updateLyricsSetting("fontSize", rounded);
                                });
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(ThemeBackend.surface1, 0.3)
                    }

                    // Font Weight & Italic
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰰓"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.weight.title", "Ketebalan & gaya miring")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.weight.desc", "Pilih ketebalan teks dan aktifkan miring (italic)")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Dropdown {
                            id: weightDropdown
                            Layout.preferredWidth: rootObj.s(120)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            options: ["Light", "Normal", "Medium", "DemiBold", "Bold", "ExtraBold", "Black"]
                            currentIndex: {
                                let idx = options.indexOf(lyricsTabRoot.currentFontWeight);
                                return idx >= 0 ? idx : 6;
                            }
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface0
                            hoverColor: ThemeBackend.surface1
                            dropdownColor: ThemeBackend.surface0
                            borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
                            textColor: ThemeBackend.text
                            activeTextColor: ThemeBackend.crust
                            fontPixelSize: rootObj.s(11)
                            onValueChanged: function(index, value) {
                                lyricsTabRoot.currentFontWeight = value;
                                lyricsTabRoot.updateLyricsSetting("fontWeight", value);
                            }
                        }

                        ClickButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: rootObj.s(32)
                            implicitWidth: rootObj.s(70)
                            cornerRadius: ThemeBackend.borderRadius
                            buttonText: "Italic"
                            buttonIcon: "󰰑"
                            iconFontSize: rootObj.s(13)
                            textFontSize: rootObj.s(11)
                            accentColor: lyricsTabRoot.currentFontItalic ? ThemeBackend.mauve : ThemeBackend.surface1
                            textColor: lyricsTabRoot.currentFontItalic ? ThemeBackend.crust : ThemeBackend.text
                            onClicked: {
                                lyricsTabRoot.currentFontItalic = !lyricsTabRoot.currentFontItalic;
                                lyricsTabRoot.updateLyricsSetting("fontItalic", lyricsTabRoot.currentFontItalic);
                            }
                        }
                    }
                }
            }

            // Card 4: Warna & Efek (Color, Opacity, Shadow)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: colColorLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0
                visible: lyricsTabRoot.currentEnabled

                ColumnLayout {
                    id: colColorLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    // Text Color & Presets
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰏘"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.color.title", "Warna lirik")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.color.desc", "Pilih preset warna atau masukkan kode HEX")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        // Color preset chips
                        Row {
                            spacing: rootObj.s(4)
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: ["#ffffff", "#f5e0dc", "#cba6f7", "#89b4fa", "#a6e3a1", "#f9e2af", "#f38ba8", "#11111b"]
                                delegate: Rectangle {
                                    id: colorChip
                                    required property string modelData
                                    width: rootObj.s(22)
                                    height: rootObj.s(22)
                                    radius: rootObj.s(11)
                                    color: modelData
                                    border.color: lyricsTabRoot.currentColor.toLowerCase() === modelData.toLowerCase() ? ThemeBackend.mauve : Qt.alpha(ThemeBackend.surface2, 0.8)
                                    border.width: lyricsTabRoot.currentColor.toLowerCase() === modelData.toLowerCase() ? 2 : 1

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            lyricsTabRoot.currentColor = modelData;
                                            lyricsTabRoot.updateLyricsSetting("color", modelData);
                                        }
                                    }
                                }
                            }
                        }

                        Input {
                            id: hexInput
                            Layout.preferredWidth: rootObj.s(90)
                            Layout.preferredHeight: rootObj.s(32)
                            text: lyricsTabRoot.currentColor
                            placeholderText: "#ffffff"
                            maximumLength: 9
                            onAccepted: function(val) {
                                let trimmed = val.trim();
                                if (!trimmed.startsWith("#")) trimmed = "#" + trimmed;
                                lyricsTabRoot.currentColor = trimmed;
                                lyricsTabRoot.updateLyricsSetting("color", trimmed);
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(ThemeBackend.surface1, 0.3)
                    }

                    // Opacity
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰂵"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.opacity.title", "Transparansi lirik")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.opacity.desc", "Atur tingkat opasitas tampilan lirik di desktop")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Draggable {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitWidth: rootObj.s(180)
                            implicitHeight: rootObj.s(18)
                            from: 10
                            to: 100
                            stepSize: 1
                            defaultValue: 85
                            showValueBubble: true
                            valueFormatter: function(v) { return Math.round(v) + " %"; }
                            value: lyricsTabRoot.currentOpacity
                            backgroundColor: ThemeBackend.surface0
                            accentColor: ThemeBackend.mauve
                            handleColor: ThemeBackend.text
                            handleBorderColor: ThemeBackend.mantle
                            onMoved: function(val) {
                                let rounded = Math.round(val);
                                lyricsTabRoot.currentOpacity = rounded;
                                lyricsTabRoot.triggerDebounced(function() {
                                    lyricsTabRoot.updateLyricsSetting("opacity", rounded);
                                });
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(ThemeBackend.surface1, 0.3)
                    }

                    // Shadow / Outline toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰏘"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.shadow.title", "Garis tepi & bayangan (Outline/Shadow)")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.shadow.desc", "Meningkatkan keterbacaan teks di atas berbagai wallpaper")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Toggle {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            checked: lyricsTabRoot.currentShadow
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface1
                            handleColor: ThemeBackend.crust
                            handleOffColor: ThemeBackend.text
                            onToggled: function(val) {
                                lyricsTabRoot.currentShadow = val;
                                lyricsTabRoot.updateLyricsSetting("shadow", val);
                            }
                        }
                    }
                }
            }

            // Card 5: Paragraph Style & Alignment (Perataan Paragraf & Baris)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: colAlignLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0
                visible: lyricsTabRoot.currentEnabled

                ColumnLayout {
                    id: colAlignLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    // Text Alignment
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰞆"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.alignment.title", "Perataan paragraf")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.alignment.desc", "Rata kiri, tengah, atau kanan teks lirik")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Row {
                            spacing: rootObj.s(4)
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                            ClickButton {
                                implicitHeight: rootObj.s(32)
                                implicitWidth: rootObj.s(48)
                                cornerRadius: ThemeBackend.borderRadius
                                buttonIcon: "󰞆"
                                iconFontSize: rootObj.s(14)
                                accentColor: lyricsTabRoot.currentAlignment === "left" ? ThemeBackend.mauve : ThemeBackend.surface1
                                textColor: lyricsTabRoot.currentAlignment === "left" ? ThemeBackend.crust : ThemeBackend.text
                                onClicked: {
                                    lyricsTabRoot.currentAlignment = "left";
                                    lyricsTabRoot.updateLyricsSetting("alignment", "left");
                                }
                            }

                            ClickButton {
                                implicitHeight: rootObj.s(32)
                                implicitWidth: rootObj.s(48)
                                cornerRadius: ThemeBackend.borderRadius
                                buttonIcon: "󰞅"
                                iconFontSize: rootObj.s(14)
                                accentColor: lyricsTabRoot.currentAlignment === "center" ? ThemeBackend.mauve : ThemeBackend.surface1
                                textColor: lyricsTabRoot.currentAlignment === "center" ? ThemeBackend.crust : ThemeBackend.text
                                onClicked: {
                                    lyricsTabRoot.currentAlignment = "center";
                                    lyricsTabRoot.updateLyricsSetting("alignment", "center");
                                }
                            }

                            ClickButton {
                                implicitHeight: rootObj.s(32)
                                implicitWidth: rootObj.s(48)
                                cornerRadius: ThemeBackend.borderRadius
                                buttonIcon: "󰞇"
                                iconFontSize: rootObj.s(14)
                                accentColor: lyricsTabRoot.currentAlignment === "right" ? ThemeBackend.mauve : ThemeBackend.surface1
                                textColor: lyricsTabRoot.currentAlignment === "right" ? ThemeBackend.crust : ThemeBackend.text
                                onClicked: {
                                    lyricsTabRoot.currentAlignment = "right";
                                    lyricsTabRoot.updateLyricsSetting("alignment", "right");
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(ThemeBackend.surface1, 0.3)
                    }

                    // Maximum Lines
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(12)

                        IconButton {
                            enabled: false
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: "󰦨"
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.maxlines.title", "Jumlah baris maksimal")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("guide.desktop_lyrics.maxlines.desc", "Batasi jumlah baris lirik yang tampil sebelum dipotong")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Dropdown {
                            id: maxLinesDropdown
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitWidth: rootObj.s(180)
                            implicitHeight: rootObj.s(32)
                            options: ["1 Baris", "2 Baris", "3 Baris", "Tanpa Batas (Wrap)"]
                            currentIndex: {
                                if (lyricsTabRoot.currentMaxLines === 1) return 0;
                                if (lyricsTabRoot.currentMaxLines === 2) return 1;
                                if (lyricsTabRoot.currentMaxLines === 3) return 2;
                                return 3;
                            }
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface0
                            hoverColor: ThemeBackend.surface1
                            dropdownColor: ThemeBackend.surface0
                            borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
                            textColor: ThemeBackend.text
                            activeTextColor: ThemeBackend.crust
                            fontPixelSize: rootObj.s(11)
                            onValueChanged: function(index, value) {
                                let lines = 2;
                                if (index === 0) lines = 1;
                                else if (index === 1) lines = 2;
                                else if (index === 2) lines = 3;
                                else lines = 0;
                                lyricsTabRoot.currentMaxLines = lines;
                                lyricsTabRoot.updateLyricsSetting("maxLines", lines);
                            }
                        }
                    }
                }
            }

            // Card 6: Live Preview Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: colPreviewLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.color: Qt.alpha(ThemeBackend.surface1, 0.4)
                border.width: 1
                visible: lyricsTabRoot.currentEnabled

                ColumnLayout {
                    id: colPreviewLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: rootObj.s(14)
                    spacing: rootObj.s(12)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: rootObj.s(8)

                        Text {
                            text: "󰈈 Pratinjau Tampilan Lirik"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(13)
                            font.bold: true
                            color: ThemeBackend.text
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: lyricsTabRoot.currentFontFamily + ", " + lyricsTabRoot.currentFontSize + "px (" + lyricsTabRoot.currentMode + ")"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(11)
                            color: ThemeBackend.subtext0
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rootObj.s(110)
                        radius: ThemeBackend.borderRadius
                        color: Qt.alpha(ThemeBackend.mantle, 0.7)
                        clip: true

                        Text {
                            anchors.fill: parent
                            anchors.margins: rootObj.s(12)
                            text: "♪ Never gonna give you up\nNever gonna let you down ♪"
                            color: lyricsTabRoot.currentColor
                            font.family: lyricsTabRoot.currentFontFamily
                            font.pixelSize: Math.min(32, lyricsTabRoot.currentFontSize * 0.6)
                            font.weight: {
                                switch (lyricsTabRoot.currentFontWeight) {
                                    case "Light": return Font.Light;
                                    case "Normal": return Font.Normal;
                                    case "Medium": return Font.Medium;
                                    case "DemiBold": return Font.DemiBold;
                                    case "Bold": return Font.Bold;
                                    case "ExtraBold": return Font.ExtraBold;
                                    case "Black": return Font.Black;
                                    default: return Font.Black;
                                }
                            }
                            font.italic: lyricsTabRoot.currentFontItalic
                            opacity: lyricsTabRoot.currentOpacity / 100.0
                            horizontalAlignment: {
                                switch (lyricsTabRoot.currentAlignment) {
                                    case "left": return Text.AlignLeft;
                                    case "right": return Text.AlignRight;
                                    default: return Text.AlignHCenter;
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                            style: lyricsTabRoot.currentShadow ? Text.Outline : Text.Normal
                            styleColor: lyricsTabRoot.currentShadow ? Qt.rgba(0, 0, 0, 0.75) : "transparent"
                        }
                    }
                }
            }
        }
    }
}
