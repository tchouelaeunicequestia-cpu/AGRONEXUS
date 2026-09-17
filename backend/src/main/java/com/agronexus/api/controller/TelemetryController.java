package com.agronexus.api.controller;

import com.agronexus.api.entity.TelemetryLog;
import com.agronexus.api.repository.TelemetryLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * ==============================================================================
 * AgroNexus Cyber-Physical IoT Telemetry Ingestion Controller
 *
 * WHY: Ingests real-time environmental data from ESP32 storage sensor nodes
 *      and serves telemetry logs to monitoring dashboards.
 * HOW: Evaluates safety thresholds (temperature, humidity, gas levels) upon
 *      ingestion to flag environmental alerts for crop preservation.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/telemetry")
public class TelemetryController {

    private final TelemetryLogRepository telemetryLogRepository;
    private final CopyOnWriteArrayList<SseEmitter> alertSubscribers =
            new CopyOnWriteArrayList<>();

    public TelemetryController(TelemetryLogRepository telemetryLogRepository) {
        this.telemetryLogRepository = telemetryLogRepository;
    }

    // POST /api/v1/telemetry — ESP32 Sensor Hardware Payload Ingestion
    @PostMapping
    public ResponseEntity<?> ingestTelemetry(@RequestBody Map<String, Object> payload) {
        String nodeId = (String) payload.get("nodeId");
        Float temp = ((Number) payload.get("temp")).floatValue();
        Float humidity = ((Number) payload.get("humidity")).floatValue();
        Integer gas = ((Number) payload.get("gas")).intValue();

        // Safety Threshold Evaluation (FAO Crop Storage Standards)
        boolean alert = temp > 30.0f || humidity > 85.0f || gas > 400;
        String alertMsg = alert ? "CRITICAL: Storage environmental parameters exceed FAO safe threshold!" : null;

        TelemetryLog log = TelemetryLog.builder()
                .nodeId(nodeId)
                .temperature(temp)
                .humidity(humidity)
                .gasLevel(gas)
                .isAlertTriggered(alert)
                .alertMessage(alertMsg)
                .build();

        TelemetryLog saved = telemetryLogRepository.save(log);
        if (alert) {
            publishAlert(saved);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping(value = "/alerts/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @PreAuthorize("hasRole('AGRONOMIST')")
    public SseEmitter streamAlerts() {
        SseEmitter emitter = new SseEmitter(0L);
        alertSubscribers.add(emitter);
        emitter.onCompletion(() -> alertSubscribers.remove(emitter));
        emitter.onTimeout(() -> alertSubscribers.remove(emitter));
        emitter.onError(error -> alertSubscribers.remove(emitter));
        try {
            emitter.send(SseEmitter.event()
                    .name("connected")
                    .data(Map.of("status", "connected")));
        } catch (IOException error) {
            alertSubscribers.remove(emitter);
            emitter.completeWithError(error);
        }
        return emitter;
    }

    // GET /api/v1/telemetry/node/{nodeId} — Latest 50 sensor logs for a storage unit
    @GetMapping("/node/{nodeId}")
    public ResponseEntity<List<TelemetryLog>> getNodeLogs(@PathVariable String nodeId) {
        return ResponseEntity.ok(telemetryLogRepository.findTop50ByNodeIdOrderByRecordedAtDesc(nodeId));
    }

    private void publishAlert(TelemetryLog alert) {
        alertSubscribers.removeIf(emitter -> {
            try {
                emitter.send(SseEmitter.event()
                        .name("telemetry-alert")
                        .data(alert));
                return false;
            } catch (IOException error) {
                emitter.completeWithError(error);
                return true;
            }
        });
    }
}