package com.agronexus.api.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * ==============================================================================
 * AgroNexus Domain-Guarded RAG AI Assistant Controller
 *
 * WHY: Evaluates prompt domain constraints and returns grounded FAO/USDA advice
 *      to eliminate AI hallucinations for rural agricultural producers.
 * HOW: Filters queries against domain keyword guardrails and returns authoritative
 *      post-harvest guidelines backed by international standard citations.
 * ==============================================================================
 */
@RestController
@RequestMapping("/api/v1/ai")
public class AiAssistantController {

    private static final List<String> ALLOWED_KEYWORDS = List.of(
        "crop", "maize", "fao", "post-harvest", "storage", "temperature", 
        "humidity", "cocoa", "grain", "mold", "pest", "aflatoxin", "harvest"
    );

    @PostMapping("/query")
    public ResponseEntity<Map<String, Object>> queryAssistant(@RequestBody Map<String, String> request) {
        String query = request.getOrDefault("query", "").toLowerCase();

        // 1. Domain Guardrail Validation
        boolean isAllowed = ALLOWED_KEYWORDS.stream().anyMatch(query::contains);

        if (!isAllowed) {
            return ResponseEntity.badRequest().body(Map.of(
                "status", "REJECTED",
                "answer", "Query outside approved agricultural domain. AgroNexus AI is strictly restricted to agronomy, post-harvest crop preservation, storage telemetry, and CEMAC/FAO trade standards."
            ));
        }

        // 2. Synthesize Grounded Advisory Response (Simulated RAG Vector Retrieval)
        String synthesizedAnswer;
        String citation;

        if (query.contains("maize") || query.contains("grain") || query.contains("storage")) {
            synthesizedAnswer = "According to FAO post-harvest grain storage standards, maize should be dried to a moisture content below 13.5% before bagging. Maintain silo storage temperatures below 25°C and relative humidity under 70% to prevent Aspergillus flavus proliferation and aflatoxin contamination.";
            citation = "FAO Agricultural Services Bulletin: Grain Storage Techniques & Management";
        } else if (query.contains("cocoa") || query.contains("cash crop")) {
            synthesizedAnswer = "Cocoa beans must undergo proper fermentation followed by sun-drying until internal moisture drops to 7%. Store in jute bags stacked on wooden pallets with a minimum 50cm clearance from warehouse walls to ensure continuous aeration.";
            citation = "UNECE / ICCO Standard Guidelines for Cocoa Post-Harvest Handling";
        } else {
            synthesizedAnswer = "General agronomic advisory: Ensure continuous monitoring of environmental parameters via your IoT storage nodes. Keep relative humidity within safe thresholds (60%-75%) to safeguard stored yields against spoilage.";
            citation = "AgroNexus Cyber-Physical Storage Framework & USDA Guidelines";
        }

        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "answer", synthesizedAnswer,
            "citation", citation
        ));
    }
}