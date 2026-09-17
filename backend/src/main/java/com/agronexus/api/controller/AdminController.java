package com.agronexus.api.controller;

import com.agronexus.api.entity.EscrowStatus;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.TelemetryLogRepository;
import com.agronexus.api.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final TelemetryLogRepository telemetryLogRepository;

    public AdminController(UserRepository userRepository,
                           ProductRepository productRepository,
                           OrderRepository orderRepository,
                           TelemetryLogRepository telemetryLogRepository) {
        this.userRepository = userRepository;
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.telemetryLogRepository = telemetryLogRepository;
    }

    @GetMapping("/pending-users")
    public ResponseEntity<List<Map<String, Object>>> getPendingUsers() {
        List<Map<String, Object>> users = userRepository.findByIsVerifiedFalse()
                .stream()
                .map(this::toSafeUserPayload)
                .toList();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/users")
    public ResponseEntity<List<Map<String, Object>>> getUsers() {
        return ResponseEntity.ok(userRepository.findAll().stream()
                .map(this::toSafeUserPayload)
                .toList());
    }

    @PostMapping("/approve-user/{userId}")
    public ResponseEntity<Map<String, Object>> approveUser(@PathVariable Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account not found"));
        user.setIsVerified(true);
        return ResponseEntity.ok(toSafeUserPayload(userRepository.save(user)));
    }

    @PostMapping("/deapprove-user/{userId}")
    public ResponseEntity<Map<String, Object>> deapproveUser(@PathVariable Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account not found"));
        if (user.getRole() == com.agronexus.api.entity.Role.ADMIN) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Administrator accounts cannot be de-approved."));
        }
        user.setIsVerified(false);
        return ResponseEntity.ok(toSafeUserPayload(userRepository.save(user)));
    }

    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getMetrics() {
        BigDecimal escrowVolume = orderRepository.findAll().stream()
                .filter(order -> order.getEscrowStatus() == EscrowStatus.HELD_IN_ESCROW)
                .map(order -> order.getTotalEscrowAmount() == null
                        ? BigDecimal.ZERO
                        : order.getTotalEscrowAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> metrics = new HashMap<>();
        metrics.put("userCount", userRepository.count());
        metrics.put("productCount", productRepository.count());
        metrics.put("orderCount", orderRepository.count());
        metrics.put("telemetryAlertCount", telemetryLogRepository.findByIsAlertTriggeredTrue().size());
        metrics.put("escrowVolume", escrowVolume);
        return ResponseEntity.ok(metrics);
    }

    private Map<String, Object> toSafeUserPayload(User user) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("id", user.getId());
        payload.put("fullName", user.getFullName());
        payload.put("email", user.getEmail());
        payload.put("role", user.getRole().name());
        payload.put("phoneNumber", user.getPhoneNumber());
        payload.put("isVerified", user.getIsVerified());
        payload.put("createdAt", user.getCreatedAt());
        return payload;
    }
}
