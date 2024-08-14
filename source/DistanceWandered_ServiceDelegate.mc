using Toybox.System;
using Toybox.Background;
using Toybox.Communications;
import Toybox.Lang;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Time.Gregorian;

(:background)
class DistanceWandered_ServiceDelgate extends Toybox.System.ServiceDelegate {

    var whichBucket = 0;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function getAllPositions() as positionChunk {
        whichBucket = Application.Storage.getValue("bucketNum");
        var chunk = whichBucket == 1 ? 0 : 1;
        var dataForRetry = Application.Storage.getValue("retryData");
        if (dataForRetry != null) {
            var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            System.println(
                Lang.format(
                    "Returning data for retry at $1$:$2$:$3$",
                    [info.hour, info.min.format("%02d"), info.sec.format("%02d")]
                )
            );
            // only going to retry it once for now
            Application.Storage.deleteValue("retryData");
            // we need to trigger again as soon as possible to flush out the existing data
            Background.registerForTemporalEvent(Time.now().add(new Time.Duration(300)));
            return dataForRetry;
        }
        var allPositions = Application.Storage.getValue("bucket_" + chunk) as positionChunk;
        // clear out the chunk data
        Application.Storage.setValue("bucket_" + chunk, []);
        // save this in case of error
        Application.Storage.setValue("retryData", allPositions);
        return allPositions;
    }

	function onTemporalEvent() {
        Application.Storage.deleteValue("error");
        // System.println(Lang.format("In temporal event with $1$ free memory and $2$ bytes used, total $3$",
        //     [System.getSystemStats().freeMemory, System.getSystemStats().usedMemory, System.getSystemStats().totalMemory]));        
        var positions = getAllPositions();
        if (positions == null || positions.size() == 0) {
            System.println("No positions stored, returning");
            Attention.playTone(Attention.TONE_ALERT_LO);
            Background.exit(null);
        }
        // System.println(
        //     Lang.format("The position array is $1$ long", [
        //         positions.size()
        //     ])
        // );
        // System.println(Lang.format("After concatenating positions with $1$ free memory and $2$ bytes used, total $3$",
        //     [System.getSystemStats().freeMemory, System.getSystemStats().usedMemory, System.getSystemStats().totalMemory]));        
        var key = Application.Properties.getValue("key");
        var isRide = Application.Properties.getValue("isRide");
        //my-wandrer.earth-key
        //silent-chain-9650
        // System.println("Is bike distance was " + isRide);
        var measureType = isRide ? "bike" : "walk";
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
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
        System.println(
            Lang.format("Sending request at $1$:$2$:$3$ with $4$ points and key $5$", 
                [info.hour, info.min.format("%02d"), info.sec.format("%02d"), positions.size(), key]));
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
        if (responseCode == 200) {
            var distanceWandered = data.get("unique_length");
            // now we can remove the bucket for possible retries
            Application.Storage.deleteValue("retryData");
            Background.exit(distanceWandered);
        } else {
            System.println("Received error " + responseCode + " data:" + data);
            Application.Storage.setValue("error", responseCode);
            // retry as soon as possible if it wasn't connected to the phone
            if (responseCode == -104 || responseCode == -2 || responseCode == -300) {
                Background.registerForTemporalEvent(Time.now().add(new Time.Duration(300)));
            } else {
                // not deemed retryable so delete the save bucket
                Application.Storage.deleteValue("retryData");
            }
        }
        Background.exit(null);
    }
}