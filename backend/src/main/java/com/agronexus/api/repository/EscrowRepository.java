// src/main/java/com/agronexus/api/repository/EscrowRepository.java
package com.agronexus.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.agronexus.api.model.EscrowTransaction;

@Repository
public interface EscrowRepository extends JpaRepository<EscrowTransaction, Long> {
    Optional<EscrowTransaction> findByTransactionReference(String reference);
    List<EscrowTransaction> findByBuyerId(Long buyerId);
    List<EscrowTransaction> findByFarmerId(Long farmerId);
}