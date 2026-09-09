package com.agronexus.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.ZonedDateTime;

/**
 * ==============================================================================
 * AgroNexus Cyber-Physical IoT Telemetry Log Entity (Optional Component)
 * 
 * WHY: Stores timestamped ambient temperature, humidity, and gas metrics from ESP32 nodes.
 * HOW: Loosely coupled with nullable fields so marketplace trading operates
 *      100% independently if hardware nodes are offline.
 * ==============================================================================
 */
@Entity
@Table(name = "telemetry_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TelemetryLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "node_id", nullable = false, length = 50)
    private String nodeId;

    @Column(name = "storage_facility_name", nullable = true, length = 100)
    private String storageFacilityName;

    @Column(name = "temperature", nullable = false)
    private Float temperature;

    @Column(name = "humidity", nullable = false)
    private Float humidity;

    @Column(name = "gas_level", nullable = false)
    private Integer gasLevel;

    @Column(name = "is_alert_triggered", nullable = true)
    private Boolean isAlertTriggered;

    @Column(name = "alert_message", nullable = true, length = 255)
    private String alertMessage;

    @Column(name = "recorded_at")
    private ZonedDateTime recordedAt;

    @PrePersist
    protected void onCreate() {
        recordedAt = ZonedDateTime.now();
        if (isAlertTriggered == null) {
            isAlertTriggered = false;
        }
    }
}
