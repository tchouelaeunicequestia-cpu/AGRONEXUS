package com.agronexus.api.controller;

import com.agronexus.api.entity.Product;
import com.agronexus.api.entity.User;
import com.agronexus.api.repository.ProductRepository;
import com.agronexus.api.repository.UserRepository;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * ==============================================================================
 * AgroNexus Spatial Produce Catalog Controller
 *
 * WHY: Provides RESTful endpoints for produce listing management and PostGIS
 *      radial proximity searching based on buyer location coordinates.
 * HOW: Farmers construct product entries with spatial coordinates (Point).
 *      Buyers perform radial discovery querying PostGIS ST_DWithin mechanics.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public ProductController(ProductRepository productRepository, UserRepository userRepository) {
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    // POST /api/v1/products — Create a produce listing (Farmers & Admins only)
    @PostMapping
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    public ResponseEntity<?> createProduct(@RequestBody Map<String, Object> payload) {
        Long farmerId = ((Number) payload.get("farmerId")).longValue();
        User farmer = userRepository.findById(farmerId)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found"));

        double lat = ((Number) payload.get("latitude")).doubleValue();
        double lon = ((Number) payload.get("longitude")).doubleValue();

        Product product = Product.builder()
                .farmer(farmer)
                .title((String) payload.get("title"))
                .category((String) payload.get("category"))
                .description((String) payload.get("description"))
                .pricePerUnit(new BigDecimal(payload.get("pricePerUnit").toString()))
                .unitType((String) payload.getOrDefault("unitType", "kg"))
                .availableQuantity(((Number) payload.get("availableQuantity")).doubleValue())
                .location(geometryFactory.createPoint(new Coordinate(lon, lat)))
                .imageUrl((String) payload.get("imageUrl"))
                .isActive(true)
                .build();

        Product saved = productRepository.save(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // GET /api/v1/products/nearby — Radial PostGIS spatial search
    @GetMapping("/nearby")
    public ResponseEntity<List<Product>> getNearbyProducts(
            @RequestParam double latitude,
            @RequestParam double longitude,
            @RequestParam(defaultValue = "50000") double radiusMeters) {

        List<Product> products = productRepository.findProductsWithinRadius(latitude, longitude, radiusMeters);
        return ResponseEntity.ok(products);
    }
}