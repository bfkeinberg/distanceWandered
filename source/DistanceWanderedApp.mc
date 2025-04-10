import Toybox.Application;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Position;
using Toybox.Background;
using Toybox.Attention;
using Toybox.Time.Gregorian;

var milesWandered as Numeric = 0;

typedef coords as Array<Lang.Double>;
typedef positionChunk as Array<coords>;
const maxChunkSize = 80;
var newMilesField;

(:background)
class DistanceWanderedApp extends Application.AppBase {

    var inBackground = false;
    const distanceThreshold = 5;
    var tonePlayedAt = 0;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        if (state != null) {
            System.println("State: " + state.toString());
        }
        if (System.getSystemStats().totalMemory < 32000) {
/*             System.println(
                Lang.format("onStart in background at $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
 */        } else {
            var previousDistance = Application.Storage.getValue("distance");
            if (previousDistance != null) {
                if (previousDistance instanceof Lang.Float || previousDistance instanceof Lang.Number) {
                    System.println(
                        Lang.format("onStart in foreground is reusing previous accumulated distance $4$ at $5$/$6$/$7$ $1$:$2$:$3$", 
                            [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d"), 
                            previousDistance, nowInfo.month, nowInfo.day, nowInfo.year]));
                    milesWandered = previousDistance;
                }
                else {
                    System.println(
                        Lang.format("Invalid previous distance $7$, initializing miles wandered from onStart at $4$/$5$/$6$ $1$:$2$:$3$", 
                            [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d"),
                            nowInfo.month, nowInfo.day, nowInfo.year,
                            previousDistance
                            ]));
                    milesWandered = 0;
                }
            }
            else {
/*                 System.println(
                    Lang.format("No previous distance, initializing miles wandered from onStart at $4$/$5$/$6$ $1$:$2$:$3$",
                        [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d"),
                        nowInfo.month, nowInfo.day, nowInfo.year
                        ]));
 */                milesWandered = 0;
            }

            Application.Storage.clearValues();
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        // var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    	if(!inBackground) {
/*             System.println(
                Lang.format("onStop from foreground at $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
 */            // persist here as well, if an activity is running, but we may need to remove this if it persists into future runs
            var actInfo = Activity.getActivityInfo();
            if (actInfo != null && actInfo.timerState != Activity.TIMER_STATE_OFF) {
                System.println("Activity running during onStop so preserving distance of " + milesWandered);
                Application.Storage.setValue("distance", milesWandered);
            }
    		Background.deleteTemporalEvent();
    	} else {
/*             System.println(
                Lang.format("onStop from background at $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
 */        }
    }

    function getServiceDelegate(){
/*         var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        System.println(
            Lang.format("getting service delegate at $1$:$2$:$3$", 
                [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
 */    	//only called in the background	
    	inBackground = true;
        return [new DistanceWandered_ServiceDelgate()];
    }

    function onBackgroundData(data_raw as Application.PersistableType) {
        var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        if (!(data_raw instanceof Lang.Float) && !(data_raw instanceof Lang.Number)) {
            var warningMsg = Lang.format("Invalid distance $1$ returned", [data_raw]);
            var fullWarningMsg = Lang.format(
                "$7$ at $4$/$5$/$6$ $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), 
                    nowInfo.sec.format("%02d"), nowInfo.month, nowInfo.day, nowInfo.year,
                    warningMsg]);
            System.println(fullWarningMsg);
            if (WatchUi.DataField has :showAlert) {
                try {
                    WatchUi.DataField.showAlert(new $.DataFieldAlertView(warningMsg));
                } catch (excpt) {
                    System.println("Exception when showing warning");
                }
            }
        } else {
            System.println(
                Lang.format("Additional distance traveled was $4$ at $1$:$2$:$3$", 
                    [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d"), data_raw]));
            milesWandered += data_raw;
            newMilesField.setData(milesWandered);
            Application.Storage.setValue("distance", milesWandered);
            // play a happy tune when we pass the threshold, zero disables the feature
            if (Application.Properties.getValue("notificationDistance") != 0) {
                if (milesWandered-tonePlayedAt > Application.Properties.getValue("notificationDistance")) {
                    Attention.playTone(Attention.TONE_SUCCESS);
                    tonePlayedAt = milesWandered;
                }
            }
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        // System.println(
        //     Lang.format("Getting initial view at $1$:$2$:$3$", 
        //         [nowInfo.hour, nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]));
        return [ new $.DistanceWanderedView(), new $.TouchDelegate() ];
    }

    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new $.DistanceWanderedSettingsView(), new $.DataFieldSettingsDelegate()];
    }

}

function getApp() as DistanceWanderedApp {
    return Application.getApp() as DistanceWanderedApp;
}