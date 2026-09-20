package com.agronexus.api.controller;

import java.util.Map;
import java.util.Optional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.regex.Pattern;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.agronexus.api.entity.RefreshToken;
import com.agronexus.api.entity.Role;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.UserRepository;
import com.agronexus.api.entity.VerificationChallenge;
import com.agronexus.api.service.VerificationService;
import com.agronexus.api.security.JwtService;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final VerificationService verificationService;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public AuthController(UserRepository userRepository, JwtService jwtService,
            VerificationService verificationService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.verificationService = verificationService;
        this.passwordEncoder = new BCryptPasswordEncoder(12);
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String rawPassword = (String) payload.get("password");
        String fullName = (String) payload.get("fullName");
        String phone = (String) payload.get("phoneNumber");
        String nationalId = (String) payload.get("nationalId");
        if (fullName == null || fullName.trim().length() < 2
                || email == null || !Pattern.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", email)
                || rawPassword == null || rawPassword.length() < 10
                || phone == null || !Pattern.matches("^\\+?[1-9]\\d{7,14}$", phone)
                || nationalId == null || nationalId.trim().length() < 5) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Provide a valid legal name, email, phone, national ID, and password of at least 10 characters."));
        }
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

        // FR1.3: Farmers, Transporters, and Agronomists require administrative verification
        boolean requiresApproval = role == Role.FARMER || role == Role.TRANSPORTER || role == Role.AGRONOMIST;

        User user = User.builder()
                .fullName(fullName.trim())
                .email(email)
                .passwordHash(hashedPassword)
                .role(role)
                .phoneNumber((String) payload.get("phoneNumber"))
                .nationalIdHash(hash(nationalId.trim()))
                .emailVerified(false)
                .phoneVerified(false)
                .identityVerified(false)
                .biometricVerified(Boolean.TRUE.equals(payload.get("biometricVerified")))
                .isVerified(false)
                .location(geometryFactory.createPoint(new Coordinate(lon, lat)))
                .build();
        User saved = userRepository.save(user);
        try {
            verificationService.issue(saved, VerificationChallenge.Channel.EMAIL);
            verificationService.issue(saved, VerificationChallenge.Channel.PHONE);
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", e.getMessage()));
        }
        
        String message = requiresApproval 
            ? "Registration successful. Your account is pending administrative vetting by an AgroNexus Admin." 
            : "Registration successful. You may now login.";

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "userId", saved.getId(),
                "fullName", saved.getFullName(),
                "email", saved.getEmail(),
                "role", saved.getRole().name(),
                "isVerified", saved.getIsVerified(),
                "message", message
        ));
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verify(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String channelName = (String) payload.get("channel");
        String code = (String) payload.get("code");
        if (email == null || code == null || channelName == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email, channel, and verification code are required."));
        }
        try {
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new IllegalArgumentException("Registration could not be found."));
            VerificationChallenge.Channel channel = VerificationChallenge.Channel.valueOf(channelName.toUpperCase());
            verificationService.verify(user, channel, code);
            return ResponseEntity.ok(Map.of(
                    "emailVerified", user.getEmailVerified(),
                    "phoneVerified", user.getPhoneVerified(),
                    "isVerified", user.getIsVerified(),
                    "message", "Verification accepted. Complete the remaining checks before signing in."
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<?> resendVerification(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String channelName = (String) payload.get("channel");
        try {
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new IllegalArgumentException("Registration could not be found."));
            verificationService.issue(user, VerificationChallenge.Channel.valueOf(channelName.toUpperCase()));
            return ResponseEntity.ok(Map.of("message", "A new verification code was sent."));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
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

        // FR1.3: Block login if account is unverified
        if (Boolean.FALSE.equals(user.getIsVerified())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Account pending administrative approval. Please wait for an AgroNexus Admin to vet your credentials."));
        }

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

    @GetMapping("/me")
    public ResponseEntity<?> currentUser(@AuthenticationPrincipal User user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Authentication is required."));
        }
        return ResponseEntity.ok(Map.of(
                "userId", user.getId(),
                "role", user.getRole().name(),
                "email", user.getEmail(),
                "fullName", user.getFullName(),
                "isVerified", user.getIsVerified()
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
            if (Boolean.FALSE.equals(user.getIsVerified())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Account is no longer verified."));
            }
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

    private static String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder result = new StringBuilder();
            for (byte b : digest) result.append(String.format("%02x", b));
            return result.toString();
        } catch (Exception e) {
            throw new IllegalStateException("Unable to protect identity data.", e);
        }
    }
}