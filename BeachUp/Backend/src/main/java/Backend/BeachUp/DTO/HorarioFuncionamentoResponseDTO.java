package Backend.BeachUp.DTO;

import java.time.DayOfWeek;
import java.time.LocalTime;

public record HorarioFuncionamentoResponseDTO(
        Long id,
        DayOfWeek diaSemana,
        String diaSemanaLabel,
        LocalTime horaAbertura,
        LocalTime horaFechamento
) {
}
