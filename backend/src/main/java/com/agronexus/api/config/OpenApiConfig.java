package com.agronexus.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * ==============================================================================
 * AgroNexus OpenAPI / Swagger Configuration
 *
 * WHY: Configures Swagger UI with JWT Bearer Token authentication support.
 * HOW: Adds the global 'Authorize' lock icon in Swagger UI so protected routes
 *      can be tested directly using a Bearer token.
 * ==============================================================================
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI agroNexusOpenAPI() {
        final String schemeName = "bearerAuth";
        return new OpenAPI()
                .info(new Info()
                        .title("AgroNexus Enterprise API")
                        .version("1.0.0")
                        .description("Integrated Agricultural Management Platform REST API"))
                .addSecurityItem(new SecurityRequirement().addList(schemeName))
                .components(new Components().addSecuritySchemes(schemeName,
                        new SecurityScheme()
                                .name(schemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}