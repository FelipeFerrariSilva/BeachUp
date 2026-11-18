package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusPartida;

import java.time.LocalDateTime;

public record PartidaResponseDTO(
        Long id,
        String fase,
        Integer rodada,
        Long idTimeCasa,
        String nomeTimeCasa,
        Long idTimeVisitante,
        String nomeTimeVisitante,
        Integer placarTimeCasa,
        Integer placarTimeVisitante,
        Long idTimeVencedor,
        LocalDateTime dataHoraJogo,
        StatusPartida status
) {
}
