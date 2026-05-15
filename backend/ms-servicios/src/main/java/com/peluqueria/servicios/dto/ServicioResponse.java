package com.peluqueria.servicios.dto;

import java.math.BigDecimal;

public record ServicioResponse(Long id, String nombre, String descripcion, BigDecimal precio, Integer duracionMinutos) {
}
