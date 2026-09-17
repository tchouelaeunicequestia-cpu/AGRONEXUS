package com.agronexus.api.controller;

import com.agronexus.api.entity.Product;
import com.agronexus.api.entity.TelemetryLog;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.TelemetryLogRepository;
import com.agronexus.api.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farmers")
public class FarmerDashboardController {

    private final ProductRepository productRepository;
    private final TelemetryLogRepository telemetryLogRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public FarmerDashboardController(ProductRepository productRepository, 
                                     TelemetryLogRepository telemetryLogRepository,
                                     OrderRepository orderRepository,
                                     UserRepository userRepository) {
        this.productRepository = productRepository;
        this.telemetryLogRepository = telemetryLogRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
    }

    // GET /api/v1/farmers/{farmerId}/dashboard
    @GetMapping("/{farmerId}/dashboard")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    public ResponseEntity<?> getFarmerDashboard(@PathVariable Long farmerId,
                                                @AuthenticationPrincipal User authenticatedUser) {
        if (!authenticatedUser.getId().equals(farmerId)
                && authenticatedUser.getRole().name().equals("FARMER")) {
            return ResponseEntity.status(403).body(Map.of("error", "You can only view your own dashboard."));
        }
        return buildDashboard(farmerId);
    }

    @GetMapping("/me/dashboard")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<?> getMyDashboard(@AuthenticationPrincipal User authenticatedUser) {
        return buildDashboard(authenticatedUser.getId());
    }

    private ResponseEntity<?> buildDashboard(Long farmerId) {
        List<Product> products = productRepository.findByFarmerId(farmerId);
        double totalYield = products.stream()
                .mapToDouble(Product::getAvailableQuantity)
                .sum();
        TelemetryLog telemetry = telemetryLogRepository.findTopByOrderByRecordedAtDesc();
        double escrowBalance = orderRepository.findByProductFarmerId(farmerId).stream()
                .filter(order -> order.getEscrowStatus() != null
                        && order.getEscrowStatus().name().equals("HELD_IN_ESCROW"))
                .map(order -> order.getTotalEscrowAmount().doubleValue())
                .reduce(0.0, Double::sum);

        return ResponseEntity.ok(Map.of(
            "escrowBalance", escrowBalance,
            "activeLotsCount", products.size(),
            "totalYieldKg", totalYield,
            "siloTemp", telemetry == null ? null : telemetry.getTemperature(),
            "siloHumidity", telemetry == null ? null : telemetry.getHumidity(),
            "siloGas", telemetry == null ? null : telemetry.getGasLevel(),
            "telemetryAvailable", telemetry != null
        ));
    }
}