# Redis Caching - Response Caching

Redis is an open source, in-memory data structure store, used as a database, cache and message broker. This supports data structures such as strings, hash lists, sets, sorted sets with range queries, bitmaps, hyperlogs  and geospatial indexes with radius queries. 

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
4. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/README.md#testing">TESTING</a>
5. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/README.md#deployment">DEPLOYMENT</a>
6. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/README.md#observability">OBSERVABILITY</a>

## WHAT YOU’LL BUILD

When considering about a weather forecasting app, then at a time number of people check the whether for a particular place and the result should be same. In that situation we can use this response caching mechanism to give the result rather than always calling to the back end. 

Here we are using Redis to cache the response of our sample weather service, because Redis is a open source and a in memory data structure store. This is a NoSQL family of data management solution and it is based on the key-value data model. This is keeping all data in RAM and makes them supremely useful as a caching layer. Therefore it provides a much speed to the system. 

Actually Redis is simple, can work with it easily, user friendly and need few minutes to install and work with application. That means, a small investment of time and effort can have an immediate, dramatic impact on performance. 

With Redis as a cache, we can gain a lot of power (such as the ability to fine-tune cache contents and durability) and greater efficiency overall. Once we use the data structures, the efficiency boost becomes tremendous for specific application scenarios.

It is showing same behaviour with Ballerina as well and you will understand this by implementing the following sample service. 
 
The high level picture of this response caching is as follows.

![alt text](https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/images/BBG-Redis_Response_Caching.svg)




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
		├── weather_forecasting_backend.bal
		└── weather_forecasting_service.bal
	└── tests
		├── weather_forecasting_backend_test.bal
		└── weather_forecasting_service_test.bal
</code>
</pre>

* Create the above directories in your local machine and also create empty **.bal** files.
* Then open the terminal and navigate to **redis_response_caching/guide** and run Ballerina project initializing toolkit.

<pre>
<code>$ ballerina init</code>
</pre>

### Developing the service

Let’s see how to implement the weather_forecasting_service which the service handles redis response caching. In this service, we need to implement the required logic to check the response from the redis cache database. As per the logic, If the response available in the redis cache then need to get the result from the cache and show the response. If this is the very first call to the backend or the cache invalidate time has passed then the response will not available in the cache. In that situation need to call to the backend and response should give to the client while the response should cache in the redis database. Therefore here we need to use that WSO2 redis cache package to implement this logic and has implemented weather_forecasting_service.bal by using that redis package as follows.

#### The implementation of weather_forecasting_service.bal

```java
//importing required packages including the WSO2 redis package
import ballerina/http;
import ballerina/io;
import wso2/redis;

// Backend
endpoint http:Client backendEndpoint {
    url: "http://localhost:9096/weatherForecastingBackend"
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
```

According to the above implementation, we have used the following line to import the WSO2 redis package to our service.
```java
import wso2/redis;
```
Then we have created the connection with redis database(redis datasource) by using the below code lines.

```java
endpoint redis:Client cache {
    host: "localhost",
    password: "",
    options: { ssl: false }
};
```

As per the logic, when calling to the backend as the first time or cache has expired, the it called to the backend and the response of the backend will cache by assigning a key and expiry time for that. The expiry time unit is millisecond. As per example, If you set the expiry time as 600000, then it will represents 600000 milliseconds and it will equal to 10 minutes. This logic has implemented in the “handleBackendResponse” function as the below.

```java
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
```

Then when calling to the weather_forcast_service again by another one, if the response already cached then it will get from the cache and show it as the response by executing following code lines with the *getWeatherForcast()* function.

```java
 var cachedResponse = cache->get("key");

        match cachedResponse {
            // If the response is cached set it as the payload
            string result => {
                io:println("Found in cache! " + result);
                res.setPayload(<json>result);
            }
```

If the response is not found in the cache, then the backend calling is happening by executing the following code lines within the *getWeatherForcast()* function.

```java
 // If response is not cached, call the backend and get the result and cache it
            () => {
                io:println("Not Found in cache Called to Backend and cache the response");
                var backendResponse = backendEndpoint->get("/getDailyForcast");
                res = handleBackendResponse(backendResponse);
            }
```

Let’s see the backend implementation as well. The backend is weather_forecasting_backend.bal and it has implemented as the below. Please note this is a sample backend only to present the redis caching with ballerina. 

#### The implementation of weather_forecasting_backend.bal

