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

    var menuItem;

    function initialize(parentMenuItem as MenuItem) {
        TextPickerDelegate.initialize();
        menuItem = parentMenuItem;
    }

    function onTextEntered(text, changed) {
        if (changed) {
            System.println("Setting key to " + text);
            Application.Properties.setValue("key", text);
            menuItem.setSubLabel(text);
        }
        lastText = text;
        return true;
    }

    function onCancel() {
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
        menu.addItem(
            new MenuItem(
                "Wandrer.earth key",
                keyText,
                "key",
                {}
            )
        );
        menu.addItem(
            new MenuItem("Notification distance", "Alert after this many miles", "notifyDistance", {}));
        var currentType = Properties.getValue("activityType");
        menu.addItem(
            new ToggleMenuItem("Bicycling", "type of activity", "bike", currentType==1, {}));
        menu.addItem(
            new ToggleMenuItem("Walking", "type of activity", "walk", currentType==2, {}));

        WatchUi.pushView(menu, new $.DataFieldSettingsMenuDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

