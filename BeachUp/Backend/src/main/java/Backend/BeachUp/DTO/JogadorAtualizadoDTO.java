package Backend.BeachUp.DTO;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class JogadorAtualizadoDTO {

    private Long id;
    private String cpf;
    private UsuarioDTO usuario;

    private String accessToken;

    private String refreshToken;
}
