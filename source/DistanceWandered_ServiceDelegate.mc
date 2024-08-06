using Toybox.System;
using Toybox.Background;
using Toybox.Communications;
import Toybox.Lang;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Time.Gregorian;

(:background)
class DistanceWandered_ServiceDelgate extends Toybox.System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

	function onTemporalEvent() {
        Application.Storage.deleteValue("error");
        System.println(Lang.format("In temporal event with $1$ free memory and $2$ bytes used",
            [System.getSystemStats().freeMemory, System.getSystemStats().usedMemory]));        
        var key;
        var isRide;
        var positions = [] as Array<Array<Lang.Double>>;
        try {
            key = Application.Properties.getValue("key");
            isRide = Application.Properties.getValue("isRide");
            positions = Application.Storage.getValue("positions");
        } catch (err)
        {
           Application.Storage.setValue("pending", false);
            System.println(err + " returning without sending request...");
            return;
        }
        //my-wandrer.earth-key
        //silent-chain-9650
        System.println("Is bike distance was " + isRide);
        var measureType = isRide ? "bike" : "walk";
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        System.println(
            Lang.format("Sending request at $1$:$2$:$3$ with $4$ points and key $5$", 
                [info.hour, info.min.format("%02d"), info.sec.format("%02d"), positions.size(), key]));

        // var url = Lang.format(
        //     "http://localhost:8080/wandrerDistance?activity_type=$2$&key=$1$&source=garmin",
        //     [key, measureType]);
        // var url = "https://aqi-gateway.herokuapp.com/wandrerDistance";
        var url = Lang.format(
            "https://wandrer.earth/api/v1/athletes/match?activity_type=$2$&key=$1$&source=garmin",
            [key, measureType]);
        var params = {
              "points" => positions
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {                                           // set headers
                   "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
                                                                   // set response type
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };
       Communications.makeWebRequest(url, params, options, method(:onReceive));
	}

   // set up the response callback function
    function onReceive(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
       Application.Storage.setValue("pending", false);
        var distanceWandered = 0;
        if (responseCode == 200) {
            distanceWandered = data.get("unique_length");
        } else {
            System.println("Received error " + responseCode + " data:" + data);
            Application.Storage.setValue("error", responseCode);
        }
        Background.exit(distanceWandered);
    }
}