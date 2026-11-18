package Backend.BeachUp.DTO;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter

public class JogadorCadastroDTO extends UsuarioCadastroDTO{
    private String cpf;
}
