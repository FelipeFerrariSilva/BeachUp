package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.TipoCobertura;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class QuadraCadastroDTO {

    private String nome;
    private TipoCobertura tipoCobertura;

    @NotNull(message = "Valor por hora é obrigatório")
    @Positive(message = "Valor por hora deve ser positivo")
    private BigDecimal valorHora;
}
