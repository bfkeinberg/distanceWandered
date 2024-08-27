import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Position;
using Toybox.Background;
using Toybox.Attention;

var milesWandered as Numeric = -1;

typedef coords as Array<Lang.Double>;
typedef positionChunk as Array<coords>;
const maxChunkSize = 80;
var newMilesField;

(:background)
class DistanceWanderedApp extends Application.AppBase {

    var inBackground = false;
    const distanceThreshold = 10;       // until we decide to make it configurable
    var tonePlayedAt = 0;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            System.println("State: " + state.toString());
        }
        if (System.getSystemStats().totalMemory < 32000) {
        } else {
            System.println("initializing miles wandered from onStart");
            milesWandered = 0;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    	if(!inBackground) {
    		Background.deleteTemporalEvent();
    	}
    }

    function getServiceDelegate(){
    	//only called in the background	
    	inBackground = true;
        return [new DistanceWandered_ServiceDelgate()];
    }

    function onBackgroundData(data_raw as Application.PersistableType) {
        if (data_raw == null) {
            System.println("No background data, nothing to do");
        } else {
            System.println("Additional distance traveled was " + data_raw);
            newMilesField.setData(data_raw);
            milesWandered += data_raw;
            // play a happy tune when we pass the threshold
            if (milesWandered-tonePlayedAt > distanceThreshold) {
                Attention.playTone(Attention.TONE_INTERVAL_ALERT);
                tonePlayedAt = milesWandered;
            }
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Background.deleteTemporalEvent();
        return [ new $.DistanceWanderedView(), new $.TouchDelegate() ];
    }

    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new $.DistanceWanderedSettingsView(), new $.DataFieldSettingsDelegate()];
    }

}

function getApp() as DistanceWanderedApp {
    return Application.getApp() as DistanceWanderedApp;
}