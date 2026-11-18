package Backend.BeachUp.Controller;


import Backend.BeachUp.DTO.AutenticacaoDTO;
import Backend.BeachUp.DTO.LoginResponseDTO;
import Backend.BeachUp.Service.AuthService;
import Backend.BeachUp.Service.PasswordResetService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@AllArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDTO> login(@RequestBody @Valid AutenticacaoDTO data) {

        LoginResponseDTO response = authService.autenticar(data);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<LoginResponseDTO> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");
        if (refreshToken == null || refreshToken.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(authService.refresh(refreshToken));
    }

    @PostMapping("/esqueceu-senha")
    public ResponseEntity<Map<String, String>> esqueceuSenha(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("mensagem", "Email é obrigatório"));
        }
        passwordResetService.solicitarReset(email);
        return ResponseEntity.ok(Map.of("mensagem",
                "Se este email estiver cadastrado, você receberá as instruções em breve."));
    }

    @PostMapping("/redefinir-senha")
    public ResponseEntity<Map<String, String>> redefinirSenha(@RequestBody Map<String, String> body) {
        String token     = body.get("token");
        String novaSenha = body.get("novaSenha");

        if (token == null || token.isBlank() || novaSenha == null || novaSenha.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("mensagem", "Token e nova senha são obrigatórios"));
        }

        passwordResetService.redefinirSenha(token, novaSenha);
        return ResponseEntity.ok(Map.of("mensagem", "Senha redefinida com sucesso. Faça login com a nova senha."));
    }
}
