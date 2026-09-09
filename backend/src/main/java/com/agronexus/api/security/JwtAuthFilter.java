package com.agronexus.api.security;

import com.agronexus.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * ==============================================================================
 * AgroNexus JWT Authentication Request Filter
 *
 * WHY: Intercepts every HTTP request BEFORE it reaches any controller and
 *      validates the JWT Bearer token in the Authorization header.
 *
 * HOW: Extends OncePerRequestFilter (runs once per request, not per chain hop).
 *      Execution order:
 *        1. Extract token from "Authorization: Bearer <token>" header.
 *        2. If no token present → pass through (allows public /auth/* endpoints).
 *        3. Validate token via JwtService.validateToken().
 *        4. Extract email and role from the token payload.
 *        5. Load user from the database by email.
 *        6. Set a UsernamePasswordAuthenticationToken in the Spring SecurityContext,
 *           granting ROLE_<ROLE> authority for @PreAuthorize annotation enforcement.
 *        7. If token is invalid or expired → respond with 401 UNAUTHORIZED.
 * ==============================================================================
 */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public JwtAuthFilter(JwtService jwtService, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        // Step 1: No Authorization header or not a Bearer token → pass through
        // This allows public endpoints like /api/v1/auth/register and /api/v1/auth/login to remain open
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Step 2: Extract raw JWT token (strip "Bearer " prefix)
        final String rawToken = authHeader.substring(7);

        try {
            // Step 3: Validate token signature and expiration via JwtService
            jwtService.validateToken(rawToken);

            // Step 4: Extract email and role from token claims
            String email = jwtService.extractEmail(rawToken);
            String role  = jwtService.extractRole(rawToken);

            // Step 5: Only set authentication if SecurityContext is not already populated
            if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {

                // Step 6: Verify user still exists in database
                userRepository.findByEmail(email).ifPresent(user -> {

                    // Build Spring Security authority from the user's RBAC role
                    // Convention: ROLE_FARMER, ROLE_BUYER, ROLE_ADMIN, etc.
                    List<SimpleGrantedAuthority> authorities = List.of(
                            new SimpleGrantedAuthority("ROLE_" + role)
                    );

                    // Create authentication token and set it in the SecurityContext
                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(user, null, authorities);

                    SecurityContextHolder.getContext().setAuthentication(authToken);
                });
            }

            // Step 7: Pass request to the next filter in the chain
            filterChain.doFilter(request, response);

        } catch (RuntimeException e) {
            // Step 8: Token is invalid or expired → reject with 401 UNAUTHORIZED
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write(
                    "{\"error\": \"" + e.getMessage() + "\"}"
            );
        }
    }
}
