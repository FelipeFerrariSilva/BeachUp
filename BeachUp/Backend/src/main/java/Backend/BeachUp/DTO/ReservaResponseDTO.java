package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusReserva;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ReservaResponseDTO(
        Long id,
        Long quadraId,
        String nomeQuadra,
        String nomeArena,
        Long jogadorId,
        String nomeJogador,
        LocalDateTime dataHoraInicio,
        LocalDateTime dataHoraFim,
        BigDecimal valorTotal,
        StatusReserva status,
        List<String> fotosArena
) {
}
