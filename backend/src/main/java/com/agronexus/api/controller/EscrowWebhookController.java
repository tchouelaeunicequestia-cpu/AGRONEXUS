// src/main/java/com/agronexus/api/controller/EscrowWebhookController.java
package com.agronexus.api.controller;

import java.time.LocalDateTime;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.agronexus.api.model.EscrowTransaction;
import com.agronexus.api.repository.EscrowRepository;

@RestController
@RequestMapping("/api/v1/webhooks/payments")
public class EscrowWebhookController {

    private final EscrowRepository escrowRepository;

    public EscrowWebhookController(EscrowRepository escrowRepository) {
        this.escrowRepository = escrowRepository;
    }

    @PostMapping("/callback")
    public ResponseEntity<?> handlePaymentCallback(@RequestBody Map<String, Object> webhookPayload) {
        try {
            String reference = (String) webhookPayload.get("reference");
            String status = (String) webhookPayload.get("status"); // SUCCESS, FAILED
            
            EscrowTransaction tx = escrowRepository.findByTransactionReference(reference)
                .orElseThrow(() -> new RuntimeException("Escrow reference not found: " + reference));

            if ("SUCCESS".equalsIgnoreCase(status) || "COMPLETED".equalsIgnoreCase(status)) {
                tx.setStatus(EscrowTransaction.EscrowStatus.LOCKED_IN_ESCROW);
            } else {
                tx.setStatus(EscrowTransaction.EscrowStatus.FAILED);
            }
            
            tx.setUpdatedAt(LocalDateTime.now());
            escrowRepository.save(tx);

            return ResponseEntity.ok(Map.of(
                "received", true,
                "reference", reference,
                "currentStatus", tx.getStatus().name()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}