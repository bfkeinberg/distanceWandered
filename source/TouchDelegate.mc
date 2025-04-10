using Toybox.System;
using Toybox.WatchUi;
using Toybox.Background;
using Toybox.Time.Gregorian;
using Toybox.Application.Storage;
using Toybox.Attention;
import Toybox.Activity;
import Toybox.Graphics;

class DataFieldAlertView extends WatchUi.DataFieldAlert {

    var message;

    //! Constructor
    public function initialize(_message) {
        DataFieldAlert.initialize();
        message = _message;
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_SMALL, message, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class TouchDelegate extends WatchUi.BehaviorDelegate {

    // (:background)
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(clickEvent) {
        // don't do anything with the tap if no activity is running
        var actInfo = Activity.getActivityInfo();
        if (actInfo == null || actInfo.timerState == Activity.TIMER_STATE_OFF || actInfo.timerState == Activity.TIMER_STATE_STOPPED) {
            return false;
        }
        if (clickEvent.getType() == CLICK_TYPE_TAP) {
            var when = Time.now().subtract(Gregorian.duration({:minutes => 5}));
            var lastTimeRun = Background.getLastTemporalEventTime();
            if (lastTimeRun != null) {
                when = lastTimeRun.add(new Time.Duration(300));
            }
            var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            System.println(
                Lang.format("Tapped at $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
            var info = Gregorian.info(when, Time.FORMAT_MEDIUM);
            var connectionInfo = System.getDeviceSettings().connectionInfo;
            var phoneIsConnected = connectionInfo.hasKey(:bluetooth) && connectionInfo.get(:bluetooth).state == System.CONNECTION_STATE_CONNECTED;
            Application.Storage.setValue("connected", phoneIsConnected);
            var connected = System.getDeviceSettings().phoneConnected;
            if (!connected || !phoneIsConnected) {
                System.println("Phone not connected at " + info.hour + ":" + info.min.format("%02d"));
                Attention.playTone(Attention.TONE_CANARY);
                if (WatchUi.DataField has :showAlert) {
                    WatchUi.DataField.showAlert(new $.DataFieldAlertView("Phone not connected"));
                }
                return true;
            }
            if (Application.Properties.getValue("key").equals("my-wandrer.earth-key")) {
                Attention.playTone(Attention.TONE_CANARY);
                if (WatchUi.DataField has :showAlert) {
                    WatchUi.DataField.showAlert(new $.DataFieldAlertView("Key not configured"));
                }
                return true;
            }
            // don't trigger background event if already scheduled
            var lastTemporalEvent = Background.getTemporalEventRegisteredTime();
            if (lastTemporalEvent == null || Time.now().compare(lastTemporalEvent) >= 0) {
                var whichBucket = Application.Storage.getValue("bucketNum");
                var positions = Application.Storage.getValue("bucket_" + whichBucket) as positionChunk;
                if (positions == null || !(positions instanceof Lang.Array) || positions.size() < 2) {
                    System.println("No positions, returning from tap");
                    Attention.playTone(Attention.TONE_ALERT_LO);
                    return true;
                }
                System.println(
                    Lang.format("Scheduling request for $4$/$5$/$6$ $1$:$2$:$3$", 
                        [
                            info.hour, info.min.format("%02d"), info.sec.format("%02d"),
                            info.month, info.day, info.year
                        ]
                    )
                );
                // flip the buckets, so that any positions stored while waiting for this event
                // will be stored in the other bucket
                // Since no event is scheduled the contents of the other bucket have already been used
                Application.Storage.setValue("pending", true);
                if (whichBucket == 1) {
                    whichBucket = 0;
                } else {
                    whichBucket = 1;
                }
                Application.Storage.setValue("bucketNum", whichBucket);
                // System.println("registering for temporal event");
                Background.registerForTemporalEvent(when);
            } else {
                // notify user that nothing will happen
                Attention.playTone(Attention.TONE_TIME_ALERT);
            }
        }
        return true;
    }
}