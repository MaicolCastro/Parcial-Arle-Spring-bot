package com.peluqueria.citas.service;

import com.peluqueria.citas.dto.CitaRequest;
import com.peluqueria.citas.dto.CitaResponse;
import com.peluqueria.citas.model.CitaEntity;
import com.peluqueria.citas.model.CitaEstado;
import com.peluqueria.citas.repository.CitaRepository;
import com.peluqueria.jwt.JwtPrincipal;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class CitaService {

    private final CitaRepository citaRepository;

    public CitaService(CitaRepository citaRepository) {
        this.citaRepository = citaRepository;
    }

    public List<CitaResponse> listar(JwtPrincipal principal) {
        if ("ADMIN".equalsIgnoreCase(principal.role())) {
            return citaRepository.findAll().stream().map(this::toDto).toList();
        }
        return citaRepository.findAllByUserIdOrderByFechaHoraDesc(principal.userId()).stream()
                .map(this::toDto)
                .toList();
    }

    public CitaResponse obtener(Long id, JwtPrincipal principal) {
        CitaEntity c = citaRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        assertAccess(c, principal);
        return toDto(c);
    }

    @Transactional
    public CitaResponse crear(CitaRequest req, JwtPrincipal principal) {
        CitaEntity c = new CitaEntity();
        c.setUserId(principal.userId());
        c.setServicioId(req.servicioId());
        c.setFechaHora(req.fechaHora());
        c.setNotas(req.notas());
        if ("ADMIN".equalsIgnoreCase(principal.role()) && req.estado() != null) {
            c.setEstado(req.estado());
        } else {
            c.setEstado(CitaEstado.PENDIENTE);
        }
        return toDto(citaRepository.save(c));
    }

    @Transactional
    public CitaResponse actualizar(Long id, CitaRequest req, JwtPrincipal principal) {
        CitaEntity c = citaRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        assertAccess(c, principal);
        c.setServicioId(req.servicioId());
        c.setFechaHora(req.fechaHora());
        c.setNotas(req.notas());
        if (req.estado() != null) {
            if (!"ADMIN".equalsIgnoreCase(principal.role())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo ADMIN puede cambiar el estado");
            }
            c.setEstado(req.estado());
        }
        return toDto(citaRepository.save(c));
    }

    @Transactional
    public void eliminar(Long id, JwtPrincipal principal) {
        CitaEntity c = citaRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        assertAccess(c, principal);
        citaRepository.delete(c);
    }

    private void assertAccess(CitaEntity c, JwtPrincipal principal) {
        if ("ADMIN".equalsIgnoreCase(principal.role())) {
            return;
        }
        if (!c.getUserId().equals(principal.userId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }

    private CitaResponse toDto(CitaEntity c) {
        return new CitaResponse(c.getId(), c.getUserId(), c.getServicioId(), c.getFechaHora(), c.getNotas(), c.getEstado());
    }
}
