import ballerina/io;
import ballerina/http;
import ballerinax/docker;

@docker:Expose{}
endpoint http:Listener listner  {
    port : 9095
};

@docker:Config {
    registry: "ballerina.guides.io",
    name: "weather_forecasting_service2",
    tag: "v1.1",
    baseImage: "ballerina/ballerina-platform:0.980.1"
}

//@docker:CopyFiles {
//   files:[{source:"/home/nadee/Downloads/981/ballerina-platform-0.980.1/bre/lib/wso2-redis-package-0.5.4.jar", target:"/ballerina/runtime/bre/lib"}]
//}

service<http:Service> weatherForecastingBackend  bind listner {

    getDailyForcast(endpoint caller, http:Request req) {
        http:Response res = new;
            json response = { "Location":"Sri Lanka",
                "Status":"Thunderstorm",
                "Temperature":"29 celcius",
                "Wind": "18 km/h",
                "Humidity":"86%",
                "Precipitation":"80%" };
            res.setPayload(response);

        caller->respond(res) but { error e => io:println("Error sending response") };
    }
}