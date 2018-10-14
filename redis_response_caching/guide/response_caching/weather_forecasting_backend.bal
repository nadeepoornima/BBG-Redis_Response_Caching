import ballerina/io;
import ballerina/http;
import ballerinax/docker;
//import ballerinax/kubernetes;

@docker:Expose {}
endpoint http:Listener listner {
    port: 9096
};

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"weatherForecastingBackend",
//    path:"/"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"contentfilter"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"validate"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"enricher"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"backend"
//}
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/weather_forcasting_backend:v1.0",
//    name:"ballerina-guides-weather-forcasting-backend",
//    baseImage:"ballerina/ballerina-platform:0.980.0",
//    copyFiles:[{target:"/ballerina/runtime/bre/lib",
//        source:<path_to_JDBC_jar>}]
//}
@docker:Config{}
service<http:Service> weatherForecastingBackend bind listner {

    getDailyForcast(endpoint caller, http:Request req) {
        http:Response res = new;
        json response = { "Location": "Sri Lanka",
            "Status": "Thunderstorm",
            "Temperature": "29 celcius",
            "Wind": "18 km/h",
            "Humidity": "86%",
            "Precipitation": "80%" };
        res.setPayload(response);

        caller->respond(res) but { error e => io:println("Error sending response") };
    }
}