import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
using Toybox.Position;
using Toybox.System;
using Toybox.Application.Storage;
using Toybox.Attention;

class DistanceWanderedView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    // var positions;
    var lastAwake;
    const wakeInterval = 15; // TODO: configure
    const minFreeSpace = 70000;   // TODO: guesswork

    function initialize() {
        DataField.initialize();
        lastAwake = Time.now();
        mValue = 0.0f;
        Application.Storage.setValue("connected", true);
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label") as Text;
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value") as Text;
            valueView.locY = valueView.locY + 7;
        }

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    function compute(info as Activity.Info) as Void {
        var howLongAwake = Time.now().compare(lastAwake);
        if (howLongAwake >= wakeInterval) {
            lastAwake = Time.now();
            var here = Position.getInfo();
            var accuracy = here.accuracy;
            var currentPosition = here.position;
            // var timeInfo = Gregorian.info(here.when, Time.FORMAT_MEDIUM);
            // System.println("waking up inside compute @ " + 
            //     currentPosition.toGeoString(Position.GEO_DEG) + " @ " + 
            //     Lang.format("$1$:$2$:$3$", [timeInfo.hour, timeInfo.min.format("%02d"), timeInfo.sec.format("%02d")]));
            if (currentPosition != null && accuracy > Position.QUALITY_LAST_KNOWN && System.getSystemStats().freeMemory > minFreeSpace) {
                // don't add default coords under simulator
                var coords = currentPosition.toDegrees();
                if (coords[0] <  179.999999d && coords[1] < 179.999999d) {
                    var positions = Application.Storage.getValue("positions");
                    // System.println("Adding position " + currentPosition.toDegrees());
                    positions.add(coords);
                    Application.Storage.setValue("positions", positions);
                    // System.println("The array size is now " + positions.size());
                }
            } else if (System.getSystemStats().freeMemory < minFreeSpace) {
                // alert when there is insufficient free space to add points
                Attention.playTone(Attention.TONE_INTERVAL_ALERT);
            }
        }

    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        var label = View.findDrawableById("label") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
            label.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        try {
            if (Application.Storage.getValue("connected") == false) {
                label.setColor(Graphics.COLOR_RED);
            }
        } catch (ex) {
            System.println("Error while fetching connected value " + ex);
        }
        value.setText(milesWandered.format("%.2f") + " miles");
        if (Application.Storage.getValue("pending")) {
            value.setColor(Graphics.COLOR_LT_GRAY);
        }
        if (Application.Storage.getValue("error")) {
            value.setText("Error " + Application.Storage.getValue("error").toString());
            value.setColor(Graphics.COLOR_RED);
        }
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
