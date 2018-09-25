import ballerina/http;
import ballerina/io;
import wso2/redis;
import ballerinax/docker;

// Backend
@docker:Expose{}
endpoint http:Client backendEndpoint {
    url: "http://localhost:9095/weatherForecastingBackend"
};
//Service Listner
@docker:Expose{}
endpoint http:Listener Servicelistner  {
    port : 9100
};

@docker:CopyFiles {
    files:[{source: "/home/nadee/Downloads/RedisBBG/wso2-redis-0.5.4.zip"
        , target:"/home/nadee/Downloads/RedisBBG/Redis_service_conteianer"}]
}

// unzip and run installation script through shelscript

// possibility to run shelscript through docker

// Redis datasource used as an LRU cache
endpoint redis:Client cache {
    host: "test-host",
    name: "some-rediss",
    //host: "test-host",
    password: "",
    options: { ssl: false }
};

@docker:Config {
    registry: "ballerina.guides.io",
    name: "weather_forecasting_service",
    tag: "v1.0",
    baseImage: "ballerina/ballerina-platform:0.980.1"
}

service<http:Service> weatherForecastService bind Servicelistner {

    getWeatherForecast(endpoint caller, http:Request req) {
        http:Response res = new;

        // First check whether the response is already cached
        var cachedResponse = cache->get("key");

        match cachedResponse {
            // If the response is cached set it as the payload
            string result => {
                io:println("Found in cache! " + result);
                res.setPayload(<json>result);
            }
            // If response is not cached, call the backend and get the result and cache it
            () => {
                io:println("Not Found in cache Called to Backend and cache the response");
                var backendResponse = backendEndpoint->get("/getDailyForcast");
                res = handleBackendResponse(backendResponse);

            }
            error => {
                res.setPayload({ message: "Error occurred" });
            }
        }

        // Respond to the client
        caller->respond(res) but {
            error e => io:println("Error sending response")
        };
    }
}

function handleBackendResponse(http:Response|error backendResponse) returns http:Response {
    http:Response res = new;
    match backendResponse {
        http:Response backendRes => {
            res = backendRes;
            var jsonPayload = res.getJsonPayload();
            match jsonPayload {
                json j => {
                    // Cache the response
                    _ = cache->setVal("key", j.toString());
                    // Set an expiry time for the cache
                    _ = cache->pExpire("key", 600000);
                }
                error e => {
                    io:println("Error while updating the cache" + e.message);
                }
            }
        }
        error => {
            res.setPayload({ message: "Error occurred" });
        }
    }
    return res;
}