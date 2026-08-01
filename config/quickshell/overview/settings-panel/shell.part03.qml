                                implicitHeight: shortcutColumn.implicitHeight + 24
                                radius: 14
                                color: colors.surfaceContainer
                                border.width: 1
                                border.color: colors.outlineVariant

                                ColumnLayout {
                                    id: shortcutColumn
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    Text {
                                        text: "Shortcuts"
                                        color: colors.onSurface
                                        font.family: "Noto Sans"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: "Super + ,   Open settings\nSuper + Q   Close settings"
                                        color: colors.onSurfaceVariant
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        lineHeight: 1.35
                                    }
                                }
                            }
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.currentPage

                        ScrollView {
                            id: appearanceScroll
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: appearanceScroll.availableWidth
                                spacing: 14

                                Item { implicitHeight: 4 }

                                Text {
                                    Layout.leftMargin: 20
                                    text: "Appearance"
                                    color: colors.onSurface
                                    font.family: "Noto Sans"
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    text: "Control spacing, window shape, transparency, blur, shadows, and motion. Changes apply live after Save."
                                    color: colors.onSurfaceVariant
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Layout"
                                    description: "These settings override the defaults without modifying the portable source files."

                                    SliderSetting {
                                        title: "Inner gaps"
                                        description: "Space between tiled windows"
                                        from: 0
                                        to: 30
                                        currentValue: root.gapsIn
                                        onValueEdited: value => { root.gapsIn = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Outer gaps"
                                        description: "Space between windows and monitor edges"
                                        from: 0
                                        to: 50
                                        currentValue: root.gapsOut
                                        onValueEdited: value => { root.gapsOut = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Border size"
                                        from: 0
                                        to: 8
                                        currentValue: root.borderSize
                                        onValueEdited: value => { root.borderSize = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Corner rounding"
                                        from: 0
                                        to: 30
                                        currentValue: root.rounding
                                        onValueEdited: value => { root.rounding = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Active opacity"
                                        from: 0.60
                                        to: 1.0
                                        stepSize: 0.01
                                        decimals: 2
                                        currentValue: root.activeOpacity
                                        onValueEdited: value => { root.activeOpacity = value; root.markDirty(); }
                                    }

                                    SliderSetting {
                                        title: "Inactive opacity"
                                        from: 0.50
                                        to: 1.0
                                        stepSize: 0.01
                                        decimals: 2
                                        currentValue: root.inactiveOpacity
                                        onValueEdited: value => { root.inactiveOpacity = value; root.markDirty(); }
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Effects"

                                    ToggleSetting {
                                        title: "Animations"
                                        description: "Disable for the lowest latency and simplest motion"
                                        currentValue: root.animationsEnabled
                                        onValueEdited: value => { root.animationsEnabled = value; root.markDirty(); }
                                    }

                                    ToggleSetting {
                                        title: "Blur"
                                        description: "Controls transparent window and overlay blur"
                                        currentValue: root.blurEnabled
                                        onValueEdited: value => { root.blurEnabled = value; root.markDirty(); }
                                    }

                                    SliderSetting {
                                        enabled: root.blurEnabled
                                        opacity: enabled ? 1.0 : 0.45
                                        title: "Blur size"
                                        from: 1
                                        to: 20
                                        currentValue: root.blurSize
                                        onValueEdited: value => { root.blurSize = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        enabled: root.blurEnabled
                                        opacity: enabled ? 1.0 : 0.45
                                        title: "Blur passes"
                                        from: 1
                                        to: 8
                                        currentValue: root.blurPasses
                                        onValueEdited: value => { root.blurPasses = Math.round(value); root.markDirty(); }
                                    }

                                    SliderSetting {
                                        enabled: root.blurEnabled
                                        opacity: enabled ? 1.0 : 0.45
                                        title: "Blur vibrancy"
                                        from: 0
                                        to: 1
                                        stepSize: 0.01
                                        decimals: 2
                                        currentValue: root.blurVibrancy
                                        onValueEdited: value => { root.blurVibrancy = value; root.markDirty(); }
                                    }

                                    ToggleSetting {
                                        title: "Window shadows"
                                        currentValue: root.shadowEnabled
                                        onValueEdited: value => { root.shadowEnabled = value; root.markDirty(); }
                                    }

                                    SliderSetting {
                                        enabled: root.shadowEnabled
                                        opacity: enabled ? 1.0 : 0.45
                                        title: "Shadow range"
                                        from: 1
                                        to: 20
                                        currentValue: root.shadowRange
                                        onValueEdited: value => { root.shadowRange = Math.round(value); root.markDirty(); }
                                    }

                                    ToggleSetting {
                                        title: "Dim inactive windows"
                                        currentValue: root.dimInactive
                                        onValueEdited: value => { root.dimInactive = value; root.markDirty(); }
                                    }

                                    SliderSetting {
                                        enabled: root.dimInactive
                                        opacity: enabled ? 1.0 : 0.45
                                        title: "Inactive dim strength"
                                        from: 0
                                        to: 0.50
                                        stepSize: 0.01
                                        decimals: 2
                                        currentValue: root.dimStrength
                                        onValueEdited: value => { root.dimStrength = value; root.markDirty(); }
                                    }
                                }

                                Item { implicitHeight: 8 }
                            }
                        }

                        ScrollView {
                            id: wallpaperScroll
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: wallpaperScroll.availableWidth
                                spacing: 14

                                Item { implicitHeight: 4 }

                                Text {
                                    Layout.leftMargin: 20
                                    text: "Wallpaper & color"
                                    color: colors.onSurface
                                    font.family: "Noto Sans"
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    text: "Choose exactly where Super + W searches and how Matugen builds the desktop palette."
                                    color: colors.onSurfaceVariant
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Wallpaper directories"
                                    description: "Only existing folders are searched. Add multiple locations and remove stale ones."

                                    Repeater {
                                        model: root.wallpaperDirectories

                                        Rectangle {
                                            required property int index
                                            required property string modelData

                                            Layout.fillWidth: true
