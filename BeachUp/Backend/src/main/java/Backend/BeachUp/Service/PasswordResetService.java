package Backend.BeachUp.Service;

import Backend.BeachUp.Model.PasswordResetTokenModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.PasswordResetTokenRepository;
import Backend.BeachUp.Repository.UsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    private static final int EXPIRACAO_MINUTOS = 30;

    @Transactional
    public void solicitarReset(String email) {
        usuarioRepository.findByEmail(email).ifPresent(usuario -> {
            // Remove tokens anteriores do mesmo usuário
            tokenRepository.deleteByUsuarioId(usuario.getId());

            String token = UUID.randomUUID().toString().replace("-", "");

            PasswordResetTokenModel resetToken = PasswordResetTokenModel.builder()
                    .token(token)
                    .usuario(usuario)
                    .expiraEm(LocalDateTime.now().plusMinutes(EXPIRACAO_MINUTOS))
                    .build();

            tokenRepository.save(resetToken);
            emailService.enviarEmailResetSenha(usuario, token);

            log.info("Token de reset enviado para email: {}", email);
        });
    }

    @Transactional
    public void redefinirSenha(String token, String novaSenha) {
        PasswordResetTokenModel resetToken = tokenRepository.findByToken(token)
                .orElseThrow(() -> new RuntimeException("Token inválido ou não encontrado"));

        if (!resetToken.isValido()) {
            throw new RuntimeException("Este link de redefinição expirou ou já foi utilizado. " +
                    "Solicite um novo link em /auth/esqueceu-senha");
        }

        if (novaSenha == null || novaSenha.length() < 6) {
            throw new RuntimeException("A nova senha deve ter no mínimo 6 caracteres");
        }

        Usuario usuario = resetToken.getUsuario();
        usuario.setSenha(passwordEncoder.encode(novaSenha));
        usuarioRepository.save(usuario);

        // Invalida o token após o uso
        resetToken.setUsado(true);
        tokenRepository.save(resetToken);

        log.info("Senha redefinida com sucesso para usuário id={}", usuario.getId());
    }

    @Transactional
    public void limparTokensExpirados() {
        tokenRepository.deleteExpirados(LocalDateTime.now());
    }
}
