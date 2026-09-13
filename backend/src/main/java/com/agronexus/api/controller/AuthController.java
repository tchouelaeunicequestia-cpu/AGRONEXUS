package com.agronexus.api.controller;

import com.agronexus.api.entity.RefreshToken;
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

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public AuthController(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = new BCryptPasswordEncoder(12);
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String rawPassword = (String) payload.get("password");

        if (userRepository.findByEmail(email).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Email address is already registered."));
        }

        double lat = payload.containsKey("latitude") ? ((Number) payload.get("latitude")).doubleValue() : 3.8480;
        double lon = payload.containsKey("longitude") ? ((Number) payload.get("longitude")).doubleValue() : 11.5021;
        String hashedPassword = passwordEncoder.encode(rawPassword);

        Role role;
        try {
            role = Role.valueOf(((String) payload.getOrDefault("role", "BUYER")).toUpperCase());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Invalid role. Allowed values: FARMER, BUYER, TRANSPORTER, AGRONOMIST, ADMIN"));
        }

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
                "userId", saved.getId(),
                "fullName", saved.getFullName(),
                "email", saved.getEmail(),
                "role", saved.getRole().name(),
                "message", "Registration successful. You may now login."
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String rawPassword = (String) payload.get("password");

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty() || !passwordEncoder.matches(rawPassword, userOpt.get().getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid email or password. Please try again."));
        }

        User user = userOpt.get();
        String accessToken = jwtService.generateAccessToken(user);
        RefreshToken refreshToken = jwtService.createRefreshToken(user);

        return ResponseEntity.ok(Map.of(
                "accessToken", accessToken,
                "refreshToken", refreshToken.getToken(),
                "userId", user.getId(),
                "role", user.getRole().name(),
                "email", user.getEmail(),
                "fullName", user.getFullName()
        ));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> payload) {
        String requestRefreshToken = payload.get("refreshToken");

        if (requestRefreshToken == null || requestRefreshToken.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Refresh token is required."));
        }

        try {
            RefreshToken newRefreshToken = jwtService.verifyAndRotateRefreshToken(requestRefreshToken);
            User user = newRefreshToken.getUser();
            String newAccessToken = jwtService.generateAccessToken(user);

            return ResponseEntity.ok(Map.of(
                    "accessToken", newAccessToken,
                    "refreshToken", newRefreshToken.getToken()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logoutUser(@RequestBody Map<String, String> payload) {
        String requestRefreshToken = payload.get("refreshToken");
        if (requestRefreshToken != null) {
            jwtService.revokeRefreshToken(requestRefreshToken);
        }
        return ResponseEntity.ok(Map.of("message", "Logged out successfully."));
    }
}