package com.peluqueria.citas.dto;

import com.peluqueria.citas.model.CitaEstado;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public record CitaRequest(
        Long servicioId,
        @NotNull Instant fechaHora,
        @Size(max = 500) String notas,
        CitaEstado estado
) {
}
