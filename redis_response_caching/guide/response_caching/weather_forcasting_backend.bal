import ballerina/io;
import ballerina/http;

endpoint http:Listener listner  {
    port : 9095
};

service<http:Service> weatherForcastingBackend  bind listner {

    getDailyForcast(endpoint caller, http:Request req) {
        http:Response res = new;
            json response = { "Location":"Sri Lanka",
                "Status":"Thunderstorm",
                "Temprature":"29 celcius",
                "Wind": "18 km/h",
                "Humidity":"86%",
                "Precipitation":"80%" };
            res.setPayload(response);

        caller->respond(res) but { error e => io:println("Error sending response") };
    }
}