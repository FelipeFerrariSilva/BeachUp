package Backend.BeachUp.Service;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTCreationException;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

@Service
public class TokenService {

    @Value("${api.security.token.secret}")
    private String secret;

    @Value("${api.security.token.issuer:auth-api}")
    private String issuer;

    private Algorithm algorithm;


    @PostConstruct // Inicializa o algoritmo uma única vez após injetar o 'secret'
    protected void init() {
        this.algorithm = Algorithm.HMAC256(secret);
    }

    public String generateToken(UserDetails user, String sessionId) {
        try {

            String role = user.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .findFirst()
                    .orElse("");

            return JWT.create()
                    .withIssuer(issuer)
                    .withSubject(user.getUsername())
                    .withClaim("role", role)
                    .withClaim("sessionId", sessionId)
                    .withIssuedAt(Instant.now())
                    .withExpiresAt(genExpirationDate())
                    .sign(algorithm);

        } catch (JWTCreationException exception) {
            throw new RuntimeException("Erro ao gerar token", exception);
        }
    }

    public String generateRefreshToken(UserDetails user) {
        try {
            return JWT.create()
                    .withIssuer(issuer)
                    .withSubject(user.getUsername())
                    .withIssuedAt(Instant.now())
                    .withExpiresAt(Instant.now().plus(Duration.ofDays(7)))
                    .sign(algorithm);
        } catch (JWTCreationException exception) {
            throw new RuntimeException("Erro ao gerar refresh token", exception);
        }
    }

    public String validateRefreshToken(String token) {
        DecodedJWT decodedJWT = decodeToken(token);
        return decodedJWT != null ? decodedJWT.getSubject() : null;
    }

    public String validateToken(String token) {
        DecodedJWT decodedJWT = decodeToken(token);
        return decodedJWT != null ? decodedJWT.getSubject() : null;
    }

    public String getSessionId(String token) {
        DecodedJWT decodedJWT = decodeToken(token);
        return decodedJWT != null ? decodedJWT.getClaim("sessionId").asString() : null;
    }

    // Método para evitar repetição de código (DRY)
    private DecodedJWT decodeToken(String token) {
        try {
            return JWT.require(algorithm)
                    .withIssuer(issuer)
                    .build()
                    .verify(token);
        } catch (JWTVerificationException exception) {
            return null;
        }
    }

    private Instant genExpirationDate() {
        return Instant.now().plus(Duration.ofHours(1));
    }
}