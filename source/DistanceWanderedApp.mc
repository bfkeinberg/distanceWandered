import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Position;
using Toybox.Background;

var milesWandered as Numeric = 0;

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
        System.println("Distance traveled was " + data_raw);
        milesWandered = data_raw;
    }

    function setFirstPosition() as Void {
        var positions = [] as Array<Array<Lang.Double>>;
        System.println("setting first position");
        var here = Position.getInfo();
        var currentPosition = here.position;
        var accuracy = here.accuracy;
        var inDegrees = currentPosition.toDegrees();
        if (currentPosition != null && accuracy > Position.QUALITY_LAST_KNOWN && (inDegrees[0] < 179.999999d)) {
            positions.add(currentPosition.toDegrees());
        }
        Application.Storage.setValue("positions", positions);
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        System.println("Getting initial view");
        Application.Storage.deleteValue("positions");
        setFirstPosition();
        Application.Storage.deleteValue("pending");
        milesWandered = 0;
        return [ new $.DistanceWanderedView(), new $.TouchDelegate() ];
    }

    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new $.DistanceWanderedSettingsView(), new $.DataFieldSettingsDelegate()];
    }

}

function getApp() as DistanceWanderedApp {
    return Application.getApp() as DistanceWanderedApp;
}