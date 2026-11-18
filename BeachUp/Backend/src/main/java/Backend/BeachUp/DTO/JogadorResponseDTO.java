package Backend.BeachUp.DTO;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class JogadorResponseDTO {
    Long id;
    private String cpf;
    private UsuarioDTO usuario;
}
