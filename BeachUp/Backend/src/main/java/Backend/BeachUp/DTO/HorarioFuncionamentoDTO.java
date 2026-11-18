package Backend.BeachUp.DTO;

import jakarta.validation.constraints.NotNull;

import java.time.DayOfWeek;
import java.time.LocalTime;

public record HorarioFuncionamentoDTO(
        @NotNull(message = "Dia da semana é obrigatório")
        DayOfWeek diaSemana,

        @NotNull(message = "Hora de abertura é obrigatória")
        LocalTime horaAbertura,

        @NotNull(message = "Hora de fechamento é obrigatória")
        LocalTime horaFechamento
) {
}
