                                            implicitHeight: 48
                                            radius: 12
                                            color: colors.surfaceHigh

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 8
                                                spacing: 10

                                                Text {
                                                    text: "󰉋"
                                                    color: colors.primary
                                                    font.family: "Symbols Nerd Font Mono"
                                                    font.pixelSize: 17
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData
                                                    color: colors.onSurface
                                                    font.family: "Noto Sans"
                                                    font.pixelSize: 13
                                                    elide: Text.ElideMiddle
                                                }

                                                Button {
                                                    id: removeButton
                                                    implicitWidth: 34
                                                    implicitHeight: 34

                                                    contentItem: Text {
                                                        text: "󰩴"
                                                        color: colors.onSurfaceVariant
                                                        font.family: "Symbols Nerd Font Mono"
                                                        font.pixelSize: 15
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }

                                                    background: Rectangle {
                                                        radius: 9
                                                        color: removeButton.hovered
                                                            ? Qt.rgba(colors.error.r, colors.error.g, colors.error.b, 0.18)
                                                            : "transparent"
                                                    }

                                                    onClicked: root.removeWallpaperDirectory(index)
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        TextField {
                                            id: directoryField
                                            Layout.fillWidth: true
                                            placeholderText: "/path/to/wallpapers or ~/Pictures/Wallpapers"
                                            color: colors.onSurface
                                            placeholderTextColor: colors.onSurfaceVariant
                                            selectByMouse: true

                                            background: Rectangle {
                                                radius: 11
                                                color: colors.surfaceHigh
                                                border.width: 1
                                                border.color: directoryField.activeFocus
                                                    ? colors.primary
                                                    : colors.outlineVariant
                                            }

                                            onAccepted: {
                                                root.addWallpaperDirectory(text);
                                                text = "";
                                            }
                                        }

                                        SecondaryButton {
                                            text: "Add"
                                            iconText: "󰐕"
                                            onClicked: {
                                                root.addWallpaperDirectory(directoryField.text);
                                                directoryField.text = "";
                                            }
                                        }

                                        SecondaryButton {
                                            text: "Browse"
                                            iconText: "󰉋"
                                            onClicked: folderDialog.open()
                                        }
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Dynamic color generation"

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            Text {
                                                text: "Color mode"
                                                color: colors.onSurface
                                                font.family: "Noto Sans"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                            }

                                            ComboBox {
                                                Layout.fillWidth: true
                                                model: ["dark", "light"]
                                                currentIndex: model.indexOf(root.wallpaperMode)
                                                onActivated: index => {
                                                    root.wallpaperMode = model[index];
                                                    root.markDirty();
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            Text {
                                                text: "Material scheme"
                                                color: colors.onSurface
                                                font.family: "Noto Sans"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                            }

                                            ComboBox {
                                                Layout.fillWidth: true
                                                model: root.schemeNames
                                                currentIndex: model.indexOf(root.wallpaperScheme)
                                                onActivated: index => {
                                                    root.wallpaperScheme = model[index];
                                                    root.markDirty();
                                                }
                                            }
                                        }
                                    }

                                    SliderSetting {
                                        title: "Image source color index"
                                        description: "Usually leave this at zero. Higher values choose another extracted image color."
                                        from: 0
                                        to: 15
                                        currentValue: root.wallpaperSourceIndex
                                        onValueEdited: value => { root.wallpaperSourceIndex = Math.round(value); root.markDirty(); }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: currentWallpaperText.implicitHeight + 26
                                        radius: 12
                                        color: colors.surfaceHigh

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            Text {
                                                text: "Current wallpaper"
                                                color: colors.onSurfaceVariant
                                                font.family: "Noto Sans"
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                id: currentWallpaperText
                                                Layout.fillWidth: true
                                                text: root.systemInfo.current_wallpaper || "Not detected"
                                                color: colors.onSurface
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
                                                elide: Text.ElideMiddle
                                            }
                                        }
                                    }

                                    PrimaryButton {
                                        text: "Save and choose wallpaper"
                                        iconText: "󰸉"
                                        onClicked: root.saveSettings("wallpaper")
                                    }
                                }

                                Item { implicitHeight: 8 }
                            }
                        }

                        ScrollView {
                            id: launcherScroll
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: launcherScroll.availableWidth
                                spacing: 14

                                Item { implicitHeight: 4 }

                                Text {
                                    Layout.leftMargin: 20
                                    text: "Launcher"
                                    color: colors.onSurface
                                    font.family: "Noto Sans"
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    text: "Tune Super + Space without editing Fuzzel files. Wallpaper color generation remains intact."
                                    color: colors.onSurfaceVariant
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Launcher geometry"

                                    SliderSetting {
                                        title: "Width"
                                        from: 32
                                        to: 80
                                        currentValue: root.launcherWidth
                                        onValueEdited: value => { root.launcherWidth = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Visible rows"
                                        from: 4
                                        to: 18
                                        currentValue: root.launcherLines
                                        onValueEdited: value => { root.launcherLines = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
