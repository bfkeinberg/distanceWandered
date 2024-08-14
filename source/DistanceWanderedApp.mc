import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Position;
using Toybox.Background;

var milesWandered as Numeric = 0;

typedef coords as Array<Lang.Double>;
typedef positionChunk as Array<coords>;
const maxChunkSize = 80;

(:background)
class DistanceWanderedApp extends Application.AppBase {

    var inBackground = false;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
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
        }
        System.println("Additional distance traveled was " + data_raw);
        milesWandered += data_raw;
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        milesWandered = 0;
        Background.deleteTemporalEvent();
        return [ new $.DistanceWanderedView(), new $.TouchDelegate() ];
    }

    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new $.DistanceWanderedSettingsView(), new $.DataFieldSettingsDelegate()];
    }

}

function getApp() as DistanceWanderedApp {
    return Application.getApp() as DistanceWanderedApp;
}