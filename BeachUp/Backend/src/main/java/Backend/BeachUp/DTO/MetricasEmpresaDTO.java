package Backend.BeachUp.DTO;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class MetricasEmpresaDTO {

    private BigDecimal faturamentoTotal;

    private BigDecimal faturamentoMesAtual;

    private BigDecimal ticketMedio;

    private long totalReservas;

    private long reservasConfirmadas;

    private long reservasPendentes;

    private long reservasCanceladas;

    private long reservasHoje;

    private long totalArenas;

    private long totalQuadras;

    private List<QuadraRankingDTO> topQuadras;

    private List<FaturamentoMensalDTO> faturamentoUltimos6Meses;

    @Data
    @Builder
    public static class QuadraRankingDTO {
        private String nomeQuadra;
        private long totalReservas;
    }

    @Data
    @Builder
    public static class FaturamentoMensalDTO {
        private int ano;
        private int mes;
        private String mesNome;
        private BigDecimal total;
    }
}
