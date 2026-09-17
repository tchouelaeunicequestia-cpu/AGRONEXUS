// src/main/java/com/agronexus/api/model/EscrowTransaction.java
package com.agronexus.api.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "escrow_transactions")
public class EscrowTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String transactionReference; // e.g., MTN-MOMO-2026-... or ORANGE-PAY-...
    private Long buyerId;
    private Long farmerId;
    private BigDecimal amount;
    private String currency = "XAF";
    
    @Enumerated(EnumType.STRING)
    private PaymentProvider provider; // MTN_MOMO, ORANGE_MONEY, BANK_ACCOUNT
    
    @Enumerated(EnumType.STRING)
    private EscrowStatus status = EscrowStatus.PENDING;

    private String payerPhoneOrAccount;
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    public enum PaymentProvider {
        MTN_MOMO, ORANGE_MONEY, BANK_ACCOUNT
    }

    public enum EscrowStatus {
        PENDING, LOCKED_IN_ESCROW, RELEASED_TO_FARMER, REFUNDED_TO_BUYER, FAILED
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTransactionReference() { return transactionReference; }
    public void setTransactionReference(String transactionReference) { this.transactionReference = transactionReference; }
    public Long getBuyerId() { return buyerId; }
    public void setBuyerId(Long buyerId) { this.buyerId = buyerId; }
    public Long getFarmerId() { return farmerId; }
    public void setFarmerId(Long farmerId) { this.farmerId = farmerId; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
    public PaymentProvider getProvider() { return provider; }
    public void setProvider(PaymentProvider provider) { this.provider = provider; }
    public EscrowStatus getStatus() { return status; }
    public void setStatus(EscrowStatus status) { this.status = status; }
    public String getPayerPhoneOrAccount() { return payerPhoneOrAccount; }
    public void setPayerPhoneOrAccount(String payerPhoneOrAccount) { this.payerPhoneOrAccount = payerPhoneOrAccount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}