package com.agronexus.api.entity;

/**
 * ==============================================================================
 * AgroNexus Escrow Lifecycle Statuses
 * 
 * WHY: Manages the atomic state machine transitions of an agricultural transaction.
 * HOW: PENDING -> HELD_IN_ESCROW -> DISPATCHED -> IN_TRANSIT -> DELIVERED -> COMPLETED
 *      (or DISPUTED / REFUNDED).
 * ==============================================================================
 */
public enum EscrowStatus {
    PENDING,
    HELD_IN_ESCROW,
    DISPATCHED,
    IN_TRANSIT,
    DELIVERED,
    COMPLETED,
    DISPUTED,
    REFUNDED
}
