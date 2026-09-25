// src/main/java/com/agronexus/api/controller/EscrowController.java
package com.agronexus.api.controller;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.agronexus.api.entity.Order;
import com.agronexus.api.entity.User;
import com.agronexus.api.model.EscrowTransaction;
import com.agronexus.api.repository.EscrowRepository;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.service.EscrowEngineService;

@RestController
@RequestMapping("/api/v1/escrow")
public class EscrowController {

    private final EscrowRepository escrowRepository;
    private final EscrowEngineService escrowEngineService;
    private final OrderRepository orderRepository;

    public EscrowController(EscrowRepository escrowRepository, EscrowEngineService escrowEngineService,
                            OrderRepository orderRepository) {
        this.escrowRepository = escrowRepository;
        this.escrowEngineService = escrowEngineService;
        this.orderRepository = orderRepository;
    }

    @PostMapping("/order")
    @PreAuthorize("hasAnyRole('BUYER', 'ADMIN')")
    public ResponseEntity<?> createEscrowOrder(@RequestBody Map<String, Object> payload) {
        try {
            Long buyerId = ((Number) payload.get("buyerId")).longValue();
            Long productId = ((Number) payload.get("productId")).longValue();
            Double quantity = ((Number) payload.get("quantity")).doubleValue();
            Boolean isSelfPickup = payload.get("isSelfPickup") == null
                    ? Boolean.FALSE
                    : Boolean.valueOf(payload.get("isSelfPickup").toString());
            String deliveryAddress = (String) payload.get("deliveryAddress");

            return ResponseEntity.status(201).body(escrowEngineService.createEscrowOrder(
                    buyerId, productId, quantity, null, isSelfPickup, deliveryAddress));
        } catch (NullPointerException | ClassCastException | NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "buyerId, productId, and quantity are required and must be valid."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/order/{orderCode}/quote")
    @PreAuthorize("hasRole('TRANSPORTER')")
    public ResponseEntity<?> submitTransportQuote(
            @PathVariable String orderCode,
            @RequestBody Map<String, Object> payload,
            @AuthenticationPrincipal User transporter) {
        try {
            BigDecimal transportFee = new BigDecimal(payload.get("transportFee").toString());
            return ResponseEntity.ok(escrowEngineService.submitTransportQuote(
                    orderCode, transporter, transportFee));
        } catch (NullPointerException | NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "transportFee is required and must be a valid amount."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/order/{orderCode}/approve-quote")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<?> approveTransportQuote(
            @PathVariable String orderCode,
            @AuthenticationPrincipal User buyer) {
        return ResponseEntity.ok(escrowEngineService.approveTransportQuote(orderCode, buyer));
    }

    @GetMapping("/buyer/orders")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<List<Map<String, Object>>> getBuyerQuoteOrders(
            @AuthenticationPrincipal User buyer) {
        return ResponseEntity.ok(orderRepository.findByBuyerId(buyer.getId()).stream()
                .filter(order -> order.getEscrowStatus() == com.agronexus.api.entity.EscrowStatus.PENDING)
                .map(this::orderSummary)
                .collect(Collectors.toList()));
    }

    private Map<String, Object> orderSummary(Order order) {
        return Map.of(
                "orderCode", order.getOrderCode(),
                "productTitle", order.getProduct().getTitle(),
                "quantity", order.getQuantity(),
                "itemCost", order.getItemCost(),
                "transportFee", order.getTransportFee(),
                "platformServiceFee", order.getDepositBuffer(),
                // Retained for clients using the original response contract.
                "depositBuffer", order.getDepositBuffer(),
                "deliveryAddress", order.getDeliveryAddress(),
                "status", order.getEscrowStatus().name());
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