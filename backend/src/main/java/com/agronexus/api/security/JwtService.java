package com.agronexus.api.security;

import com.agronexus.api.entity.RefreshToken;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.RefreshTokenRepository;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${agronexus.jwt.secret}")
    private String jwtSecret;

    // 15 Minutes Access Token Lifetime (Short-Lived)
    private static final long ACCESS_TOKEN_EXPIRATION_MS = 15 * 60 * 1000;

    // 7 Days Refresh Token Lifetime (Long-Lived)
    private static final long REFRESH_TOKEN_EXPIRATION_MS = 7 * 24 * 60 * 60 * 1000L;

    private final RefreshTokenRepository refreshTokenRepository;

    public JwtService(RefreshTokenRepository refreshTokenRepository) {
        this.refreshTokenRepository = refreshTokenRepository;
    }

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret));
    }

    public String generateAccessToken(User user) {
        return Jwts.builder()
                .subject(user.getEmail())
                .claim("role", user.getRole().name())
                .claim("userId", user.getId())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + ACCESS_TOKEN_EXPIRATION_MS))
                .signWith(getSigningKey())
                .compact();
    }

    @Transactional
    public RefreshToken createRefreshToken(User user) {
        // Upsert approach: Find existing refresh token for the user or create a new one to prevent duplicate key violations
        RefreshToken refreshToken = refreshTokenRepository.findByUser(user)
                .map(existingToken -> {
                    existingToken.setToken(UUID.randomUUID().toString());
                    existingToken.setExpiryDate(Instant.now().plusMillis(REFRESH_TOKEN_EXPIRATION_MS));
                    existingToken.setRevoked(false);
                    return existingToken;
                })
                .orElseGet(() -> RefreshToken.builder()
                .user(user)
                .token(UUID.randomUUID().toString())
                .expiryDate(Instant.now().plusMillis(REFRESH_TOKEN_EXPIRATION_MS))
                .revoked(false)
                .build());

        return refreshTokenRepository.save(refreshToken);
    }

    @Transactional
    public RefreshToken verifyAndRotateRefreshToken(String tokenStr) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new RuntimeException("Invalid refresh token."));

        if (refreshToken.isRevoked()) {
            refreshTokenRepository.deleteByUser(refreshToken.getUser());
            throw new RuntimeException("Security Breach: Revoked refresh token reused. All sessions terminated.");
        }

        if (refreshToken.getExpiryDate().isBefore(Instant.now())) {
            refreshTokenRepository.delete(refreshToken);
            throw new RuntimeException("Refresh token has expired. Please log in again.");
        }

        refreshToken.setRevoked(true);
        refreshTokenRepository.save(refreshToken);

        return createRefreshToken(refreshToken.getUser());
    }

    @Transactional
    public void revokeRefreshToken(String tokenStr) {
        refreshTokenRepository.findByToken(tokenStr).ifPresent(token -> {
            token.setRevoked(true);
            refreshTokenRepository.save(token);
        });
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            throw new RuntimeException("JWT token has expired. Please refresh token.");
        } catch (JwtException e) {
            throw new RuntimeException("Invalid JWT token. Access denied.");
        }
    }

    public String extractEmail(String token) {
        return Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token).getPayload().getSubject();
    }

    public String extractRole(String token) {
        return (String) Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token).getPayload().get("role");
    }
}
