package com.xyz.productService.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/health")
@AllArgsConstructor
@Tag(name = "Health API", description = "Endpoints for checking health")
public class HealthController {

    private static final Logger logger = LoggerFactory.getLogger(HealthController.class);

    @GetMapping
    @Operation(summary = "Service health check", description = "Check if the product service is running")
    public ResponseEntity<String> healthCheck() {
        logger.info("Health check endpoint was accessed.");
        return ResponseEntity.ok("UP");
    }
}
