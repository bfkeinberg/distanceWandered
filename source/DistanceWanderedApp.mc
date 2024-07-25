import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Position;
using Toybox.Background;

var milesWandered as Numeric = 0;

(:background)
class DistanceWanderedApp extends Application.AppBase {

    var inBackground = false;
    var positions = [] as Array<Position.Location>;

    function initialize() {
        AppBase.initialize();
        milesWandered = 0;
        // Application.Storage.clearValues();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        var here = Position.getInfo();
        var currentPosition = here.position;
        var accuracy = here.accuracy;
        var inDegrees = currentPosition.toDegrees();
        if (currentPosition != null && accuracy > Position.QUALITY_LAST_KNOWN && (inDegrees[0] < 179.999999d)) {
            positions.add(currentPosition.toDegrees());
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
        System.println("Distance traveled was " + data_raw);
        milesWandered = data_raw;
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new $.DistanceWanderedView(positions), new $.TouchDelegate(positions) ];
    }

    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new $.DistanceWanderedSettingsView(), new $.DataFieldSettingsDelegate()];
    }

}

function getApp() as DistanceWanderedApp {
    return Application.getApp() as DistanceWanderedApp;
}