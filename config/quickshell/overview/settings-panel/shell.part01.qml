//@ pragma AppId aarav-settings
//@ pragma ShellId aarav-settings
//@ pragma DropExpensiveFonts

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property int currentPage: 0
    property bool loaded: false
    property bool dirty: false
    property bool statusIsError: false
    property string statusText: "Loading settings…"
    property string pendingAction: ""
    property var systemInfo: ({})

    property var wallpaperDirectories: []
    property string wallpaperMode: "dark"
    property string wallpaperScheme: "scheme-expressive"
    property int wallpaperSourceIndex: 0

    property int gapsIn: 5
    property int gapsOut: 10
    property int borderSize: 2
    property int rounding: 12
    property real activeOpacity: 0.97
    property real inactiveOpacity: 0.92

    property bool blurEnabled: true
    property int blurSize: 7
    property int blurPasses: 3
    property real blurVibrancy: 0.12
    property bool animationsEnabled: true
    property bool shadowEnabled: true
    property int shadowRange: 4
    property int shadowPower: 3
    property bool dimInactive: true
    property real dimStrength: 0.08

    property int launcherWidth: 52
    property int launcherLines: 9
    property int launcherFontSize: 14
    property int launcherLineHeight: 24
    property int launcherHorizontalPad: 18
    property int launcherVerticalPad: 12
    property int launcherInnerPad: 8
    property int launcherRadius: 18
    property int launcherSelectionRadius: 10

    property bool followMouse: true
    property real mouseSensitivity: -0.40

    readonly property string homePath: Quickshell.env("HOME") || ""
    readonly property string managerPath: Quickshell.shellDir + "/settings.py"

    readonly property var pageNames: [
        "Appearance",
        "Wallpaper",
        "Launcher",
        "Input",
        "System"
    ]

    readonly property var pageIcons: [
        "󰏘",
        "󰸉",
        "󰍉",
        "󰍽",
        "󰒓"
    ]

    readonly property var schemeNames: [
        "scheme-expressive",
        "scheme-tonal-spot",
        "scheme-vibrant",
        "scheme-fidelity",
        "scheme-content",
        "scheme-monochrome",
        "scheme-neutral",
        "scheme-rainbow",
        "scheme-fruit-salad"
    ]

    Colors {
        id: colors
    }


    function pick(value, fallbackValue): var {
        return value === undefined || value === null ? fallbackValue : value;
    }

    function markDirty(): void {
        if (loaded)
            dirty = true;
    }

    function normalizePathFromUrl(url): string {
        let value = url.toString();
        if (value.startsWith("file://"))
            value = value.substring(7);
        return decodeURIComponent(value);
    }

    function addWallpaperDirectory(path): void {
        const trimmed = path.trim();
        if (!trimmed)
            return;

        const updated = wallpaperDirectories.slice();
        if (updated.indexOf(trimmed) === -1)
            updated.push(trimmed);
        wallpaperDirectories = updated;
        markDirty();
    }

    function removeWallpaperDirectory(index): void {
        const updated = wallpaperDirectories.slice();
        updated.splice(index, 1);
        wallpaperDirectories = updated;
        markDirty();
    }

    function settingsObject(): var {
        return {
            "version": 1,
            "wallpaper": {
                "directories": wallpaperDirectories,
                "mode": wallpaperMode,
                "scheme": wallpaperScheme,
                "source_color_index": wallpaperSourceIndex
            },
            "layout": {
                "gaps_in": gapsIn,
                "gaps_out": gapsOut,
                "border_size": borderSize,
                "rounding": rounding,
                "active_opacity": activeOpacity,
                "inactive_opacity": inactiveOpacity
            },
            "effects": {
                "blur_enabled": blurEnabled,
                "blur_size": blurSize,
                "blur_passes": blurPasses,
                "blur_vibrancy": blurVibrancy,
                "animations_enabled": animationsEnabled,
                "shadow_enabled": shadowEnabled,
                "shadow_range": shadowRange,
                "shadow_power": shadowPower,
                "dim_inactive": dimInactive,
                "dim_strength": dimStrength
            },
            "launcher": {
                "width": launcherWidth,
                "lines": launcherLines,
                "font_size": launcherFontSize,
                "line_height": launcherLineHeight,
                "horizontal_pad": launcherHorizontalPad,
                "vertical_pad": launcherVerticalPad,
                "inner_pad": launcherInnerPad,
                "radius": launcherRadius,
                "selection_radius": launcherSelectionRadius
            },
            "input": {
                "follow_mouse": followMouse,
                "sensitivity": mouseSensitivity
            }
        };
    }

    function loadPayload(payload): void {
        const settings = payload.settings || payload;
        const wallpaper = settings.wallpaper || {};
        const layout = settings.layout || {};
        const effects = settings.effects || {};
        const launcher = settings.launcher || {};
        const inputSettings = settings.input || {};

        wallpaperDirectories = (wallpaper.directories || []).slice();
        wallpaperMode = wallpaper.mode || "dark";
        wallpaperScheme = wallpaper.scheme || "scheme-expressive";
        wallpaperSourceIndex = pick(wallpaper.source_color_index, 0);

        gapsIn = pick(layout.gaps_in, 5);
        gapsOut = pick(layout.gaps_out, 10);
        borderSize = pick(layout.border_size, 2);
        rounding = pick(layout.rounding, 12);
        activeOpacity = pick(layout.active_opacity, 0.97);
        inactiveOpacity = pick(layout.inactive_opacity, 0.92);

        blurEnabled = pick(effects.blur_enabled, true);
        blurSize = pick(effects.blur_size, 7);
        blurPasses = pick(effects.blur_passes, 3);
        blurVibrancy = pick(effects.blur_vibrancy, 0.12);
        animationsEnabled = pick(effects.animations_enabled, true);
        shadowEnabled = pick(effects.shadow_enabled, true);
        shadowRange = pick(effects.shadow_range, 4);
        shadowPower = pick(effects.shadow_power, 3);
        dimInactive = pick(effects.dim_inactive, true);
        dimStrength = pick(effects.dim_strength, 0.08);

        launcherWidth = pick(launcher.width, 52);
        launcherLines = pick(launcher.lines, 9);
        launcherFontSize = pick(launcher.font_size, 14);
        launcherLineHeight = pick(launcher.line_height, 24);
        launcherHorizontalPad = pick(launcher.horizontal_pad, 18);
        launcherVerticalPad = pick(launcher.vertical_pad, 12);
        launcherInnerPad = pick(launcher.inner_pad, 8);
        launcherRadius = pick(launcher.radius, 18);
        launcherSelectionRadius = pick(launcher.selection_radius, 10);

        followMouse = pick(inputSettings.follow_mouse, true);
        mouseSensitivity = pick(inputSettings.sensitivity, -0.40);

        systemInfo = payload.system || ({});
        loaded = true;
        dirty = false;
    }

    function saveSettings(nextAction): void {
        pendingAction = nextAction || "";
        statusIsError = false;
        statusText = "Applying settings…";
        saveProcess.exec([
            "python",
            managerPath,
            "set-json",
            JSON.stringify(settingsObject())
        ]);
    }

    function runAction(command, progressText): void {
        statusIsError = false;
        statusText = progressText;
        actionProcess.exec(command);
    }

    component PrimaryButton: Button {
        id: control
        property string iconText: ""

        implicitHeight: 42
        leftPadding: 16
        rightPadding: 16

        contentItem: RowLayout {
            spacing: 8

            Text {
                visible: control.iconText.length > 0
                text: control.iconText
                color: colors.onPrimary
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
            }

            Text {
                text: control.text
                color: colors.onPrimary
                font.family: "Noto Sans"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        background: Rectangle {
            radius: 12
            color: control.down
                ? Qt.darker(colors.primary, 1.12)
                : control.hovered
                    ? Qt.lighter(colors.primary, 1.08)
                    : colors.primary
        }
    }

    component SecondaryButton: Button {
        id: control
        property string iconText: ""

        implicitHeight: 40
        leftPadding: 14
        rightPadding: 14

        contentItem: RowLayout {
            spacing: 8

            Text {
                visible: control.iconText.length > 0
                text: control.iconText
                color: colors.onSurface
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 16
            }

            Text {
                text: control.text
                color: colors.onSurface
                font.family: "Noto Sans"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        background: Rectangle {
            radius: 11
            color: control.down
                ? colors.surfaceHighest
                : control.hovered
                    ? colors.surfaceHigh
                    : colors.surfaceContainer
            border.width: 1
            border.color: colors.outlineVariant
        }
    }

    component NavigationButton: Button {
        id: control
        property string iconText: ""
        property bool selected: false

        implicitHeight: 48
        Layout.fillWidth: true
        leftPadding: 14
        rightPadding: 14

        contentItem: RowLayout {
            spacing: 12

            Text {
                text: control.iconText
                color: control.selected ? colors.onPrimaryContainer : colors.onSurfaceVariant
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 19
            }

            Text {
                Layout.fillWidth: true
                text: control.text
                color: control.selected ? colors.onPrimaryContainer : colors.onSurface
                font.family: "Noto Sans"
                font.pixelSize: 14
                font.weight: control.selected ? Font.DemiBold : Font.Normal
            }
        }

        background: Rectangle {
            radius: 13
            color: control.selected
                ? colors.primaryContainer
                : control.hovered
                    ? colors.surfaceHigh
                    : "transparent"
        }
    }

    component SettingCard: Rectangle {
        id: card
        property string title: ""
        property string description: ""
        default property alias contentData: cardBody.data

        Layout.fillWidth: true
        implicitHeight: cardBody.implicitHeight + 32
        radius: 18
        color: colors.surfaceContainer
        border.width: 1
        border.color: colors.outlineVariant

        ColumnLayout {
            id: cardBody
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: card.title
                color: colors.onSurface
                font.family: "Noto Sans"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Text {
                visible: card.description.length > 0
                Layout.fillWidth: true
                text: card.description
                color: colors.onSurfaceVariant
                font.family: "Noto Sans"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }

    component SliderSetting: Item {
        id: setting
        property string title: ""
        property string description: ""
        property real from: 0
        property real to: 100
        property real stepSize: 1
        property real currentValue: 0
        property int decimals: 0
        signal valueEdited(real value)

        Layout.fillWidth: true
        implicitHeight: content.implicitHeight

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

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

                Rectangle {
                    implicitWidth: valueLabel.implicitWidth + 18
                    implicitHeight: 30
                    radius: 10
                    color: colors.primaryContainer

                    Text {
                        id: valueLabel
                        anchors.centerIn: parent
                        text: setting.decimals === 0
