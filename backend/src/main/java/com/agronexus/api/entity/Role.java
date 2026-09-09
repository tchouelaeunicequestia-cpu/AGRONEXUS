package com.agronexus.api.entity;

/**
 * ==============================================================================
 * AgroNexus User Roles Taxonomy
 * WHY: Defines the 5 primary RBAC roles specified in the project specification.
 * HOW: Enforced via Spring Security @PreAuthorize annotations on API routes.
 * ==============================================================================
 */
public enum Role {
    FARMER,
    BUYER,
    TRANSPORTER,
    AGRONOMIST,
    ADMIN
}
