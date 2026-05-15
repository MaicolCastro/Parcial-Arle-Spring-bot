package com.peluqueria.servicios.service;

import com.peluqueria.jwt.JwtPrincipal;
import com.peluqueria.servicios.dto.ServicioRequest;
import com.peluqueria.servicios.dto.ServicioResponse;
import com.peluqueria.servicios.model.ServicioEntity;
import com.peluqueria.servicios.repository.ServicioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ServicioService {

    private final ServicioRepository servicioRepository;

    public ServicioService(ServicioRepository servicioRepository) {
        this.servicioRepository = servicioRepository;
    }

    public List<ServicioResponse> listar() {
        return servicioRepository.findAll().stream().map(this::toDto).toList();
    }

    public ServicioResponse obtener(Long id) {
        return servicioRepository.findById(id).map(this::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @Transactional
    public ServicioResponse crear(ServicioRequest req, JwtPrincipal principal) {
        requireAdmin(principal);
        ServicioEntity e = new ServicioEntity();
        e.setNombre(req.nombre().trim());
        e.setDescripcion(req.descripcion());
        e.setPrecio(req.precio());
        e.setDuracionMinutos(req.duracionMinutos());
        return toDto(servicioRepository.save(e));
    }

    @Transactional
    public ServicioResponse actualizar(Long id, ServicioRequest req, JwtPrincipal principal) {
        requireAdmin(principal);
        ServicioEntity e = servicioRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        e.setNombre(req.nombre().trim());
        e.setDescripcion(req.descripcion());
        e.setPrecio(req.precio());
        e.setDuracionMinutos(req.duracionMinutos());
        return toDto(servicioRepository.save(e));
    }

    @Transactional
    public void eliminar(Long id, JwtPrincipal principal) {
        requireAdmin(principal);
        ServicioEntity e = servicioRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        servicioRepository.delete(e);
    }

    private void requireAdmin(JwtPrincipal principal) {
        if (!"ADMIN".equalsIgnoreCase(principal.role())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo ADMIN puede modificar el catálogo");
        }
    }

    private ServicioResponse toDto(ServicioEntity e) {
        return new ServicioResponse(e.getId(), e.getNombre(), e.getDescripcion(), e.getPrecio(), e.getDuracionMinutos());
    }
}
