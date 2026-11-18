package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusCampeonato;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CampeonatoResponseDTO(
        Long id,
        String nome,
        String descricao,
        String categoria,
        LocalDate dataInicio,
        LocalDate dataFim,
        StatusCampeonato status,
        String tokenInscricao,
        Long idEmpresa,
        Long idArena,
        Long idTimeVencedor,
        int totalInscritos,
        BigDecimal taxaInscricao
) {
}
