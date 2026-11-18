package Backend.BeachUp.DTO;

import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.NonNull;
import lombok.Setter;

@Getter
@Setter
public class ResultadoPartidaDTO {
    @NonNull @Min(0)
    private Integer placarTimeCasa;

    @NonNull @Min(0)
    private Integer placarTimeVisitante;

}