```java
import ballerina/io;
import ballerina/http;

endpoint http:Listener listner  {
    port : 9096
};

service<http:Service> weatherForecastingBackend  bind listner {

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
```

Now you have completed developing the redis response caching scenario with Ballerina redis caching package.

## TESTING

### Invoking the services

1. **Testing the backend service**

To test the back end service, you need to go to the *BBG-Redis_Response_Caching/redis_response_caching/guide/response_caching* and run the *weather_forecasting_backend.bal* by executing the following command. 
<pre>
<code>$ ballerina run weather_forecasting_backend.bal</code>
</pre>
If correctly up the backend service, it will show the following message on the terminal.
<pre>
<code>
ballerina: initiating service(s) in 'weather_forecasting_backend.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9096
</code>
</pre>
Now you can invoke the backend by sending the request as the below:
<pre>
<code>curl -v http://localhost:9096/weatherForecastingBackend/getDailyForcast</code>
</pre>
The expected response for the above request is,
<pre>
<code>
{"Location":"Sri Lanka","Status":"Thunderstorm","Temperature":"29 celcius","Wind":"18 km/h","Humidity":"86%","Precipitation":"80%"} 
</code>
</pre>

2. **Testing the weather forecasting service** 

To test this service, the backend service must be in up and running status. Then you need to run the weather forecasting service as well. For that you need to go to the *BBG-Redis_Response_Caching/redis_response_caching/guide/response_caching* and run the *weather_forecasting_service.bal* by executing the following command.

<pre>
<code>$ ballerina run weather_forecasting_service.bal</code>
</pre>

If correctly up the weather forecasting service, it will show the following message on the terminal.
<pre>
<code>
ballerina: initiating service(s) in 'weather_forecasting_service.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9100
</code>
</pre>

Now you can invoke the weather forecasting service by sending the request as the below:
<pre>
<code>curl -v http://localhost:9100/weatherForecastService/getWeatherForecast</code>
</pre>

Then the expected responses are,

- **If the first time invoke this service** : 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Server**: Not Found in cache Called to Backend and cache the response<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Client**: {"Location":"Sri Lanka","Status":"Thunderstorm","Temperature":"29 celcius","Wind":"18 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;km/h","Humidity":"86%","Precipitation":"80%"}

- **If the second time invoke this service before the cache invalid (eg: as per the implementation cache will invalidate within 10 minutes after caching the response in redis database)** :

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Server**: Found in cache! {"Location":"Sri Lanka","Status":"Thunderstorm","Temperature":"29 celcius","Wind":"18 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;km/h","Humidity":"86%","Precipitation":"80%"}<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Client**: {"Location":"Sri Lanka","Status":"Thunderstorm","Temperature":"29 celcius","Wind":"18 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;km/h","Humidity":"86%","Precipitation":"80%"}

- **When expiring the cache** :

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Server**: Not Found in cache Called to Backend and cache the response<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Client**:  {"Location":"Sri Lanka","Status":"Thunderstorm","Temperature":"29 celcius","Wind":"18 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;km/h","Humidity":"86%","Precipitation":"80%"}

### Writing unit tests

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. When writing the test functions, the below convention should be followed.

Test functions should be annotated with @test:Config. See the below example.

```java
@test:Config
   function testFunc() {
   }
```

This guide contains unit test cases for redis caching service and backend service in the following files.
1. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/redis_response_caching/guide/tests/weather_forecasting_service_test.bal">Weather forecasting test file</a>
2. <a href="https://github.com/nadeepoornima/BBG-Redis_Response_Caching/blob/master/redis_response_caching/guide/tests/weather_forecasting_backend_test.bal">Backend service test file</a> 

To run the unit tests, navigate to *BBG-Redis_Response_Caching/redis_response_caching* and run the following command.
<pre>
<code>$ ballerina test</code>
</pre>

## DEPLOYMENT

### Deploying locally

* As the first step, you can build a Ballerina executable archive (.balx) of the services that we developed above. Navigate to *BBG-Redis_Response_Caching/redis_response_caching/guide/response_caching* and run the following command.
<pre>
<code>$ ballerina build</code>
</pre>

* Once the *weather_forecasting_backend.balx* and *weather_forecasting_service.balx* files are created inside the target folder, you can run them with the following command.
<pre>
<code>$ballerina run target/weather_forecasting_backend.balx</code>
<code>$ballerina run target/weather_forecasting_service.balx</code>
</pre>

