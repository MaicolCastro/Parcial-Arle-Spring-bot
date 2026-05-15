package com.peluqueria.auth.bootstrap;

import com.peluqueria.auth.model.Role;
import com.peluqueria.auth.model.UserEntity;
import com.peluqueria.auth.repository.UserRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Usuario demo solo si la base está vacía (primera ejecución).
 */
@Component
public class AuthDemoDataLoader implements ApplicationRunner {

    public static final String DEMO_EMAIL = "admin@peluqueria.demo";
    public static final String DEMO_PASSWORD = "Admin123";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthDemoDataLoader(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) {
            return;
        }
        UserEntity u = new UserEntity();
        u.setEmail(DEMO_EMAIL);
        u.setPasswordHash(passwordEncoder.encode(DEMO_PASSWORD));
        u.setRole(Role.ADMIN);
        userRepository.save(u);
    }
}
