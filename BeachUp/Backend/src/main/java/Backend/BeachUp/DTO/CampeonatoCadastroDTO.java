package Backend.BeachUp.DTO;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
public class CampeonatoCadastroDTO {

    @NotBlank(message = "Nome é obrigatório")
    @Size(max = 50)
    private String nome;

    @Size(max = 60)
    private String descricao;

    @Size(max = 20)
    private String categoria;

    @NotNull(message = "Data de início é obrigatória")
    private LocalDate dataInicio;

    private LocalDate dataFim;

    @NotNull(message = "Arena é obrigatória")
    private Long arenaId;

    @DecimalMin(value = "0.00", message = "Taxa de inscrição não pode ser negativa")
    private BigDecimal taxaInscricao;
}
