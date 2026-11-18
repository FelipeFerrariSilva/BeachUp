package Backend.BeachUp.DTO;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UsuarioDTO {
    private String nome;
    private String email;
    private String role;
    private String fotoUrl;
}
