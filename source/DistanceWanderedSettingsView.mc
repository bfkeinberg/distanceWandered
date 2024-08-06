//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application.Properties;

//! Initial view for the settings
class DistanceWanderedSettingsView extends WatchUi.View {

    //! Constructor
    public function initialize() {
        View.initialize();
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_SMALL, "Press Menu \nfor settings", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

var lastText;

class MyTextPickerDelegate extends WatchUi.TextPickerDelegate {

    function initialize() {
        TextPickerDelegate.initialize();
    }

    function onTextEntered(text, changed) {
        if (changed) {
            System.println("Setting key to " + text);
            Application.Properties.setValue("key", text);
        }
        lastText = text;
        return true;
    }

    function onCancel() {
        System.println("Text entry canceled");
        return true;
    }
}

//! Handle opening the settings menu
class DataFieldSettingsDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    public function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle the menu event
    //! @return true if handled, false otherwise
    public function onMenu() as Boolean {
        var keyText = Application.Properties.getValue("key");
        var menu = new $.DataFieldSettingsMenu();
        var displayCyclingDistance = Properties.getValue("isRide") ? true : false;
        menu.addItem(new WatchUi.ToggleMenuItem("Cycle or walk distance", null, "bike", displayCyclingDistance, null));
        menu.addItem(
            new MenuItem(
                "Wandrer.earth key",
                keyText,
                "key",
                {}
            )
        );

        WatchUi.pushView(menu, new $.DataFieldSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

