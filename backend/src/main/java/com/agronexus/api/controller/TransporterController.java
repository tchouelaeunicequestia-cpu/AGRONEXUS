// src/main/java/com/agronexus/api/controller/TransporterController.java
package com.agronexus.api.controller;

import com.agronexus.api.repository.OrderRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/transporter")
public class TransporterController {

    private final OrderRepository orderRepository;

    public TransporterController(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @GetMapping("/metrics")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<?> getTransporterMetrics() {
        return ResponseEntity.ok(Map.of(
            "lockedEscrow", "100,000 XAF",
            "temp", "8.2°C",
            "odometer", "142 km",
            "jobs", 2
        ));
    }
}