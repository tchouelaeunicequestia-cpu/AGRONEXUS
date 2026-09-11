package com.agronexus.api.controller;

import com.agronexus.api.entity.Order;
import com.agronexus.api.service.EscrowEngineService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

/**
 * ==============================================================================
 * AgroNexus Financial Escrow Transaction Controller
 *
 * WHY: Processes order creation, Mobile Money/Orange Money deposit calculations,
 *      escrow fund locking, and disbursement payouts.
 * HOW: Interacts directly with EscrowEngineService business logic to manage order state.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/escrow")
public class EscrowController {

    private final EscrowEngineService escrowEngineService;

    public EscrowController(EscrowEngineService escrowEngineService) {
        this.escrowEngineService = escrowEngineService;
    }

    // POST /api/v1/escrow/order — Lock funds in escrow depository (Buyers & Admins only)
    @PostMapping("/order")
    @PreAuthorize("hasAnyRole('BUYER', 'ADMIN')")
    public ResponseEntity<?> createEscrowOrder(@RequestBody Map<String, Object> payload) {
        Long buyerId = ((Number) payload.get("buyerId")).longValue();
        Long productId = ((Number) payload.get("productId")).longValue();
        Double quantity = ((Number) payload.get("quantity")).doubleValue();
        Boolean isSelfPickup = (Boolean) payload.getOrDefault("isSelfPickup", false);
        String deliveryAddress = (String) payload.getOrDefault("deliveryAddress", "Farm Gate Pickup");

        BigDecimal transportFee = payload.containsKey("transportFee") ?
                new BigDecimal(payload.get("transportFee").toString()) : null;

        Map<String, Object> result = escrowEngineService.createEscrowOrder(
                buyerId, productId, quantity, transportFee, isSelfPickup, deliveryAddress);

        return ResponseEntity.ok(result);
    }

    // POST /api/v1/escrow/disburse/{orderCode} — Disburse payment upon receipt (Buyers & Admins only)
    @PostMapping("/disburse/{orderCode}")
    @PreAuthorize("hasAnyRole('ADMIN', 'BUYER')")
    public ResponseEntity<Order> disburseFunds(@PathVariable String orderCode) {
        Order updatedOrder = escrowEngineService.disburseEscrowFunds(orderCode);
        return ResponseEntity.ok(updatedOrder);
    }
}