* Successful execution of the service displays the following output.
<pre>
<code>$ballerina run target/weather_forecasting_backend.balx</code>
<code>
ballerina: initiating service(s) in 'weather_forecasting_backend.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9096
</code>
</pre>

<pre>
<code>$ballerina run target/weather_forecasting_service.balx</code>
<code>
ballerina: initiating service(s) in 'weather_forecasting_service.balx'
ballerina: started HTTP/WS endpoint 0.0.0.0:9100
</code>
</pre>

### Deploying on Docker

You can run the service that we developed above as a Docker container. As Ballerina platform includes <a href="https://github.com/ballerinax/docker">Ballerina_Docker_Extension</a>, which offers native support for running Ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. Since this guide requires Redis as a prerequisite and you can download the Redis docker image from <a href="https://hub.docker.com/_/redis/">here<a> and please follow guidlines and you can use it to deploy this project as a docker image.

**First, let's see how to configure Redis in the Docker container.**

- Initially, you need to pull the Redis docker image using the below command.
<pre>$ docker pull redis</pre>
- Then run the following command to start the redis instance.
<pre>$ docker run --name some-redis -d redis</pre> 
- Check whether the redis container is up and running using the following command.
<pre>$docker ps</pre>

**Let's create the docker containers for weather forecasting service and sample backend as follows.**

As our implementation we need to create the backend service docker image first and need to create the weather service image as second one. Let's see how to do that.

- First add the required docker annotations in our weather_forecasting_backend. You need to import ballerinax/docker; and add the docker annotations as shown below to enable docker image generation during the build time. 
-  *@docker:Config* annotation is used to provide the basic docker image configurations for the sample. *@docker:Expose {}* is used to expose the port. 

