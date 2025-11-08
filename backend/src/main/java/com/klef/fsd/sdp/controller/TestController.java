package com.klef.fsd.sdp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @GetMapping("/")
    public String home() {
        return "✅ Backend is running successfully!";
    }

    @GetMapping("/api/hello")
    public String hello() {
        return "Hello from Event Management API!";
    }
}
