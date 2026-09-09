package com.agronexus.api.controller;

import com.agronexus.api.entity.Role;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.UserRepository;
import com.agronexus.api.security.JwtService;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

/**
 * ==============================================================================
 * AgroNexus Authentication & Identity Management Controller
 *
 * WHY: Exposes two public endpoints that do not require a JWT token:
 *      1. /register - Creates a new user account and stores hashed credentials.
 *      2. /login    - Validates credentials and returns a signed JWT token.
 *
 * HOW: On registration, the user's password is hashed using BCrypt (strength=12)
 *      before being stored. The GPS coordinates (latitude/longitude) are converted
 *      into a PostGIS Point geometry and stored in the 'users' table.
 *      On login, the stored BCrypt hash is compared with the raw password.
 *      If valid, a JWT token signed with HMAC-SHA256 is returned for subsequent requests.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    // PostGIS GeometryFactory configured for WGS84 coordinate system (SRID 4326)
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public AuthController(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        // BCrypt password hashing with strength 12 (2^12 = 4096 hashing rounds)
        this.passwordEncoder = new BCryptPasswordEncoder(12);
    }

    // ===========================================================================
    // POST /api/v1/auth/register
    // PURPOSE: Creates a new user account across all 5 platform roles.
    // ROLES SUPPORTED: FARMER, BUYER, TRANSPORTER, AGRONOMIST, ADMIN
    // ===========================================================================
    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> payload) {

        String email = (String) payload.get("email");
        String rawPassword = (String) payload.get("password");

        // Check if email is already registered
        if (userRepository.findByEmail(email).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Email address is already registered."));
        }

        // Parse GPS location from request or default to Yaoundé, Cameroon
        double lat = payload.containsKey("latitude") ? ((Number) payload.get("latitude")).doubleValue() : 3.8480;
        double lon = payload.containsKey("longitude") ? ((Number) payload.get("longitude")).doubleValue() : 11.5021;

        // Hash the user's raw password using BCrypt before storing
        String hashedPassword = passwordEncoder.encode(rawPassword);

        // Parse the role string from the payload and map to Role enum (default: BUYER)
        Role role;
        try {
            role = Role.valueOf(((String) payload.getOrDefault("role", "BUYER")).toUpperCase());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Invalid role. Allowed values: FARMER, BUYER, TRANSPORTER, AGRONOMIST, ADMIN"));
        }

        // Build and persist the User entity
        User user = User.builder()
                .fullName((String) payload.get("fullName"))
                .email(email)
                .passwordHash(hashedPassword)
                .role(role)
                .phoneNumber((String) payload.get("phoneNumber"))
                .isVerified(true)
                .location(geometryFactory.createPoint(new Coordinate(lon, lat)))
                .build();

        User saved = userRepository.save(user);

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "userId",   saved.getId(),
                "fullName", saved.getFullName(),
                "email",    saved.getEmail(),
                "role",     saved.getRole().name(),
                "message",  "Registration successful. You may now login."
        ));
    }

    // ===========================================================================
    // POST /api/v1/auth/login
    // PURPOSE: Validates credentials and returns a signed JWT Bearer token.
    // HOW: Compares raw password with BCrypt hash using passwordEncoder.matches().
    //      JWT is generated and signed externally by JwtService (see security config).
    // ===========================================================================
    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody Map<String, Object> payload) {

        String email    = (String) payload.get("email");
        String rawPassword = (String) payload.get("password");

        Optional<User> userOpt = userRepository.findByEmail(email);

        if (userOpt.isEmpty() || !passwordEncoder.matches(rawPassword, userOpt.get().getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid email or password. Please try again."));
        }

        User user = userOpt.get();

return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED).body(Map.of(
                "error", "JWT issuance is not implemented yet."
        ));
    }
}
