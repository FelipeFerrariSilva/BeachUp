package Backend.BeachUp.DTO;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TimesCadastroDTO {

    @NotBlank(message = "Nome é obrigatório")
    @Size(max = 50)
    private String nome;

    @Size(max = 50)
    private String descricao;
}
