package com.agronexus.api.security;

import com.agronexus.api.entity.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;

/**
 * ==============================================================================
 * AgroNexus JWT Security Token Service
 *
 * WHY: Generates signed JWT Bearer tokens upon successful login and validates
 *      them on every protected API request before granting access.
 *
 * HOW: Uses HMAC-SHA256 (HS256) cryptographic signing.
 *      Each JWT token payload carries three key claims:
 *        - sub      : the user's registered email address (used to reload profile from DB)
 *        - role     : the user's RBAC role (FARMER, BUYER, TRANSPORTER, AGRONOMIST, ADMIN)
 *        - userId   : the user's database ID (used for quick authorization lookups)
 *        - iat      : issued-at timestamp
 *        - exp      : expiration timestamp (24 hours from creation)
 *
 *      Token Flow:
 *        1. User logs in via POST /api/v1/auth/login
 *        2. AuthController calls generateToken(user) here
 *        3. Signed token is returned to the user
 *        4. User sends token in all requests: Authorization: Bearer <token>
 *        5. JwtAuthFilter calls validateToken() & extractEmail() on every request
 * ==============================================================================
 */
@Service
public class JwtService {

    @Value("${agronexus.jwt.secret}")
    private String jwtSecret;

    @Value("${agronexus.jwt.expiration-ms}")
    private long jwtExpirationMs;

    // Build HMAC-SHA256 signing key from the Base64-encoded secret in application.yml
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret));
    }

    // ===========================================================================
    // generateToken(User user)
    // PURPOSE: Creates a signed JWT containing the user's email, role, and userId.
    // CALLED BY: AuthController.loginUser() after successful credential verification.
    // ===========================================================================
    public String generateToken(User user) {
        return Jwts.builder()
                .subject(user.getEmail())                        // 'sub' claim: user email
                .claim("role", user.getRole().name())            // RBAC role claim
                .claim("userId", user.getId())                   // DB user ID claim
                .issuedAt(new Date())                            // 'iat' claim: current time
                .expiration(new Date(System.currentTimeMillis() + jwtExpirationMs)) // 'exp' claim
                .signWith(getSigningKey())                        // HMAC-SHA256 signature
                .compact();
    }

    // ===========================================================================
    // validateToken(String token)
    // PURPOSE: Verifies token signature and expiry on every protected API request.
    // CALLED BY: JwtAuthFilter on every incoming HTTP request header.
    // ===========================================================================
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            throw new RuntimeException("JWT token has expired. Please login again.");
        } catch (JwtException e) {
            throw new RuntimeException("Invalid JWT token. Access denied.");
        }
    }

    // ===========================================================================
    // extractEmail(String token)
    // PURPOSE: Reads the 'sub' claim (user email) from a validated token.
    // CALLED BY: JwtAuthFilter to reload the user profile from the database.
    // ===========================================================================
    public String extractEmail(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }

    // ===========================================================================
    // extractRole(String token)
    // PURPOSE: Reads the 'role' claim from a validated token for RBAC enforcement.
    // CALLED BY: JwtAuthFilter to set Spring Security granted authorities.
    // ===========================================================================
    public String extractRole(String token) {
        return (String) Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("role");
    }
}
