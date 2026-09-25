package com.agronexus.api.service;

import com.agronexus.api.entity.*;
import com.agronexus.api.repository.OrderRepository;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;
import java.util.UUID;

/**
 * ==============================================================================
 * AgroNexus Escrow Financial Engine Service
 * 
 * WHY: Enforces transparent escrow fees and payouts.
 * HOW: Routes escrow deposits to official Admin Mobile Money Wallets:
 *      - Orange Money Escrow Wallet: +237 694002750
 *      - MTN MoMo Escrow Wallet:     +237 651305141
 *      Generates instant admin notifications including the Farmer's direct registered phone number.
 * ==============================================================================
 */
@Service
public class EscrowEngineService {

    // Official Admin Escrow Mobile Money Merchant Numbers
    public static final String OFFICIAL_ORANGE_MONEY_ESCROW = "+237694002750";
    public static final String OFFICIAL_MTN_MOMO_ESCROW     = "+237651305141";

    // A single, transparent platform handling fee applied to the item cost.
    private static final BigDecimal PLATFORM_SERVICE_FEE_RATE = new BigDecimal("0.05");

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final OrderEmailService orderEmailService;

    public EscrowEngineService(OrderRepository orderRepository,
                               ProductRepository productRepository,
                               UserRepository userRepository,
                               OrderEmailService orderEmailService) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
        this.orderEmailService = orderEmailService;
    }

    /**
     * Create Order and Lock Funds in Escrow with Mobile Money Notification
     */
    @Transactional
    public Map<String, Object> createEscrowOrder(Long buyerId, Long productId, Double quantity, 
                                                BigDecimal transportFee, Boolean isSelfPickup, String deliveryAddress) {
        if (quantity == null || quantity <= 0) {
            throw new IllegalArgumentException("Quantity must be greater than zero.");
        }
        if (transportFee != null && transportFee.signum() < 0) {
            throw new IllegalArgumentException("Transport fee cannot be negative.");
        }

        User buyer = userRepository.findById(buyerId)
                .orElseThrow(() -> new RuntimeException("Buyer not found"));
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));
        if (product.getAvailableQuantity() < quantity) {
            throw new IllegalArgumentException("Requested quantity exceeds available produce.");
        }
        User farmer = product.getFarmer();

        boolean selfPickup = (isSelfPickup != null && isSelfPickup);
        BigDecimal itemCost = product.getPricePerUnit().multiply(BigDecimal.valueOf(quantity));
        BigDecimal freight = selfPickup ? BigDecimal.ZERO : (transportFee != null ? transportFee : BigDecimal.valueOf(5000));
        
        // Keep the fee proportional to the order and charge it once for either fulfilment mode.
        BigDecimal depositBuffer = itemCost.multiply(PLATFORM_SERVICE_FEE_RATE)
                .setScale(2, RoundingMode.CEILING);

        BigDecimal totalEscrow = itemCost.add(freight).add(depositBuffer);

        String orderCode = "ORD-2026-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Order order = Order.builder()
                .orderCode(orderCode)
                .buyer(buyer)
                .product(product)
                .isSelfPickup(selfPickup)
                .quantity(quantity)
                .itemCost(itemCost)
                .transportFee(freight)
                .depositBuffer(depositBuffer)
                .totalEscrowAmount(selfPickup ? totalEscrow : BigDecimal.ZERO)
                .escrowStatus(selfPickup
                        ? EscrowStatus.HELD_IN_ESCROW
                        : EscrowStatus.TRANSPORT_QUOTE_PENDING)
                .deliveryAddress(deliveryAddress)
                .build();

        Order savedOrder = orderRepository.save(order);
        orderEmailService.sendOrderCreatedEmail(savedOrder);

        // Admin Notification Payload with Farmer Registered Phone Number
        String adminNotification = String.format(
            "🔔 [AGRONEXUS ORDER ALERT]\nOrder Code: %s\nStatus: %s\nEscrow Amount: %s\nBuyer: %s (Phone: %s)\nFarmer: %s (Phone: %s)\nProduce: %s (%s kg)\nMode: %s",
            orderCode,
            selfPickup ? EscrowStatus.HELD_IN_ESCROW : EscrowStatus.TRANSPORT_QUOTE_PENDING,
            selfPickup ? totalEscrow.toPlainString() + " XAF" : "Pending transporter quote",
            buyer.getFullName(),
            buyer.getPhoneNumber() != null ? buyer.getPhoneNumber() : "Not Provided",
            farmer.getFullName(),
            farmer.getPhoneNumber() != null ? farmer.getPhoneNumber() : "Not Provided",
            product.getTitle(),
            quantity,
            selfPickup ? "DIRECT SELF-PICKUP" : "FREIGHT DELIVERY"
        );

        return Map.of(
            "order", savedOrder,
            "orangeMoneyEscrowWallet", OFFICIAL_ORANGE_MONEY_ESCROW,
            "mtnMomoEscrowWallet", OFFICIAL_MTN_MOMO_ESCROW,
            "farmerPhoneNumber", farmer.getPhoneNumber() != null ? farmer.getPhoneNumber() : "N/A",
            "adminNotificationText", adminNotification
        );
    }

    @Transactional
    public Order submitTransportQuote(String orderCode, User transporter, BigDecimal transportFee) {
        if (transportFee == null || transportFee.signum() < 0) {
            throw new IllegalArgumentException("Transport fee must be zero or greater.");
        }

        Order order = orderRepository.findByOrderCode(orderCode)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        if (Boolean.TRUE.equals(order.getIsSelfPickup())) {
            throw new IllegalStateException("Self-pickup orders do not require a transport quote.");
        }
        if (order.getEscrowStatus() != EscrowStatus.TRANSPORT_QUOTE_PENDING) {
            throw new IllegalStateException("This order is not waiting for a transport quote.");
        }

        order.setTransporter(transporter);
        order.setTransportFee(transportFee);
        order.setEscrowStatus(EscrowStatus.PENDING);
        return orderRepository.save(order);
    }

    @Transactional
    public Order approveTransportQuote(String orderCode, User buyer) {
        Order order = orderRepository.findByOrderCode(orderCode)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        if (!order.getBuyer().getId().equals(buyer.getId())) {
            throw new SecurityException("Only the buyer who created the order can approve its quote.");
        }
        if (order.getEscrowStatus() != EscrowStatus.PENDING
                || order.getTransporter() == null
                || order.getTransportFee() == null) {
            throw new IllegalStateException("A transporter quote must be submitted before approval.");
        }

        BigDecimal totalEscrow = order.getItemCost()
                .add(order.getTransportFee())
                .add(order.getDepositBuffer());
        order.setTotalEscrowAmount(totalEscrow);
        order.setEscrowStatus(EscrowStatus.HELD_IN_ESCROW);
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
