package com.agronexus.api.repository;

import com.agronexus.api.entity.VerificationChallenge;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface VerificationChallengeRepository extends JpaRepository<VerificationChallenge, Long> {
    Optional<VerificationChallenge> findTopByUserIdAndChannelAndConsumedFalseOrderByIdDesc(
            Long userId, VerificationChallenge.Channel channel);
}
