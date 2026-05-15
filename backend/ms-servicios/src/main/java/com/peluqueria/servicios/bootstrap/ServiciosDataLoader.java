package com.peluqueria.servicios.bootstrap;

import com.peluqueria.servicios.model.ServicioEntity;
import com.peluqueria.servicios.repository.ServicioRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class ServiciosDataLoader implements ApplicationRunner {

    private final ServicioRepository servicioRepository;

    public ServiciosDataLoader(ServicioRepository servicioRepository) {
        this.servicioRepository = servicioRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (servicioRepository.count() > 0) {
            return;
        }
        servicioRepository.save(s("Corte caballero", "Corte clásico o degradado", new BigDecimal("18.00"), 30));
        servicioRepository.save(s("Corte + barba", "Arreglo completo", new BigDecimal("25.00"), 45));
        servicioRepository.save(s("Tinte / color", "Consulta incluida", new BigDecimal("45.00"), 90));
    }

    private ServicioEntity s(String nombre, String desc, BigDecimal precio, int min) {
        ServicioEntity e = new ServicioEntity();
        e.setNombre(nombre);
        e.setDescripcion(desc);
        e.setPrecio(precio);
        e.setDuracionMinutos(min);
        return e;
    }
}
