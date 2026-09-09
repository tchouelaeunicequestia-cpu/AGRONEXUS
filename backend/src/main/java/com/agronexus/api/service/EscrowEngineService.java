package com.agronexus.api.service;

import com.agronexus.api.entity.*;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

/**
 * ==============================================================================
 * AgroNexus Escrow Financial Engine Service
 * 
 * WHY: Enforces financial escrow rules, MoMo/Orange withdrawal fee coverage, and payouts.
 * HOW: Calculates total locked funds including MTN/Orange Money cashout fee buffers (1.5%)
 *      and supports both Freight Delivery and Direct Buyer Self-Pickup workflows.
 * ==============================================================================
 */
@Service
public class EscrowEngineService {

    // 1.5% Standard MTN Mobile Money (MoMo) & Orange Money cashout fee rate
    private static final BigDecimal MOMO_ORANGE_CASHOUT_FEE_RATE = new BigDecimal("0.015");

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public EscrowEngineService(OrderRepository orderRepository,
                               ProductRepository productRepository,
                               UserRepository userRepository) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    /**
     * Create Order and Lock Funds in Escrow (MTN MoMo / Orange Money compatible)
     */
    @Transactional
    public Order createEscrowOrder(Long buyerId, Long productId, Double quantity, 
                                  BigDecimal transportFee, Boolean isSelfPickup, String deliveryAddress) {
        User buyer = userRepository.findById(buyerId)
                .orElseThrow(() -> new RuntimeException("Buyer not found"));
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        boolean selfPickup = (isSelfPickup != null && isSelfPickup);
        BigDecimal itemCost = product.getPricePerUnit().multiply(BigDecimal.valueOf(quantity));
        BigDecimal freight = selfPickup ? BigDecimal.ZERO : (transportFee != null ? transportFee : BigDecimal.valueOf(5000));
        
        // Calculate MTN / Orange Money cashout fee buffer (1.5%) so Farmer receives exact net price
        BigDecimal momoCashoutFee = itemCost.multiply(MOMO_ORANGE_CASHOUT_FEE_RATE).setScale(2, RoundingMode.CEILING);
        BigDecimal depositBuffer = momoCashoutFee.add(BigDecimal.valueOf(5000)); // MoMo fee + security buffer

        // Total Depository Formula Execution
        BigDecimal totalEscrow = selfPickup ? 
                itemCost.add(depositBuffer) : 
                itemCost.add(freight).add(depositBuffer.multiply(BigDecimal.valueOf(2)));

        Order order = Order.builder()
                .orderCode("ORD-2026-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .buyer(buyer)
                .product(product)
                .isSelfPickup(selfPickup)
                .quantity(quantity)
                .itemCost(itemCost)
                .transportFee(freight)
                .depositBuffer(depositBuffer)
                .totalEscrowAmount(totalEscrow)
                .escrowStatus(selfPickup ? EscrowStatus.READY_FOR_PICKUP : EscrowStatus.HELD_IN_ESCROW)
                .deliveryAddress(deliveryAddress)
                .build();

        return orderRepository.save(order);
    }

    /**
     * Disburse Escrow Funds upon Verified Order Completion
     */
    @Transactional
    public Order disburseEscrowFunds(String orderCode) {
        Order order = orderRepository.findByOrderCode(orderCode)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getEscrowStatus() == EscrowStatus.COMPLETED) {
            throw new IllegalStateException("Escrow funds already disbursed for this order.");
        }

        order.setEscrowStatus(EscrowStatus.COMPLETED);
        return orderRepository.save(order);
    }
}
