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
        var positions = Application.Storage.getValue("positions");
        var key = Application.Properties.getValue("key");
        //my-wandrer.earth-key
        //silent-chain-9650
        var isRide = Application.Properties.getValue("isRide");
        System.println("Is bike distance was " + isRide);
        var measureType = isRide ? "bike" : "walk";
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        System.println(
            Lang.format("Sending request at $1$:$2$:$3$ with $4$ points", 
                [info.hour, info.min.format("%02d"), info.sec.format("%02d"), positions.size()]));

        // var url = "http://localhost:8080/wandrerDistance"; 
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