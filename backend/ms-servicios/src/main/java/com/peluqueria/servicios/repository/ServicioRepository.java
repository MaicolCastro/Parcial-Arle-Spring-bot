package com.peluqueria.servicios.repository;

import com.peluqueria.servicios.model.ServicioEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ServicioRepository extends JpaRepository<ServicioEntity, Long> {
}
