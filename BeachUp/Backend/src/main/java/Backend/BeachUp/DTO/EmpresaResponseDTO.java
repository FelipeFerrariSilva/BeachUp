package Backend.BeachUp.DTO;


import Backend.BeachUp.Model.ENUMS.TipoPlano;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;

@Getter
@AllArgsConstructor
public class EmpresaResponseDTO {
    
    private Long id;
    private String cnpj;
    private TipoPlano planoAtual;
    private UsuarioDTO usuario;
}
