                                        title: "Font size"
                                        from: 10
                                        to: 22
                                        currentValue: root.launcherFontSize
                                        onValueEdited: value => { root.launcherFontSize = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Row height"
                                        from: 18
                                        to: 44
                                        currentValue: root.launcherLineHeight
                                        onValueEdited: value => { root.launcherLineHeight = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Horizontal padding"
                                        from: 4
                                        to: 40
                                        currentValue: root.launcherHorizontalPad
                                        onValueEdited: value => { root.launcherHorizontalPad = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Vertical padding"
                                        from: 4
                                        to: 30
                                        currentValue: root.launcherVerticalPad
                                        onValueEdited: value => { root.launcherVerticalPad = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Row spacing"
                                        from: 2
                                        to: 24
                                        currentValue: root.launcherInnerPad
                                        onValueEdited: value => { root.launcherInnerPad = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Outer corner radius"
                                        from: 0
                                        to: 32
                                        currentValue: root.launcherRadius
                                        onValueEdited: value => { root.launcherRadius = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Selected row radius"
                                        from: 0
                                        to: 24
                                        currentValue: root.launcherSelectionRadius
                                        onValueEdited: value => { root.launcherSelectionRadius = Math.round(value); root.markDirty(); }
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Live shape preview"
                                    description: "This previews density and proportions; the real launcher uses current wallpaper colors and application icons."

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: Math.min(620, 280 + root.launcherWidth * 5)
                                        implicitHeight: 92 + Math.min(root.launcherLines, 5) * 34
                                        radius: root.launcherRadius
                                        color: colors.surfaceHigh
                                        border.width: 2
                                        border.color: colors.primary

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Math.max(8, root.launcherHorizontalPad / 2)
                                            spacing: Math.max(3, root.launcherInnerPad / 2)

                                            Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: 38
                                                radius: 11
                                                color: colors.surfaceHighest

                                                Text {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "   Search applications"
                                                    color: colors.onSurfaceVariant
                                                    font.family: "Noto Sans, Symbols Nerd Font Mono"
                                                    font.pixelSize: root.launcherFontSize
                                                }
                                            }

                                            Repeater {
                                                model: Math.min(root.launcherLines, 5)

                                                Rectangle {
                                                    required property int index
                                                    Layout.fillWidth: true
                                                    implicitHeight: Math.max(26, root.launcherLineHeight)
                                                    radius: index === 0 ? root.launcherSelectionRadius : 8
                                                    color: index === 0 ? colors.primaryContainer : "transparent"

                                                    Text {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 12
                                                        verticalAlignment: Text.AlignVCenter
                                                        text: ["Zen Browser", "Kitty", "Dolphin", "Spotify", "Discord"][index]
                                                        color: index === 0 ? colors.onPrimaryContainer : colors.onSurface
                                                        font.family: "Noto Sans"
                                                        font.pixelSize: root.launcherFontSize
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Item { implicitHeight: 8 }
                            }
                        }

                        ScrollView {
                            id: inputScroll
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: inputScroll.availableWidth
                                spacing: 14

                                Item { implicitHeight: 4 }

                                Text {
                                    Layout.leftMargin: 20
                                    text: "Input & behavior"
                                    color: colors.onSurface
                                    font.family: "Noto Sans"
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    text: "Adjust mouse focus and pointer sensitivity. Hardware-specific monitor settings stay protected."
                                    color: colors.onSurfaceVariant
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Pointer"

                                    ToggleSetting {
                                        title: "Focus follows mouse"
                                        description: "Moving the pointer into a window focuses it"
                                        currentValue: root.followMouse
                                        onValueEdited: value => { root.followMouse = value; root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Mouse sensitivity"
                                        description: "Hyprland sensitivity from -1.00 to +1.00"
                                        from: -1
                                        to: 1
                                        stepSize: 0.05
                                        decimals: 2
                                        currentValue: root.mouseSensitivity
                                        onValueEdited: value => { root.mouseSensitivity = value; root.markDirty(); }
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Panel behavior"

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 96
                                        radius: 13
                                        color: colors.surfaceHigh

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 14

                                            Text {
                                                text: "󰌌"
                                                color: colors.primary
                                                font.family: "Symbols Nerd Font Mono"
                                                font.pixelSize: 24
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text {
                                                    text: "Super + comma opens or focuses this panel"
                                                    color: colors.onSurface
                                                    font.family: "Noto Sans"
                                                    font.pixelSize: 14
                                                    font.weight: Font.Medium
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: "It remains open like a normal application. Super + Q or the close button exits it."
                                                    color: colors.onSurfaceVariant
                                                    font.family: "Noto Sans"
                                                    font.pixelSize: 12
                                                    wrapMode: Text.WordWrap
                                                }
                                            }
                                        }
                                    }
                                }

                                Item { implicitHeight: 8 }
                            }
                        }

                        ScrollView {
                            id: systemScroll
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: systemScroll.availableWidth
                                spacing: 14

                                Item { implicitHeight: 4 }

                                Text {
                                    Layout.leftMargin: 20
                                    text: "System"
                                    color: colors.onSurface
                                    font.family: "Noto Sans"
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.leftMargin: 20