```java
import ballerina/io;
import ballerina/http;
import ballerinax/docker;
//import ballerinax/kubernetes;

@docker:Expose {}
endpoint http:Listener listner {
   port: 9096
};

	
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

```
- After that you can build a Ballerina executable archive (.balx) of the backend service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the *BBG-Redis_Response_Caching/redis_response_caching/guide/response_caching/* folder and run the following command.

<pre>
$ballerina build weather_forecasting_backend.bal

Compiling source
    weather_forecasting_backend.bal

Generating executable
    weather_forecasting_backend.balx
        @docker                  - complete 3/3 

        Run the following command to start a Docker container:
        docker run -d -p 9096:9096 weather_forecasting_backend:latest
</pre>

- Once you successfully build the docker image of sample backend, you can run it with the docker run command that is shown in the previous step.
<pre>$docker run -d -p 9096:9096 weather_forecasting_backend:latest</pre>
- Here we run the docker image with flag -p <host_port>:<container_port> so that we use the host port 9096 and the container port 9096. Therefore you can access the service through the host port.
- Verify docker container is running with the use of $ docker ps. The status of the docker container should be shown as 'Up'.
- You can access the service using the same curl commands that we've used above.
<pre>curl -v http://localhost:9096/weatherForecastingBackend/getDailyForcast</pre>

- Then as the last step you need to add the required dcoker annotations for the *weather_forecasting_service* as the below code. In here you need to use the docker image of redis connector (ballerina/ballerina-redis:0.982.0) which we have created to build the docker image of this service in a successful manner. You need to select the version compatible image as you used ballerina version.

```java
import ballerina/http;
import ballerina/io;
import wso2/redis;
import ballerinax/docker;

// Backend
endpoint http:Client backendEndpoint {
   url: "http://172.17.0.2:9096/weatherForecastingBackend" //IP address need to chage as the backend docker iname 
};
//Service Listner
@docker:Expose{}
endpoint http:Listener Servicelistner  {
   port : 9100
};

// Redis datasource used as an LRU cache
endpoint redis:Client cache {
   host: "172.17.0.3", //Host need to change as your redis docker image 
   password: "",
   options: { ssl: false }
};

@docker:Config {
   registry: "ballerina.guides.io",
   name: "weather_forecasting_service",
   tag: "v1.0",
   baseImage: "ballerina/ballerina-redis:0.982.0"
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
```
- Furthermore, you need to change the host field in the *redis:Client endpoint* and *http:Client backendEndpoint* definition to the IP address of the redis container and the backend container respectively. You can obtain this IP address using the below command.
<pre>$docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <Container_ID></pre>

- Now you can build a Ballerina executable archive (.balx) of the weather service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the *BBG-Redis_Response_Caching/redis_response_caching/guide/response_caching/* folder and run the following command.

<pre>
$ballerina build weather_forecasting_service.bal
	
	Compiling source
    weather_forecasting_service.bal
        could not find package wso2/redis:*

Generating executable
    weather_forecasting_service.balx
        @docker                  - complete 3/3 

        Run the following command to start a Docker container:
        docker run -d -p 9100:9100 ballerina.guides.io/weather_forecasting_service:v1.0

</pre>

- Once you successfully build the docker image of sample backend, you can run it with the docker run command that is shown in the previous step.
<pre>$docker run -d -p 9100:9100 ballerina.guides.io/weather_forecasting_service:v1.0</pre>

- Here we run the docker image with flag -p <host_port>:<container_port> so that we use the host port 9100 and the container port 9100. Therefore you can access the service through the host port.
- Verify docker container is running with the use of $ docker ps. The status of the docker container should be shown as 'Up'.
-You can access the service using the same curl commands that we've used above.
<pre>curl -v http://localhost:9100/weatherForecastService/getWeatherForecast</pre>

### Deploying on Kubernetes

You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a Ballerina program on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create docker images prior to deploying it on Kubernetes. Refer to <a href="https://github.com/ballerinax/kubernetes">Ballerina_Kubernetes_Extension</a> for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs.

Since this guide requires Redis as a prerequisite, you need a couple of more steps to create a Redis pod and use it with our sample.

- First, let's look at how we can create a Redis pod in Kubernetes. If you are working with minikube, it will be convenient to use the minikube's in-built docker daemon and push the Redis docker image we are about to build to the minikube's docker registry. This is because during the next steps, in the case of minikube, the docker images we build for weather_backend and weather_service will also be pushed to minikube's docker registry. Having both images in the same registry will reduce the configuration steps. Run the following command to start using minikube's in-built docker daemon.

<pre>minikube docker-env</pre>

-  
Then run the following command from the same directory to create the Redis pod by creating a deployment and service for Redis. You can find the deployment descriptor and service descriptor in the *./resources/kubernetes* folder.

<pre>$kubectl create -f ./kubernetes/</pre>

- Now we need to import ballerinax/kubernetes; and use @kubernetes annotations as shown below to enable Kubernetes deployment for the services we developed above.

**Weather_forecasting_backend.bal**

```java
import ballerina/io;
import ballerina/http;
import ballerinax/kubernetes;
 
 
@kubernetes:Ingress {
   hostname:"ballerina.guides.io",
   name:"weatherForecastingBackend",
   path:"/"
}
 
@kubernetes:Service {
   serviceType:"NodePort",
   name:"contentfilter"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"validate"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"enricher"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"backend"
}
//@docker:Expose {}
endpoint http:Listener listner {
   port: 9096
};
 
@kubernetes:Deployment {
   image:"weather_forecasting_backend",
   name:"weather_forecasting_backend",
   baseImage:"ballerina/ballerina-platform:0.982.0"
}
//@docker:Config{}
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

``` 

- Here we have used *@kubernetes:Deployment* to specify the docker image name which will be created as part of building this service.
- Please note that if you are using minikube it is required to add the dockerHost and dockerCertPath configurations under *@kubernetes:Deployment*. Eg:

<pre>
@kubernetes:Deployment {
    @kubernetes:Deployment {
   image:"weather_forecasting_backend",
   name:"ballerina-guides-weather-forcasting-backend",
   baseImage:"ballerina/ballerina-platform:0.982.0"
    dockerHost:"tcp://<MINIKUBE_IP>:<DOCKER_PORT>",
    dockerCertPath:"<MINIKUBE_CERT_PATH>"
}
</pre>

- We have also specified *@kubernetes:Service* so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.
- In addition, we have used *@kubernetes:Ingress* which is the external interface to access your service (with path / and hostname ballerina.guides.io).
- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.

<pre>
ballerina build weather_forecasting_backend.bal
 
Compiling source
    weather_forecasting_backend.bal
 
Generating executable
    weather_forecasting_backend.balx
        @kubernetes:Service                      - complete 1/1
        @kubernetes:Ingress                      - complete 1/1
        @kubernetes:Deployment                   - complete 1/1
        @kubernetes:Docker                       - complete 3/3
 
 Run following command to deploy kubernetes artifacts: 
           kubectl apply -f ./target/weather_forecasting_backend/kubernetes/
</pre>

- You can verify that the docker image that we specified in *@kubernetes:Deployment* is created, by using docker images.
- Also the Kubernetes artifacts related our service, will be generated in *./target/weather_forecasting_backend/kubernetes*.
- Now you can create the Kubernetes deployment using:
<pre>$kubectl apply -f ./target/weather_forecasting_backend/kubernetes</pre>
- You can verify if Kubernetes deployment, service and ingress are running properly by using following Kubernetes commands.
<pre>
   $kubectl get service
   $kubectl get deploy
   $kubectl get pods
   $kubectl get ingress
</pre>
- If everything is successfully deployed, you can invoke the service either via Node port or ingress.
**Node Port:**
<pre>curl -v http://localhost:9096/weatherForecastingBackend/getDailyForcast</pre>
**Ingress:**
Add */etc/hosts* entry to match hostname.
<pre>127.0.0.1 ballerina.guides.io</pre>
 
