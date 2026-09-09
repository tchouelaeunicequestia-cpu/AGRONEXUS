package com.agronexus.api.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * ==============================================================================
 * AgroNexus Spring Security Configuration
 *
 * WHY: Defines the HTTP security rules, CORS policy, stateless JWT session
 *      management, and registers JwtAuthFilter into the Spring Security chain.
 *
 * HOW:
 *   1. CSRF is DISABLED — stateless REST APIs use JWT instead of CSRF cookies.
 *   2. Sessions are STATELESS — Spring creates no HttpSession on the server,
 *      all auth state lives inside the JWT token on the client.
 *   3. PUBLIC ROUTES: /api/v1/auth/register and /api/v1/auth/login are open.
 *   4. ALL OTHER ROUTES require a valid JWT Bearer token in Authorization header.
 *   5. @EnableMethodSecurity activates @PreAuthorize("hasRole('FARMER')") annotations
 *      on controller methods for fine-grained RBAC access control.
 *   6. CORS is configured to allow cross-origin requests from the Flutter Web client.
 * ==============================================================================
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity // Enables @PreAuthorize for role-based endpoint protection
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                // 1. Disable CSRF — not needed for stateless JWT REST APIs
                .csrf(AbstractHttpConfigurer::disable)

                // 2. Apply CORS configuration for Flutter Web client cross-origin requests
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // 3. Enforce STATELESS session management — no server-side HTTP sessions
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // 4. Authorization rules
                .authorizeHttpRequests(auth -> auth
                        // PUBLIC: Registration and login do not require a token
                        .requestMatchers("/api/v1/auth/**").permitAll()
                        // ALL OTHER endpoints: require a valid JWT Bearer token
                        .anyRequest().authenticated())

                // 5. Register JwtAuthFilter BEFORE Spring's default auth filter
                //    This ensures JWT is validated before any route is processed
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)

                .build();
    }

    /**
     * CORS Configuration
     * WHY: Allows the Flutter Web frontend and mobile clients to call the REST API
     *      from different origins (e.g., vercel.app, localhost:3000, mobile app).
     * HOW: Permits all origins for development. Restrict to specific domain in production.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*")); // Restrict to your domain in production
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
