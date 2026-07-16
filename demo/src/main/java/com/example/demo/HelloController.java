package com.example.demo;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.springframework.beans.factory.annotation.Value;

@RestController
public class HelloController {

  private final RestTemplate restTemplate;

  @Value("http://billing-service.springapp.svc.cluster.local:9090")
  private String fakeServiceUrl;

  public HelloController() {
    this.restTemplate = new RestTemplate();
  }

  @GetMapping("/hello")
  public String hello() {
    // Call the upstream fake-service.
    // If fake-service returns a 5xx or 4xx error, RestTemplate throws an exception.
    // Spring Boot handles the exception by returning a 500 to the user,
    // and Micrometer automatically records the failure in
    // http_server_requests_seconds_count!
    ResponseEntity<String> response = restTemplate.getForEntity(fakeServiceUrl, String.class);

    return "Success! Upstream says: " + response.getBody();
  }
}