**Access the service**
<pre>curl -v http://localhost:9096/weatherForecastingBackend/getDailyForcast</pre>

**Weather_forecasting_service.bal**

```java
import ballerina/http;
import ballerina/io;
import wso2/redis;
import ballerinax/kubernetes;


// Backend
endpoint http:Client backendEndpoint {
   url: "http://172.17.0.2:9096/weatherForecastingBackend"
};

@kubernetes:Ingress {
   hostname:"ballerina.guides.io",
   name:"weatherForecastingService",
   path:"/"
}

@kubernetes:Service {
   serviceType:"NodePort",
   name:"contentfilter"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"validate"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"enricher"
}
@kubernetes:Service {
   serviceType:"NodePort",
   name:"backend"
}
//Service Listner
endpoint http:Listener Servicelistner  {
   port : 9100
};


endpoint redis:Client cache {
   host: "172.17.0.3",
   password: "",
   options: { ssl: false }
};

@kubernetes:Deployment {
   image:"ballerina.guides.io/weather_forecasting_service",
   name:"weather_forecasting_service",
   baseImage:"ballerina/ballerina-platform:0.982.0"
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
```
- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
<pre>
ballerina build weather_forecasting_service.bal
compiling source
    weather_forecasting_service.bal
        could not find package wso2/redis:*
 
Generating executable
    weather_forecasting_service.balx
        @kubernetes:Service                      - complete 1/1
        @kubernetes:Ingress                      - complete 1/1
        @kubernetes:Deployment                   - complete 1/1
       @kubernetes:Docker                       - complete 3/3
 Run following command to deploy kubernetes artifacts: 
           kubectl apply -f ./target/weather_forecasting_service/kubernetes/
</pre>

- You can verify that the docker image that we specified in *@kubernetes:Deployment* is created, by using docker images.
- Also the Kubernetes artifacts related our service, will be generated in ./target/weather_forecasting_service/kubernetes.
- Now you can create the Kubernetes deployment using:
<pre>$kubectl apply -f ./target/weather_forecasting_service/kubernetes </pre>
- You can verify if Kubernetes deployment, service and ingress are running properly by using following Kubernetes commands.
<pre>
   $kubectl get service
   $kubectl get deploy
   $kubectl get pods
   $kubectl get ingress
</pre>
- If everything is successfully deployed, you can invoke the service either via Node port or ingress.
**Node Port:**
<pre>curl -v http://localhost:9100/weatherForecastService/getWeatherForecast</pre>
**Ingress:**
Add */etc/hosts entry* to match hostname.
<pre>127.0.0.1 ballerina.guides.io</pre>
**Access the service**
<pre>curl -v http://localhost:9100/weatherForecastService/getWeatherForecast</pre>

## OBSERVABILITY

Ballerina is by default observable. Meaning you can easily observe your services, resources, etc. Refer to <a href="https://ballerina.io/learn/how-to-observe-ballerina-code/">how-to-observe-ballerina-code</a> for more information. However, observability is disabled by default via configuration. Observability can be enabled by adding the following configurations to <code>ballerina.conf</code> file and then the Ballerina service will start to use it.

<pre>
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
</pre>

<blockquote>
<p><strong>NOTE</strong>: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations, default values are loaded as the other configuration parameters of metrics and tracing.</p>
</blockquote>

### Tracing

You can monitor Ballerina services using inbuilt tracing capabilities of Ballerina. Let's use <a href="https://github.com/jaegertracing/jaeger">Jaeger</a> as the distributed tracing system.

Follow the steps below to use tracing with Ballerina.

You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in <code>ballerina.conf</code> as described above.

