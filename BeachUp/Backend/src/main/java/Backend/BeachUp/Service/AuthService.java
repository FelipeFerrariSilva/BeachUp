package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.AutenticacaoDTO;
import Backend.BeachUp.DTO.LoginResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.UsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@AllArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final TokenService tokenService;
    private final UsuarioRepository usuarioRepository;

    @Transactional // garante que caso haja falhas, nada será salvo no banco
    public LoginResponseDTO autenticar(AutenticacaoDTO data) {

        var usernamePassword = new UsernamePasswordAuthenticationToken(data.email(), data.senha());
        Authentication auth = this.authenticationManager.authenticate(usernamePassword);

        Usuario user = usuarioRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        String sessionId = UUID.randomUUID().toString();
        user.setCurrentSessionId(sessionId);

        String accessToken  = tokenService.generateToken(user, sessionId);
        String refreshToken = tokenService.generateRefreshToken(user);

        user.setRefreshToken(refreshToken); // salva no banco
        usuarioRepository.save(user);

        return new LoginResponseDTO(accessToken, refreshToken);
    }

    @Transactional
    public LoginResponseDTO refresh(String refreshToken) {

        String email = tokenService.validateRefreshToken(refreshToken);
        if (email == null) throw new RuntimeException("Refresh token inválido ou expirado");

        Usuario user = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        // Garantia que o refresh Token bate com o valor salvo no banco (evita reuso)
        if (!refreshToken.equals(user.getRefreshToken())) {
            throw new RuntimeException("Refresh token não reconhecido");
        }

        String sessionId = UUID.randomUUID().toString();
        user.setCurrentSessionId(sessionId);

        String newAccessToken  = tokenService.generateToken(user, sessionId);
        String newRefreshToken = tokenService.generateRefreshToken(user); // rotaciona os tokens
        user.setRefreshToken(newRefreshToken);
        usuarioRepository.save(user);

        return new LoginResponseDTO(newAccessToken, newRefreshToken);
    }
}
