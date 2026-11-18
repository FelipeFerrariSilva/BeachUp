package Backend.BeachUp.DTO;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class ReservaCadastroDTO {

    @NotNull(message = "Quadra é obrigatória")
    private Long quadraId;

    @NotNull(message = "Data/hora é obrigatória")
    @Future(message = "A reserva só é permitida em horário futuro")
    private LocalDateTime dataHoraInicio;

    @NotNull(message = "Data/hora é obrigatória")
    @Future(message = "A reserva só é permitida em horário futuro")
    private LocalDateTime dataHoraFim;
}