<pre>
[b7a.observability]

   [b7a.observability.tracing]
   enabled=true
   name="jaeger"

   [b7a.observability.tracing.jaeger]
   reporter.hostname="localhost"
   reporter.port=5775
   sampler.param=1.0
   sampler.type="const"
   reporter.flush.interval.ms=2000
   reporter.log.spans=true
   reporter.max.buffer.spans=1000
</pre>

Run the Jaeger Docker image using the following command.

<pre>
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 -p14268:14268 jaegertracing/all-in-one:latest
</pre>

Navigate to BBG-Redis_Response_Caching/redis_response_caching/guide and *run* the response_caching using following command.

<pre>
$ ballerina run response_caching/
</pre>

Observe the tracing using Jaeger UI using the following URL.

<pre>
http://localhost:16686
</pre>

### Metrics

Metrics and alerts are built-in with Ballerina. We will use Prometheus as the monitoring tool. Follow the steps below to set up Prometheus and view metrics for 'redis reponse caching'.

You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in <code>ballerina.conf</code> as described under the <code>Observability</code> section.

<pre>
[b7a.observability.metrics]
   enabled=true
   provider="micrometer"

   [b7a.observability.metrics.micrometer]
   registry.name="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9700
   hostname="0.0.0.0"
   descriptions=false
   step="PT1M"
</pre>

Create a file <code>prometheus.yml</code> inside the <code>/tmp/</code> location. Add the below configurations to the <code>prometheus.yml</code> file.

<pre>
global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
</pre>

<blockquote>
<p><strong>NOTE</strong>: Replace <code>172.17.0.1</code> if your local Docker IP differs from <code>172.17.0.1</code></p>
</blockquote>

Run the Prometheus docker image using the following command.

<pre>
$ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
</pre>

You can access Prometheus at the following URL.

<pre>
http://localhost:19090/
</pre>

<blockquote>
<p><strong>NOTE</strong>:  By default, Ballerina has the following metrics for HTTP server connector. You can enter the following expression in Prometheus UI.</p>
<ul>
<li>http_requests_total</li>
<li>http_response_time</li>
</ul>
</blockquote>

### Logging

Ballerina has a log package for logging into the console. You can import <code>ballerina/log</code> package and start logging. The following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

Start the Ballerina service with the following command from <code>BBG-Redis_Response_Caching/redis_response_caching/guide</code>.

<pre>
$ nohup ballerina run response_caching/ &>> ballerina.log&
</pre>

<blockquote>
<p><strong>NOTE</strong>: This writes the console log to the <code>ballerina.log</code> file in the <code>BBG-Redis_Response_Caching/redis_response_caching/guide</code> directory.</p>
</blockquote>

Start Elasticsearch using the following command.

<pre>
$ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
</pre>

<blockquote>
<p><strong>NOTE</strong>: Linux users might need to run <code>sudo sysctl -w vm.max_map_count=262144</code> to increase <code>vm.max_map_count</code>.</p>
</blockquote>

Start Kibana plugin for data visualization with Elasticsearch.

<pre>
 $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2
</pre>

* Configure logstash to format the Ballerina logs.

1. Create a file named <code>logstash.conf</code> with the following content.

<pre>
input {
 beats{ 
     port => 5044 
 }  ]
}

filter {
 grok{
     match => { 
     "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
     \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }
 } 
}
output { 
 elasticsearch{ 
     hosts => "elasticsearch:9200" 
     index => "store" 
     document_type => "store_logs" 
 } 
} 
</pre>

2. Save the above <code>logstash.conf</code> inside a directory named as <code>{SAMPLE_ROOT}\pipeline</code>.

3. Start the logstash container, replace the <code>{SAMPLE_ROOT}</code> with your directory name.

<pre>
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
</pre>

* Configure filebeat to ship the Ballerina logs.

1. Create a file named <code>filebeat.yml</code> with the following content.

<pre>
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"] 
</pre>

<blockquote>
<p><strong>NOTE</strong>: Modify the ownership of <code>filebeat.yml</code> file using <code>$chmod go-w filebeat.yml</code>.</p>
</blockquote>

2. Save the above <code>filebeat.yml</code> inside a directory named as <code>{SAMPLE_ROOT}\filebeat</code>.
3. Start the logstash container, replace the <code>{SAMPLE_ROOT}</code> with your directory name.
<pre>
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/passthrough/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
</pre>
Access Kibana to visualize the logs using the following URL.
<pre>http://localhost:5601</pre>




















