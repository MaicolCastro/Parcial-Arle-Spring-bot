package com.peluqueria.gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import java.util.List;
import java.util.Map;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@Configuration
public class GatewayRootConfig {

    @Bean
    public RouterFunction<ServerResponse> gatewayWelcome() {
        return route(
                GET("/"),
                req -> ServerResponse.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(
                                Map.of(
                                        "servicio", "api-gateway — Peluquería",
                                        "mensaje", "No hay página aquí: el gateway solo enruta la API.",
                                        "rutas",
                                        List.of(
                                                "POST /api/auth/register",
                                                "POST /api/auth/login",
                                                "GET/POST/PUT/DELETE /api/citas (JWT)",
                                                "GET/POST/PUT/DELETE /api/servicios (JWT)"),
                                        "frontend", "Usa la SPA (p. ej. http://localhost o http://localhost:5173 en desarrollo)")));
    }
}
