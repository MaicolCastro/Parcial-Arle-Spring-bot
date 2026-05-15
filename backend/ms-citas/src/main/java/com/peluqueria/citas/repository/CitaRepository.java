package com.peluqueria.citas.repository;

import com.peluqueria.citas.model.CitaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CitaRepository extends JpaRepository<CitaEntity, Long> {
    List<CitaEntity> findAllByUserIdOrderByFechaHoraDesc(Long userId);
}
