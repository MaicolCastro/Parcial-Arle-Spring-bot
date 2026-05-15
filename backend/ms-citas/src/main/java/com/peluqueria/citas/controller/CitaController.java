package com.peluqueria.citas.controller;

import com.peluqueria.citas.dto.CitaRequest;
import com.peluqueria.citas.dto.CitaResponse;
import com.peluqueria.citas.service.CitaService;
import com.peluqueria.jwt.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/citas")
public class CitaController {

    private final CitaService citaService;

    public CitaController(CitaService citaService) {
        this.citaService = citaService;
    }

    @GetMapping
    public List<CitaResponse> list(@AuthenticationPrincipal JwtPrincipal principal) {
        return citaService.listar(principal);
    }

    @GetMapping("/{id}")
    public CitaResponse get(@PathVariable Long id, @AuthenticationPrincipal JwtPrincipal principal) {
        return citaService.obtener(id, principal);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CitaResponse create(@Valid @RequestBody CitaRequest body, @AuthenticationPrincipal JwtPrincipal principal) {
        return citaService.crear(body, principal);
    }

    @PutMapping("/{id}")
    public CitaResponse update(@PathVariable Long id, @Valid @RequestBody CitaRequest body,
                               @AuthenticationPrincipal JwtPrincipal principal) {
        return citaService.actualizar(id, body, principal);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id, @AuthenticationPrincipal JwtPrincipal principal) {
        citaService.eliminar(id, principal);
    }
}
