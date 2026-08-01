                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    text: "Machine profile details and safe maintenance actions. Display mode and GPU boot configuration are intentionally read-only here."
                                    color: colors.onSurfaceVariant
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                GridLayout {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 12
                                    rowSpacing: 12

                                    InfoChip {
                                        label: "Profile"
                                        value: root.systemInfo.profile || "unknown"
                                    }

                                    InfoChip {
                                        label: "GPU"
                                        value: root.systemInfo.gpu || "unknown"
                                    }

                                    InfoChip {
                                        label: "Monitor"
                                        value: root.systemInfo.monitor || "unknown"
                                    }

                                    InfoChip {
                                        label: "Display mode"
                                        value: root.systemInfo.monitor_mode || "unknown"
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Desktop maintenance"
                                    description: "These actions do not rewrite your saved settings."

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 9

                                        SecondaryButton {
                                            text: "Reload Hyprland"
                                            iconText: "󰑐"
                                            onClicked: root.runAction(["hyprctl", "reload"], "Reloading Hyprland…")
                                        }

                                        SecondaryButton {
                                            text: "Restart Waybar"
                                            iconText: "󰕰"
                                            onClicked: root.runAction(
                                                ["systemctl", "--user", "restart", "waybar.service"],
                                                "Restarting Waybar…"
                                            )
                                        }

                                        SecondaryButton {
                                            text: "Toggle gaming mode"
                                            iconText: "󰊴"
                                            onClicked: root.runAction(
                                                [root.homePath + "/.local/bin/gaming-mode", "toggle"],
                                                "Toggling gaming mode…"
                                            )
                                        }

                                        SecondaryButton {
                                            text: "Notification center"
                                            iconText: "󰂚"
                                            onClicked: root.runAction(
                                                ["swaync-client", "-t", "-sw"],
                                                "Opening notification center…"
                                            )
                                        }

                                        SecondaryButton {
                                            text: "Run desktop health check"
                                            iconText: "󰓙"
                                            onClicked: root.runAction(
                                                [root.homePath + "/.local/bin/hypr-health"],
                                                "Running health check…"
                                            )
                                        }
                                    }
                                }

                                SettingCard {
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20
                                    title: "Reset"
                                    description: "Restore the desktop settings controlled by this panel. Your wallpaper files and repository are not deleted."

                                    SecondaryButton {
                                        text: "Restore panel defaults"
                                        iconText: "󰁯"
                                        onClicked: {
                                            root.statusText = "Restoring defaults…";
                                            root.statusIsError = false;
                                            resetProcess.exec(["python", root.managerPath, "reset"]);
                                        }
                                    }
                                }

                                Item { implicitHeight: 8 }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: colors.surfaceLow

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: dirty
                                ? "Changes are local until you press Save settings."
                                : "Settings are saved outside the generated config, so wallpaper changes will not erase them."
                            color: dirty ? colors.primary : colors.onSurfaceVariant
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        SecondaryButton {
                            text: "Reload saved"
                            iconText: "󰑐"
                            enabled: !loadProcess.running && !saveProcess.running
                            onClicked: loadProcess.running = true
                        }

                        PrimaryButton {
                            text: dirty ? "Save settings" : "Settings saved"
                            iconText: dirty ? "󰆓" : "󰄬"
                            enabled: loaded && !saveProcess.running
                            onClicked: root.saveSettings("")
                        }
                    }
                }
            }
        }
    }
}
