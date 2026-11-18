package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusInscricao;

import java.math.BigDecimal;

public record InscricaoResponseDTO(
        Long inscricaoId,
        Long campeonatoId,
        String nomeCampeonato,
        Long timeId,
        String nomeTime,
        StatusInscricao status,
        BigDecimal taxaInscricao,
        // Preenchidos quando há taxa pendente (Checkout Pro)
        String preferenceId,
        String checkoutUrl,
        String sandboxCheckoutUrl
) {
}
