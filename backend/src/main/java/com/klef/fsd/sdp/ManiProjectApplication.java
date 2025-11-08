package com.klef.fsd.sdp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class ManiProjectApplication extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(ManiProjectApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(ManiProjectApplication.class, args);
        System.out.println("Mani Project is running successfully!");
    }
}
