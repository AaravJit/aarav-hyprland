                            ? Math.round(setting.currentValue).toString()
                            : Number(setting.currentValue).toFixed(setting.decimals)
                        color: colors.onPrimaryContainer
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                from: setting.from
                to: setting.to
                stepSize: setting.stepSize
                value: setting.currentValue
                onMoved: setting.valueEdited(value)
            }
        }
    }

    component ToggleSetting: Item {
        id: setting
        property string title: ""
        property string description: ""
        property bool currentValue: false
        signal valueEdited(bool value)

        Layout.fillWidth: true
        implicitHeight: row.implicitHeight

        RowLayout {
            id: row
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: setting.title
                    color: colors.onSurface
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Text {
                    visible: setting.description.length > 0
                    Layout.fillWidth: true
                    text: setting.description
                    color: colors.onSurfaceVariant
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            Switch {
                checked: setting.currentValue
                onToggled: setting.valueEdited(checked)
            }
        }
    }

    component InfoChip: Rectangle {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        implicitHeight: 76
        radius: 15
        color: colors.surfaceContainer
        border.width: 1
        border.color: colors.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 4

            Text {
                text: parent.parent.label
                color: colors.onSurfaceVariant
                font.family: "Noto Sans"
                font.pixelSize: 12
            }

            Text {
                Layout.fillWidth: true
                text: parent.parent.value || "Unknown"
                color: colors.onSurface
                font.family: "Noto Sans"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
            }
        }
    }

    Process {
        id: loadProcess
        command: ["python", root.managerPath, "get-json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.loadPayload(JSON.parse(this.text));
                    root.statusText = "Settings loaded";
                    root.statusIsError = false;
                } catch (error) {
                    root.statusText = "Could not read settings: " + error;
                    root.statusIsError = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.statusText = this.text.trim();
                    root.statusIsError = true;
                }
            }
        }
    }

    Process {
        id: saveProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length === 0)
                    return;
                try {
                    root.loadPayload(JSON.parse(this.text));
                    root.statusText = "Settings applied";
                    root.statusIsError = false;
                } catch (error) {
                    root.statusText = "Settings saved, but the response was invalid";
                    root.statusIsError = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.statusText = this.text.trim();
                    root.statusIsError = true;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.statusIsError = true;
                if (!root.statusText.length)
                    root.statusText = "Settings could not be applied";
                root.pendingAction = "";
                return;
            }

            root.dirty = false;
            if (root.pendingAction === "wallpaper") {
                root.pendingAction = "";
                root.runAction(
                    [root.homePath + "/.local/bin/set-wallpaper"],
                    "Opening wallpaper picker…"
                );
            } else {
                root.pendingAction = "";
            }
        }
    }

    Process {
        id: resetProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length === 0)
                    return;
                try {
                    root.loadPayload(JSON.parse(this.text));
                    root.statusText = "Defaults restored";
                    root.statusIsError = false;
                } catch (error) {
                    root.statusText = "Defaults applied, but reload failed";
                    root.statusIsError = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.statusText = this.text.trim();
                    root.statusIsError = true;
                }
            }
        }
    }

    Process {
        id: actionProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                if (output.length > 0) {
                    const lines = output.split("\n");
                    root.statusText = lines[lines.length - 1];
                    root.statusIsError = false;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                if (output.length > 0) {
                    root.statusText = output;
                    root.statusIsError = true;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && !root.statusIsError)
                root.statusText = "Action completed";
            else if (exitCode !== 0)
                root.statusIsError = true;
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Add wallpaper directory"
        onAccepted: root.addWallpaperDirectory(root.normalizePathFromUrl(selectedFolder))
    }

    FloatingWindow {
        id: settingsWindow
        visible: true
        title: "Aarav Settings"
        implicitWidth: 1120
        implicitHeight: 760
        minimumSize: Qt.size(900, 620)
        maximumSize: Qt.size(1600, 1000)
        color: "transparent"

        surfaceFormat.opaque: false

        onClosed: Qt.quit()

        Rectangle {
            anchors.fill: parent
            color: colors.background
            radius: 22
            border.width: 1
            border.color: colors.outlineVariant

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    color: colors.surfaceLow
                    radius: 22

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 22
                        color: parent.color
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: settingsWindow.startSystemMove()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 16
                        spacing: 14

                        Rectangle {
                            implicitWidth: 42
                            implicitHeight: 42
                            radius: 13
                            color: colors.primaryContainer

                            Text {
                                anchors.centerIn: parent
                                text: "󰒓"
                                color: colors.onPrimaryContainer
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: 21
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Aarav Settings"
                                color: colors.onSurface
                                font.family: "Noto Sans"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: dirty ? "Unsaved changes" : "Desktop control center"
                                color: dirty ? colors.primary : colors.onSurfaceVariant
                                font.family: "Noto Sans"
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            implicitWidth: Math.min(360, statusLabel.implicitWidth + 20)
                            Layout.maximumWidth: 360
                            implicitHeight: 32
                            radius: 11
                            color: statusIsError
                                ? Qt.rgba(colors.error.r, colors.error.g, colors.error.b, 0.20)
                                : colors.surfaceContainer
                            border.width: 1
                            border.color: statusIsError ? colors.error : colors.outlineVariant

                            Text {
                                id: statusLabel
                                anchors.centerIn: parent
                                text: statusText
                                color: statusIsError ? colors.error : colors.onSurfaceVariant
                                font.family: "Noto Sans"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Button {
                            id: closeButton
                            implicitWidth: 42
                            implicitHeight: 42

                            contentItem: Text {
                                text: "󰅖"
                                color: colors.onSurface
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 12
                                color: closeButton.hovered
                                    ? Qt.rgba(colors.error.r, colors.error.g, colors.error.b, 0.24)
                                    : colors.surfaceContainer
                                border.width: 1
                                border.color: closeButton.hovered ? colors.error : colors.outlineVariant
                            }

                            onClicked: Qt.quit()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.preferredWidth: 218
                        Layout.fillHeight: true
                        color: colors.surfaceLow

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 7

                            Repeater {
                                model: root.pageNames

                                NavigationButton {
                                    required property int index
                                    required property string modelData

                                    text: modelData
                                    iconText: root.pageIcons[index]
                                    selected: root.currentPage === index
                                    onClicked: root.currentPage = index
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
