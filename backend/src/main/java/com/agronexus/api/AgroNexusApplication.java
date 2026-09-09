package com.agronexus.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * ==============================================================================
 * AgroNexus Enterprise Main Application Entry Point
 * 
 * WHY: Bootstraps the Spring Boot 3.x microservice environment, initializes
 *      Spring Data JPA PostGIS spatial mapping, Spring Security filters, and
 *      launches the embedded HTTP Web Container on port 8080.
 * 
 * HOW: Annotated with @SpringBootApplication to enable Component Scanning
 *      for all packages under com.agronexus.api.* and execute SpringApplication.run().
 * ==============================================================================
 */
@SpringBootApplication
public class AgroNexusApplication {

    public static void main(String[] args) {
        SpringApplication.run(AgroNexusApplication.class, args);
    }
}
