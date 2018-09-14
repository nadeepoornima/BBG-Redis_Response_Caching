import ballerina/http;
import ballerina/test;

// Invoking the main function
endpoint http:Client clientEPofweatherService { url: "http://localhost:9100" };

@test:Config {}
function testgetWeatherForcast() {
    // Send 'GET' request and obtain the response.
    http:Response response = check clientEPofweatherService -> get("/weatherForcastService/getWeatherForcast");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getDailyForcast resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), "{\"Location\":\"Sri Lanka\",\"Status\":\"Thunderstorm\",\"Temprature\":\"29 celcius\",\"Wind\":\"18 km/h\",\"Humidity\":\"86%\",\"Precipitation\":\"80%\"}",
        msg = "Response Mismatch");

}

