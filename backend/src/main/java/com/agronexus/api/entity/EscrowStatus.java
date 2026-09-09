package com.agronexus.api.entity;

/**
 * ==============================================================================
 * AgroNexus Escrow Lifecycle Statuses
 * 
 * WHY: Manages the atomic state machine transitions of an agricultural transaction.
 * HOW: Supports both Transporter Freight Delivery AND Direct Buyer Self-Pickup:
 *      - Freight Delivery: PENDING -> HELD_IN_ESCROW -> DISPATCHED -> IN_TRANSIT -> DELIVERED -> COMPLETED
 *      - Direct Self-Pickup: PENDING -> HELD_IN_ESCROW -> READY_FOR_PICKUP -> SELF_PICKUP_COMPLETED -> COMPLETED
 * ==============================================================================
 */
public enum EscrowStatus {
    PENDING,
    HELD_IN_ESCROW,
    READY_FOR_PICKUP,        // Buyer chose self-pickup; produce ready at farm gate
    SELF_PICKUP_COMPLETED,   // Buyer collected produce directly from farmer
    DISPATCHED,              // Transporter accepted freight job
    IN_TRANSIT,              // Transporter carrying produce to buyer
    DELIVERED,               // Transporter delivered produce to buyer address
    COMPLETED,               // Verification confirmed; escrow funds disbursed
    DISPUTED,                // Dispute logged for admin arbitration
    REFUNDED                 // Funds returned to buyer
}
