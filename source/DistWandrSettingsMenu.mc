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
    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
        keyText = Application.Properties.getValue("key");
    }

    //! Handle a menu item selection
    //! @param menuItem The selected menu item
    public function onSelect(menuItem as MenuItem) as Void {
        var id = menuItem.getId();
        System.println("Menu item selected");
        if (id.equals("bike")) {
            var theMenuItem = menuItem as ToggleMenuItem;
            System.println("Setting bike vs walk");
            Properties.setValue("isRide", theMenuItem.isEnabled());
        }
        if (id.equals("key")) {
            keyText = Application.Properties.getValue("key");
            System.println("Showing text entry with " + keyText);
            WatchUi.pushView(
                new WatchUi.TextPicker(keyText),
                new MyTextPickerDelegate(),
                WatchUi.SLIDE_DOWN
            );            
        }
    }
}
