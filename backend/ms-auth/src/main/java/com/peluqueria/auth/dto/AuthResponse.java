package com.peluqueria.auth.dto;

public record AuthResponse(String token, String email, String role, Long userId) {
}
