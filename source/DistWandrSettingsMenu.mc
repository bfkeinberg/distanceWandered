// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application.Properties;

//! The settings menu
class DataFieldSettingsMenu extends WatchUi.Menu2 {

    //! Constructor
    public function initialize() {
        Menu2.initialize({:title=>"Settings"});
    }
}

//! Handles menu input and stores the menu data
class DataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    var keyText;
    var parentMenu;
    //! Constructor
    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();
        keyText = Application.Properties.getValue("key");
        parentMenu = menu;
    }

    //! Handle a menu item selection
    //! @param menuItem The selected menu item
    public function onSelect(menuItem as MenuItem) as Void {
        var toggleItem = menuItem as ToggleMenuItem;
        var id = menuItem.getId();
        if (id.equals("bike")) {
            var walkItemIndex = parentMenu.findItemById("walk");
            var walkItem = parentMenu.getItem(walkItemIndex) as ToggleMenuItem;
            if (toggleItem.isEnabled()) {
                Properties.setValue("activityType", 1);
                walkItem.setEnabled(false);
            } else {
                Properties.setValue("activityType", 2);
                walkItem.setEnabled(true);
            }
        }
        if (id.equals("walk")) {
            var bikeItemIndex = parentMenu.findItemById("bike");
            var bikeItem = parentMenu.getItem(bikeItemIndex) as ToggleMenuItem;
            if (toggleItem.isEnabled()) {
                Properties.setValue("activityType", 2);
                bikeItem.setEnabled(false);
            } else {
                Properties.setValue("activityType", 1);
                bikeItem.setEnabled(true);
            }
        }
        if (id.equals("notifyDistance")) {
            var notificationDistance = Application.Properties.getValue("notificationDistance");
            WatchUi.pushView(
                new $.NumberPicker(notificationDistance), 
                new $.NumberPickerDelegate(), 
                WatchUi.SLIDE_UP
            );
        }
        if (id.equals("key")) {
            keyText = Application.Properties.getValue("key");
            WatchUi.pushView(
                new WatchUi.TextPicker(keyText),
                new MyTextPickerDelegate(menuItem),
                WatchUi.SLIDE_DOWN
            );
        }
    }
}

