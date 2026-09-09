package com.agronexus.api.entity;

import jakarta.persistence.*; // JPA ORM annotations
import lombok.*; // Lombok getters, setters, builders
import org.locationtech.jts.geom.Point; // PostGIS Spatial geometry
import java.math.BigDecimal;
import java.time.ZonedDateTime;

/**
 * ==============================================================================
 * AgroNexus Order & Escrow Depository Entity
 * 
 * WHY: Manages trade orders, financial escrow deposits, delivery freight, and self-pickup.
 * HOW: Maps to PostgreSQL 'orders' table and enforces the escrow formula:
 *      - Freight Delivery: Total = Item Cost + Transport Fee + (2 * Deposit Buffer)
 *      - Direct Self-Pickup: Total = Item Cost + (1 * Deposit Buffer) [Transport Fee = 0]
 * ==============================================================================
 */
@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_code", nullable = false, unique = true, length = 36)
    private String orderCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id", nullable = false)
    private User buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transporter_id", nullable = true) // Nullable when buyer chooses Self-Pickup
    private User transporter;

    @Column(name = "is_self_pickup", nullable = false) // True if buyer collects directly from farm
    private Boolean isSelfPickup;

    @Column(name = "quantity", nullable = false)
    private Double quantity;

    @Column(name = "item_cost", nullable = false, precision = 10, scale = 2)
    private BigDecimal itemCost;

    @Column(name = "transport_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal transportFee;

    @Column(name = "deposit_buffer", nullable = false, precision = 10, scale = 2)
    private BigDecimal depositBuffer;

    @Column(name = "total_escrow_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalEscrowAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "escrow_status", nullable = false, length = 30)
    private EscrowStatus escrowStatus;

    @Column(name = "delivery_address", nullable = false, columnDefinition = "TEXT")
    private String deliveryAddress;

    @Column(name = "destination_location", columnDefinition = "geometry(Point, 4326)")
    private Point destinationLocation;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = ZonedDateTime.now();
        updatedAt = ZonedDateTime.now();
        if (isSelfPickup == null) {
            isSelfPickup = false;
        }
        if (escrowStatus == null) {
            escrowStatus = isSelfPickup ? EscrowStatus.READY_FOR_PICKUP : EscrowStatus.HELD_IN_ESCROW;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = ZonedDateTime.now();
    }
}
