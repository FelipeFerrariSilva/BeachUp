package Backend.BeachUp.DTO;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LocalizacaoDTO {

    @NotNull(message = "Latitude é obrigatória")
    private Double latitude;

    @NotNull(message = "Longitude é obrigatória")
    private Double longitude;


    private Double raioKm = 10.0; // caso não informado o padrão de busca é de 10km

}
