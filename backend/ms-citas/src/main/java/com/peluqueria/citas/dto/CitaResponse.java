package com.peluqueria.citas.dto;

import com.peluqueria.citas.model.CitaEstado;

import java.time.Instant;

public record CitaResponse(Long id, Long userId, Long servicioId, Instant fechaHora, String notas, CitaEstado estado) {
}
