package com.peluqueria.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.util.Date;

public class JwtTokenService {

    private final SecretKey key;
    private final long expirationMs;

    public JwtTokenService(String base64Secret, long expirationMs) {
        byte[] bytes = Decoders.BASE64.decode(base64Secret);
        this.key = Keys.hmacShaKeyFor(bytes);
        this.expirationMs = expirationMs;
    }

    public String generate(Long userId, String email, String role) {
        Date now = new Date();
        Date exp = new Date(now.getTime() + expirationMs);
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim(JwtClaims.USER_ID, userId)
                .claim(JwtClaims.EMAIL, email)
                .claim(JwtClaims.ROLE, role)
                .issuedAt(now)
                .expiration(exp)
                .signWith(key)
                .compact();
    }

    public JwtPrincipal parse(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        Long userId = claims.get(JwtClaims.USER_ID, Long.class);
        if (userId == null && claims.getSubject() != null) {
            userId = Long.parseLong(claims.getSubject());
        }
        String email = claims.get(JwtClaims.EMAIL, String.class);
        String role = claims.get(JwtClaims.ROLE, String.class);
        return new JwtPrincipal(userId, email, role);
    }
}
