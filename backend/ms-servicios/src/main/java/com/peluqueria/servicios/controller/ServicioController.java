package com.peluqueria.servicios.controller;

import com.peluqueria.jwt.JwtPrincipal;
import com.peluqueria.servicios.dto.ServicioRequest;
import com.peluqueria.servicios.dto.ServicioResponse;
import com.peluqueria.servicios.service.ServicioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/servicios")
public class ServicioController {

    private final ServicioService servicioService;

    public ServicioController(ServicioService servicioService) {
        this.servicioService = servicioService;
    }

    @GetMapping
    public List<ServicioResponse> list() {
        return servicioService.listar();
    }

    @GetMapping("/{id}")
    public ServicioResponse get(@PathVariable Long id) {
        return servicioService.obtener(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ServicioResponse create(@Valid @RequestBody ServicioRequest body,
                                   @AuthenticationPrincipal JwtPrincipal principal) {
        return servicioService.crear(body, principal);
    }

    @PutMapping("/{id}")
    public ServicioResponse update(@PathVariable Long id, @Valid @RequestBody ServicioRequest body,
                                   @AuthenticationPrincipal JwtPrincipal principal) {
        return servicioService.actualizar(id, body, principal);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id, @AuthenticationPrincipal JwtPrincipal principal) {
        servicioService.eliminar(id, principal);
    }
}
