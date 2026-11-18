package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.TipoPlano;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class EmpresaAtualizadaDTO {

    private Long id;
    private String cnpj;
    private TipoPlano planoAtual;
    private UsuarioDTO usuario;

    private String accessToken;

    private String refreshToken;
}
