using Toybox.System;
using Toybox.WatchUi;
using Toybox.Background;
using Toybox.Time.Gregorian;
using Toybox.Application.Storage;
using Toybox.Attention;

class TouchDelegate extends WatchUi.BehaviorDelegate {
    var positions;

    // (:background)
    function initialize(Positions) {
        BehaviorDelegate.initialize();
        positions = Positions;
    }

    function onTap(clickEvent) {
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
            System.println(
                Lang.format("Will send request at $1$:$2$:$3$ with $4$ positions", 
                    [info.hour, info.min.format("%02d"), info.sec.format("%02d"), positions.size()]));
            var connectionInfo = System.getDeviceSettings().connectionInfo;
            var phoneIsConnected = connectionInfo.hasKey(:bluetooth) && connectionInfo.get(:bluetooth).state == System.CONNECTION_STATE_CONNECTED;
            Application.Storage.setValue("connected", phoneIsConnected);
            var connected = System.getDeviceSettings().phoneConnected;
            if (!connected || !phoneIsConnected) {
                System.println("Phone not connected");
                Attention.playTone(Attention.TONE_CANARY);
                return true;
            }
            if (positions.size() == 0) {
                Attention.playTone(Attention.TONE_FAILURE);
                return true;
            }
            System.println("Setting positions into storage");
            Application.Storage.setValue("positions", positions);
            Application.Storage.setValue("pending", true);
            Background.registerForTemporalEvent(when);
        }
        return true;
    }
}