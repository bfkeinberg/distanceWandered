import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
using Toybox.Position;
using Toybox.System;
using Toybox.Application.Storage;
using Toybox.Attention;
using Toybox.Background;
using Toybox.FitContributor;

class DistanceWanderedView extends WatchUi.DataField {

    var lastAwake;
    const wakeInterval = 12; // TODO: configure
    var dropping = false;
    const WANDERED_MILES_FIELD_ID = 0;

    function initialize() {
        DataField.initialize();
        lastAwake = Time.now();
        Application.Storage.clearValues();
        setFirstPosition();
        Application.Storage.setValue("bucketNum", 0);
        Application.Storage.setValue("connected", true);
        newMilesField = createField("WanderedMiles", WANDERED_MILES_FIELD_ID, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"miles"});
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

    function setFirstPosition() as Void {
        var here = Position.getInfo();
        var currentPosition = here.position;
        var accuracy = here.accuracy;
        var inDegrees = currentPosition.toDegrees();
        var positions = [] as positionChunk;
        if (currentPosition != null && accuracy > Position.QUALITY_LAST_KNOWN && (inDegrees[0] < 179.999999d)) {
            positions.add(currentPosition.toDegrees());
        }
        Application.Storage.setValue("bucket_0", positions);
    }

    function addPosition(position as coords) {
        var whichBucket = Application.Storage.getValue("bucketNum");
        var positions = Application.Storage.getValue("bucket_" + whichBucket) as positionChunk;
        if (positions == null) {
            // if we've tapped on the field before flipping buckets at least once
            positions = new positionChunk[0];
        }
        else if (positions.size() > maxChunkSize) {
            positions = Application.Storage.getValue("bucket_" + whichBucket) ;
            var lastTrigger = Background.getTemporalEventRegisteredTime();
            var pendingEvent = (lastTrigger != null) && (Time.now().compare(lastTrigger) <= 0);
            // flip buckets?
            if (!pendingEvent) {
                if (whichBucket == 1) {
                    whichBucket = 0;
                } else {
                    whichBucket = 1;
                }
                var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
                System.println(
                    Lang.format("Switching to bucket $4$ because size of bucket $6$ was $5$ points and triggering call to Wandrer at $7$/$8$/$9$ $1$:$2$:$3$", 
                        [nowInfo.hour, 
                        nowInfo.min.format("%02d"), 
                        nowInfo.sec.format("%02d"), 
                        whichBucket, 
                        positions.size(),
                        Application.Storage.getValue("bucketNum"),
                        nowInfo.month,
                        nowInfo.day,
                        nowInfo.year
                        ]));
                        // force clear
                //Application.Storage.setValue("bucket_" + whichBucket, []);
                positions = new positionChunk[0];
                Application.Storage.setValue("bucketNum", whichBucket);
                // ensure that we don't try to trigger background event until five minutes past the prior one
                var when = Time.now();
                var lastTimeRun = Background.getLastTemporalEventTime();
                if (lastTimeRun != null) {
                    when = lastTimeRun.add(new Time.Duration(300));
                }
                // System.println("registering for temporal event from addPosition");
                Application.Storage.setValue("pending", true);
                Background.registerForTemporalEvent(when);
            } else {
                var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
                var lastTriggerTime = Gregorian.info(lastTrigger, Time.FORMAT_MEDIUM);
                if (!dropping) {
                    System.println(
                        Lang.format("Too many positions ($8$) in bucket $7$ to record at $1$:$2$:$3$, event trigger time is $4$:$5$:$6$", 
                            [
                                nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d"),
                                lastTriggerTime.hour, lastTriggerTime.min.format("%02d"), lastTriggerTime.sec.format("%02d"),
                                whichBucket,
                                Application.Storage.getValue("bucket_" + whichBucket).size()
                            ]));
                    Attention.playTone(Attention.TONE_ALERT_HI);
                    dropping = true;
                }
                return;
            }
        }
        dropping = false;
        positions.add(position);
        Application.Storage.setValue("bucket_" + whichBucket, positions);
    }

    function compute(info as Activity.Info) as Void {
        // don't count distance until an activity is started
        var actInfo = Activity.getActivityInfo();
        if (actInfo == null || actInfo.timerState == Activity.TIMER_STATE_OFF || actInfo.timerState == Activity.TIMER_STATE_STOPPED) {
            return;
        }
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

            if (currentPosition != null && accuracy > Position.QUALITY_LAST_KNOWN) {
                // don't add default coords under simulator
                var coords = currentPosition.toDegrees();
                if (coords[0] <  179.999999d && coords[1] < 179.999999d) {
                    // System.println("Adding position " + currentPosition.toDegrees());
                    addPosition(coords);
                }
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
            label.setColor(Graphics.COLOR_BLACK);
        }
        // set background to pink if the default wandrer key has not been changed
        if (Application.Properties.getValue("key").equals("my-wandrer.earth-key")) {
            (View.findDrawableById("Background") as Text).setColor(Graphics.COLOR_PINK);
        }
        if (Application.Storage.getValue("connected") == false) {
            label.setColor(Graphics.COLOR_RED);
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
