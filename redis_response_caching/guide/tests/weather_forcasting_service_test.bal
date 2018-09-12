//import ballerina/io;
//import ballerina/http;
//import ballerina/test;
//import ballerina/log;
//
//endpoint http:Client httpClientOne {
//    url: "http://localhost:9100"
//};
//
//// Before Suite Function is used to start the services
//@test:BeforeSuite
//function beforeSuiteFunc() {
//    boolean status = test:startServices(".");
//    log:printInfo("Starting Weather forcasting Services...");
//}
//
//// Test function
//@test:Config
//function testStartService() {
//    log:printInfo("testStartSyncData Service");
//
//    http:Request httpRequest = new;
//    var out = httpClientOne->post("/getWeatherForcast", request = httpRequest);
//    match out {
//        http:Response resp => {
//            log:printInfo("Response received from 'startService' successfully!");
//        }
//        error e => {
//            log:printError("Error occured! " + e.message);
//            test:assertFail(msg = e.message);
//        }
//    }
//}
