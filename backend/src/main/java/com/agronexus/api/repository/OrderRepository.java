package com.agronexus.api.repository;

import com.agronexus.api.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ==============================================================================
 * AgroNexus Order & Escrow Repository
 *
 * WHY: Provides database access methods for Order entity.
 * HOW: findByOrderCode() is used by EscrowEngineService to locate specific
 *      orders for state transitions and escrow fund disbursement.
 * ==============================================================================
 */
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    // Used by EscrowEngineService to locate an order for state transitions
    Optional<Order> findByOrderCode(String orderCode);

    // Retrieve all orders placed by a specific buyer
    List<Order> findByBuyerId(Long buyerId);

    // Retrieve all orders assigned to a specific transporter
    List<Order> findByTransporterId(Long transporterId);
}
