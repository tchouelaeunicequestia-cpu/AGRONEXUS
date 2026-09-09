package com.agronexus.api.repository;

import com.agronexus.api.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * ==============================================================================
 * AgroNexus Product Produce Repository (PostGIS Spatial Radial Queries)
 * 
 * WHY: Provides database access and spatial proximity filtering for produce.
 * HOW: Leverages PostGIS ST_DWithin & GiST indexing for fast radial searches.
 * ==============================================================================
 */
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    // Find produce listed by a specific farmer
    List<Product> findByFarmerId(Long farmerId);

    // Filter active produce by category
    List<Product> findByCategoryAndIsActiveTrue(String category);

    /**
     * PostGIS Radial Distance Search Query
     * 
     * WHY: Returns produce listings within user-defined radius sorted by proximity.
     * HOW: Uses ST_DWithin on PostGIS geography point with GiST index acceleration.
     */
    @Query(value = "SELECT * FROM products p " +
                   "WHERE p.is_active = true " +
                   "AND ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography, :radiusMeters) " +
                   "ORDER BY ST_Distance(p.location, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography) ASC",
           nativeQuery = true)
    List<Product> findProductsWithinRadius(
            @Param("latitude") double latitude,
            @Param("longitude") double longitude,
            @Param("radiusMeters") double radiusMeters
    );
}
