package Backend.BeachUp.DTO;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter

public class EmpresaCadastroDTO extends  UsuarioCadastroDTO{
    private String cnpj;
}
