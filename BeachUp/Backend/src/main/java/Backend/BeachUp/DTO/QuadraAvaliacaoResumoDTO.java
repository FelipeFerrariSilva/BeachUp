package Backend.BeachUp.DTO;

public record QuadraAvaliacaoResumoDTO(
        Long quadraId,
        String nomeQuadra,
        Double mediaNotas,
        Long totalAvaliacoes
) {
}
