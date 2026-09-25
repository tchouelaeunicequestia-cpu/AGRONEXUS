package com.agronexus.api.controller;

import com.agronexus.api.service.EscrowEngineService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/escrow")
@PreAuthorize("hasRole('ADMIN')")
public class AdminEscrowController {

    private final EscrowEngineService escrowEngineService;

    public AdminEscrowController(EscrowEngineService escrowEngineService) {
        this.escrowEngineService = escrowEngineService;
    }

    @PostMapping("/release/{orderCode}")
    public ResponseEntity<Map<String, Object>> executeAdminFundRelease(
            @PathVariable String orderCode,
            @RequestHeader(value = "X-Admin-User-Id", required = false) String adminId) {
        
        Map<String, Object> disbursementResult = escrowEngineService.disburseEscrowFunds(orderCode);
        return ResponseEntity.ok(disbursementResult);
    }
}