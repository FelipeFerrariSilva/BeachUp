package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.MetricasEmpresaDTO;
import Backend.BeachUp.Model.ENUMS.StatusReserva;
import Backend.BeachUp.Model.Empresa;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.ArenaRepository;
import Backend.BeachUp.Repository.EmpresaRepository;
import Backend.BeachUp.Repository.QuadraRepository;
import Backend.BeachUp.Repository.ReservaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Month;
import java.time.format.TextStyle;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MetricasService {

    private final ReservaRepository reservaRepository;
    private final ArenaRepository arenaRepository;
    private final QuadraRepository quadraRepository;
    private final EmpresaRepository empresaRepository;

    public MetricasEmpresaDTO obterMetricas(Usuario usuario) {
        Empresa empresa = empresaRepository.findByUsuarioId(usuario.getId())
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));

        Long empresaId = empresa.getId();
        LocalDate hoje = LocalDate.now();

        BigDecimal faturamentoTotal = reservaRepository.faturamentoTotal(empresaId);
        BigDecimal faturamentoMes   = reservaRepository.faturamentoPorMes(
                empresaId, hoje.getYear(), hoje.getMonthValue());
        BigDecimal ticketMedio      = reservaRepository.ticketMedio(empresaId);

        long totalReservas = reservaRepository.contarTotal(empresaId);
        long confirmadas = reservaRepository.contarPorStatus(empresaId, StatusReserva.CONFIRMADA);
        long pendentes   = reservaRepository.contarPorStatus(empresaId, StatusReserva.PENDENTE);
        long canceladas  = reservaRepository.contarPorStatus(empresaId, StatusReserva.CANCELADA);
        long reservasHoje= reservaRepository.reservasHoje(
                empresaId,
                hoje.atStartOfDay(),
                hoje.plusDays(1).atStartOfDay()
        );

        long totalArenas  = arenaRepository.findByEmpresaId(empresaId).size();
        long totalQuadras = quadraRepository.countByEmpresaId(empresaId);

        List<MetricasEmpresaDTO.QuadraRankingDTO> topQuadras = reservaRepository
                .topQuadrasMaisReservadas(empresaId)
                .stream()
                .limit(5)
                .map(row -> MetricasEmpresaDTO.QuadraRankingDTO.builder()
                        .nomeQuadra((String) row[0])
                        .totalReservas((Long) row[1])
                        .build())
                .toList();

        LocalDateTime desde = hoje.minusMonths(5).withDayOfMonth(1).atStartOfDay();
        List<MetricasEmpresaDTO.FaturamentoMensalDTO> faturamentoMensal = reservaRepository
                .faturamentoPorMesUltimos(empresaId, desde)
                .stream()
                .map(row -> {
                    int ano = (Integer) row[0];
                    int mes = (Integer) row[1];
                    BigDecimal total = (BigDecimal) row[2];
                    String nomeMes = Month.of(mes)
                            .getDisplayName(TextStyle.SHORT, new Locale("pt", "BR"));
                    return MetricasEmpresaDTO.FaturamentoMensalDTO.builder()
                            .ano(ano)
                            .mes(mes)
                            .mesNome(nomeMes)
                            .total(total)
                            .build();
                })
                .toList();

        return MetricasEmpresaDTO.builder()
                .faturamentoTotal(faturamentoTotal)
                .faturamentoMesAtual(faturamentoMes)
                .ticketMedio(ticketMedio)
                .totalReservas(totalReservas)
                .reservasConfirmadas(confirmadas)
                .reservasPendentes(pendentes)
                .reservasCanceladas(canceladas)
                .reservasHoje(reservasHoje)
                .totalArenas(totalArenas)
                .totalQuadras(totalQuadras)
                .topQuadras(topQuadras)
                .faturamentoUltimos6Meses(faturamentoMensal)
                .build();
    }
}