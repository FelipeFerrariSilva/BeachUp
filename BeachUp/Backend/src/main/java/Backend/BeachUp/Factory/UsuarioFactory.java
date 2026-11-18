package Backend.BeachUp.Factory;

import Backend.BeachUp.Model.ENUMS.Role;
import Backend.BeachUp.Model.Usuario;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class UsuarioFactory {

    private final BCryptPasswordEncoder passwordEncoder;

    public UsuarioFactory(BCryptPasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    public Usuario criarUsuario(String nome, String email, String senha, Role role) {
        if (nome == null || nome.isBlank()) {
            throw new IllegalArgumentException("Nome não pode ser vazio");
        }

        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email não pode ser vazio");
        }

        if (senha == null || senha.isBlank()) {
            throw new IllegalArgumentException("Senha não pode ser vazia");
        }

        if (role == null) {
            throw new IllegalArgumentException("Role não pode ser nula");
        }

        Usuario usuario = new Usuario();

        usuario.setNome(nome.trim());
        usuario.setEmail(email.trim().toLowerCase());
        usuario.setSenha(passwordEncoder.encode(senha));
        usuario.setRole(role);

        return usuario;
    }
}