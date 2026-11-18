package Backend.BeachUp.DTO;
import Backend.BeachUp.Model.ENUMS.TipoCobertura;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@AllArgsConstructor
public class QuadraResponseDTO {

    private Long id;
    private String nome;
    private TipoCobertura tipoCobertura;
    private BigDecimal valorHora;
    private List<String> fotos;
}
