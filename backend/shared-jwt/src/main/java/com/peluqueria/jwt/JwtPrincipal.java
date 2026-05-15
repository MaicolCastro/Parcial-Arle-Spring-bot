package com.peluqueria.jwt;

public record JwtPrincipal(Long userId, String email, String role) {
}
