package Backend.BeachUp.DTO;

import java.time.LocalDateTime;

public record AvaliacaoResponseDTO(
        Long id,
        Long reservaId,
        Long quadraId,
        String nomeQuadra,
        String nomeJogador,
        Integer nota,
        String comentario,
        LocalDateTime criadoEm
) {
}
