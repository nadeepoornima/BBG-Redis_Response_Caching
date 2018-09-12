# Redis Caching - Response Caching

Redis is an open source, in-memory data structure store, used as a database, cache and message broker. This supports data structures such as strings, hash lists, sets, sorted sets with range queries, bitmaps, hyperlogs  and geospatial indexes with radius queries[1]. 

WSO2 provides a Ballerina package which includes a client to perform operations with a Redis database. 

This document is describing about response caching and how redis deals with this. The response caching is a much use full mechanism when dealing with microservices because it improves the performance of microservice as follows.

If the response of a service has cached then it will help to improve the speed and availability of a particular service. Because if the response cached, the it will help to reduce the round trips to dependencies. As well as if the response cached then the end user will able to get the result much faster than calling to back end time to time. Therefore the speed of the system will increase and users could get much better experience. 

Furthermore, this is a good solution to increase availability of the service, because if particular service is down, we will able to sever the result out of the cache. 

And also this helps to reduce the frequent of producing response from the back end. If deducted frequent of back end calling, then response producing also will deduct. Hence this is a better way to improve the performance of a particular system. 

Actually this is much profitable when the nature of data static and don’t change often.

Let’s see an example and how we can use this response caching  in real world by following this guide.

The following are the sections available in this guide.

1. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching#what-youll-build">WHAT YOU’LL BUILD</a>
2. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching#prerequisites">PREREQUISITES</a> 
3. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching#implementation">IMPLEMENTATION</a>
4. TESTING
5. DEPLOYMENT
6. OBSERVABILITY

## WHAT YOU’LL BUILD

When considering about a weather forecasting app, then at a time number of people check the whether for a particular place and the result should be same. In that situation we can use this response caching mechanism to give the result rather than always calling to the back end. 

Here we are using Redis to cache the response of our sample weather service, because Redis is a open source and a in memory data structure store. This is a NoSQL family of data management solution and it is based on the key-value data model. This is keeping all data in RAM and makes them supremely useful as a caching layer. Therefore it provides a much speed to the system. 

Actually Redis is simple, can work with it easily, user friendly and need few minutes to install and work with application. That means, a small investment of time and effort can have an immediate, dramatic impact on performance. 

With Redis as a cache, we can gain a lot of power (such as the ability to fine-tune cache contents and durability) and greater efficiency overall. Once we use the data structures, the efficiency boost becomes tremendous for specific application scenarios.

It is showing same behaviour with Ballerina as well and you will understand this by implementing the following sample service. 
 
The high level picture of this response caching is as follows.

![alt text](https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/images/BBGUseCaseChanged.png)



1. First call to the backend
2. Get the result and response cache
3. Again call to same backend
4. Get the result from redis cache instead of calling to the backend again
5. If cache expired, call back to the BE and response will cache again




## PREREQUISITES	

1. <a href="https://ballerina.io/learn/getting-started/">Ballerina Distribution</a>
2. A Text Editor or an IDE
3. Install Ballerina Redis package. You can download the package from <a href="https://github.com/wso2-ballerina/package-redis/releases/tag/v0.5.4">GitHub releases</a> of the package. Inside the package zip archive you can find a installer script. It will install the package in seconds.
4. Install Redis database in your machine/any remote server. <a href="https://redis.io/download">Redis website</a> has simple instructions for installation. They provide a Redis docker image too!

### Optional requirements

1. Ballerina IDE plugins (<a href="https://plugins.jetbrains.com/plugin/9520-ballerina">IntelliJ IDEA</a>, <a href="https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina">VSCode</a>, <a href="https://atom.io/packages/language-ballerina">Atom</a>)
2. <a href="https://docs.docker.com/install/">Docker</a>
3. <a href="https://kubernetes.io/docs/setup/">Kubernetes</a>

## IMPLEMENTATION

If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

<pre>
<code>
└── redis_response_caching
├── guide
	├── response_caching
		├── weather_forcasting_backend.bal
		└── weather_forcasting_service.bal
	└── tests
		├── weather_forcasting_backend_test.bal
		└── weather_forcasting_service_test.bal
</code>
</pre>

* Create the above directories in your local machine and also create empty **.bal** files.
* Then open the terminal and navigate to **redis_response_caching/guide** and run Ballerina project initializing toolkit.

<pre>
<code>$ ballerina init</code>
</pre>

### Developing the service

Let’s see how to implement the weather_forcasting_service which the service handles redis response caching. In this service, we need to implement the required logic to check the response from the redis cache database. As per the logic, If the response available in the redis cache then need to get the result from the cache and show the response. If this is the very first call to the backend or the cache invalidate time has passed then the response will not available in the cache. In that situation need to call to the backend and response should give to the client while the response should cache in the redis database. Therefore here we need to use that WSO2 redis cache package to implement this logic and has implemented weather_forcasting_service.bal by using that redis package as follows.

#### The implementation of weather_forcasting_service.bal

<pre>
<code>
//importing required packages including the WSO2 redis package
import ballerina/http;
import ballerina/io;
import wso2/redis;

// Backend
endpoint http:Client backendEndpoint {
    url: "http://localhost:9095/weatherForcastingBackend"
};
//Service Listner
endpoint http:Listener Servicelistner  {
    port : 9100
};


// Redis datasource used as an LRU cache
endpoint redis:Client cache {
    host: "localhost",
    password: "",
    options: { ssl: false }
};

service<http:Service> weatherForcastService bind Servicelistner {

    getWeatherForcast(endpoint caller, http:Request req) {
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
</code>
</pre>





