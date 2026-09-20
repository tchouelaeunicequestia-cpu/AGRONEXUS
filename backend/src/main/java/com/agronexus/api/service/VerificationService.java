package com.agronexus.api.service;

import com.agronexus.api.entity.User;
import com.agronexus.api.entity.VerificationChallenge;
import com.agronexus.api.repository.UserRepository;
import com.agronexus.api.repository.VerificationChallengeRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.ZonedDateTime;

@Service
public class VerificationService {
    private static final int MAX_ATTEMPTS = 5;
    private final SecureRandom random = new SecureRandom();
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
    private final VerificationChallengeRepository challenges;
    private final UserRepository users;

    @Value("${agronexus.verification.delivery-mode:disabled}")
    private String deliveryMode;

    public VerificationService(VerificationChallengeRepository challenges, UserRepository users) {
        this.challenges = challenges;
        this.users = users;
    }

    public void issue(User user, VerificationChallenge.Channel channel) {
        if ("disabled".equalsIgnoreCase(deliveryMode)) {
            throw new IllegalStateException("Verification delivery is not configured.");
        }
        String code = String.format("%06d", random.nextInt(1_000_000));
        challenges.save(VerificationChallenge.builder()
                .user(user)
                .channel(channel)
                .codeHash(encoder.encode(code))
                .expiresAt(ZonedDateTime.now().plusMinutes(10))
                .attempts(0)
                .consumed(false)
                .build());
        if ("console".equalsIgnoreCase(deliveryMode)) {
            System.out.printf("AgroNexus %s verification code for user %d: %s%n",
                    channel.name(), user.getId(), code);
        } else {
            throw new IllegalStateException("Verification provider integration is not configured.");
        }
    }

    public void verify(User user, VerificationChallenge.Channel channel, String code) {
        var challenge = challenges.findTopByUserIdAndChannelAndConsumedFalseOrderByIdDesc(
                user.getId(), channel).orElseThrow(() -> new IllegalArgumentException("No active verification code."));
        if (challenge.isConsumed() || challenge.getExpiresAt().isBefore(ZonedDateTime.now())) {
            throw new IllegalArgumentException("Verification code expired.");
        }
        challenge.setAttempts(challenge.getAttempts() + 1);
        if (challenge.getAttempts() > MAX_ATTEMPTS || !encoder.matches(code, challenge.getCodeHash())) {
            challenges.save(challenge);
            throw new IllegalArgumentException("Invalid verification code.");
        }
        challenge.setConsumed(true);
        challenges.save(challenge);
        if (channel == VerificationChallenge.Channel.EMAIL) user.setEmailVerified(true);
        if (channel == VerificationChallenge.Channel.PHONE) user.setPhoneVerified(true);
        user.setIsVerified(Boolean.TRUE.equals(user.getEmailVerified())
                && Boolean.TRUE.equals(user.getPhoneVerified())
                && Boolean.TRUE.equals(user.getIdentityVerified())
                && Boolean.TRUE.equals(user.getBiometricVerified()));
        users.save(user);
    }
}
