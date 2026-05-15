package com.peluqueria.auth.config;

import com.peluqueria.jwt.JwtTokenService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JwtBeansConfig {

    @Bean
    public JwtTokenService jwtTokenService(
            @Value("${app.jwt.secret-base64}") String secretBase64,
            @Value("${app.jwt.expiration-ms}") long expirationMs) {
        return new JwtTokenService(secretBase64, expirationMs);
    }
}
