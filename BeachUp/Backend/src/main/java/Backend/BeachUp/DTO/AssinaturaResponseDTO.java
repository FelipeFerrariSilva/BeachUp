package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusAssinatura;
import Backend.BeachUp.Model.ENUMS.TipoPlano;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AssinaturaResponseDTO(
        Long id,
        TipoPlano tipoPlano,
        String nomePlano,
        Integer limiteQuadras,
        BigDecimal valorMensal,
        double taxaReserva,
        LocalDateTime dataInicio,
        LocalDateTime dataFim,
        StatusAssinatura status,
        boolean premiumAtivo,
        boolean podeCriarCampeonato
) {
}
