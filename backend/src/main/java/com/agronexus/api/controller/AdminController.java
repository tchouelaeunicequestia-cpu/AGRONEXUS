package com.agronexus.api.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.agronexus.api.entity.User;
import com.agronexus.api.repository.UserRepository;

/**
 * ==============================================================================
 * AgroNexus Admin Control & Vetting Controller (FR1.3)
 * WHY: Manages administrative approval workflows for pending producer, transporter,
 *      and agronomist accounts.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    private final UserRepository userRepository;

    public AdminController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // GET /api/v1/admin/pending-users - List all accounts awaiting verification
    @GetMapping("/pending-users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<User>> getPendingUsers() {
        List<User> pendingUsers = userRepository.findAll().stream()
                .filter(u -> u.getIsVerified() != null && !u.getIsVerified())
                .toList();
        return ResponseEntity.ok(pendingUsers);
    }

    // POST /api/v1/admin/approve-user/{userId} - Approve a pending user account
    @PostMapping("/approve-user/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> approveUser(@PathVariable Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User account not found"));
        
        user.setIsVerified(true);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "message", "User account " + user.getEmail() + " successfully verified and approved.",
                "userId", user.getId(),
                "role", user.getRole().name()
        ));
    }
}