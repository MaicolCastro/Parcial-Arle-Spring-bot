package com.peluqueria.auth.service;

import com.peluqueria.auth.dto.AuthResponse;
import com.peluqueria.auth.dto.LoginRequest;
import com.peluqueria.auth.dto.RegisterRequest;
import com.peluqueria.auth.model.Role;
import com.peluqueria.auth.model.UserEntity;
import com.peluqueria.auth.repository.UserRepository;
import com.peluqueria.jwt.JwtTokenService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtTokenService jwtTokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmailIgnoreCase(req.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email ya registrado");
        }
        UserEntity u = new UserEntity();
        u.setEmail(req.email().trim().toLowerCase());
        u.setPasswordHash(passwordEncoder.encode(req.password()));
        u.setRole(userRepository.count() == 0 ? Role.ADMIN : Role.USER);
        userRepository.save(u);
        String token = jwtTokenService.generate(u.getId(), u.getEmail(), u.getRole().name());
        return new AuthResponse(token, u.getEmail(), u.getRole().name(), u.getId());
    }

    public AuthResponse login(LoginRequest req) {
        UserEntity u = userRepository.findByEmailIgnoreCase(req.email().trim().toLowerCase())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales inválidas"));
        if (!passwordEncoder.matches(req.password(), u.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales inválidas");
        }
        String token = jwtTokenService.generate(u.getId(), u.getEmail(), u.getRole().name());
        return new AuthResponse(token, u.getEmail(), u.getRole().name(), u.getId());
    }
}
