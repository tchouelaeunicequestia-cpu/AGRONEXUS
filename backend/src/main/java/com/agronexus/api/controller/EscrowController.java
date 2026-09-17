// src/main/java/com/agronexus/api/controller/EscrowController.java
package com.agronexus.api.controller;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.agronexus.api.model.EscrowTransaction;
import com.agronexus.api.repository.EscrowRepository;

@RestController
@RequestMapping("/api/v1/escrow")
public class EscrowController {

    private final EscrowRepository escrowRepository;

    public EscrowController(EscrowRepository escrowRepository) {
        this.escrowRepository = escrowRepository;
    }

    @PostMapping("/initialize")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<?> initializeEscrowPayment(@RequestBody Map<String, Object> payload) {
        try {
            Long buyerId = Long.valueOf(payload.get("buyerId").toString());
            Long farmerId = Long.valueOf(payload.get("farmerId").toString());
            BigDecimal amount = new BigDecimal(payload.get("amount").toString());
            String providerStr = payload.get("provider").toString(); // MTN_MOMO, ORANGE_MONEY, BANK_ACCOUNT
            String phoneOrAccount = payload.get("payerPhoneOrAccount").toString();

            EscrowTransaction.PaymentProvider provider = EscrowTransaction.PaymentProvider.valueOf(providerStr);

            EscrowTransaction tx = new EscrowTransaction();
            tx.setTransactionReference("ANX-ESCROW-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
            tx.setBuyerId(buyerId);
            tx.setFarmerId(farmerId);
            tx.setAmount(amount);
            tx.setProvider(provider);
            tx.setPayerPhoneOrAccount(phoneOrAccount);
            // In live integration, this initiates USSD prompt / Direct Request-to-Pay via Campay/PayUnit
            tx.setStatus(EscrowTransaction.EscrowStatus.LOCKED_IN_ESCROW); 

            escrowRepository.save(tx);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Funds successfully locked into AgroNexus CEMAC Escrow vault.",
                "reference", tx.getTransactionReference(),
                "status", tx.getStatus()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/release/{reference}")
    @PreAuthorize("hasRole('FARMER') or hasRole('AGRONOMIST')")
    public ResponseEntity<?> releaseEscrow(@PathVariable String reference) {
        EscrowTransaction tx = escrowRepository.findByTransactionReference(reference)
            .orElseThrow(() -> new RuntimeException("Escrow transaction not found."));

        tx.setStatus(EscrowTransaction.EscrowStatus.RELEASED_TO_FARMER);
        tx.setUpdatedAt(LocalDateTime.now());
        escrowRepository.save(tx);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Escrow successfully disbursed to Farmer's registered Mobile Money/Bank payout line.",
            "reference", reference
        ));
    }
}