package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.ENUMS.StatusReserva;
import Backend.BeachUp.Model.QuadraModel;
import Backend.BeachUp.Model.ReservaModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ReservaRepository extends JpaRepository<ReservaModel, Long> {

    List<ReservaModel> findByJogadorId(Long jogadorId);
    List<ReservaModel> findByQuadraId(Long quadraId);
    Optional<ReservaModel> findByMpPaymentId(String mpPaymentId);

    @Query("""
        SELECT r FROM ReservaModel r
        WHERE r.quadra = :quadra
        AND r.status != 'CANCELADA'
        AND r.dataHoraInicio < :fim
        AND r.dataHoraFim > :inicio
        ORDER BY r.dataHoraInicio
    """)
    List<ReservaModel> findConflitos(
            @Param("quadra") QuadraModel quadra,
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim
    );
    // Busca reservas confirmadas e encerradas para as quais o email de avaliação ainda não foi enviado
    @Query("""
        SELECT r FROM ReservaModel r
        WHERE r.status = 'CONFIRMADA'
        AND r.dataHoraFim <= :agora
        AND r.emailAvaliacaoEnviado = false
    """)
    List<ReservaModel> findReservasEncerradasSemEmailAvaliacao(@Param("agora") LocalDateTime agora);


    //TOTAL DE RESERVAS
    @Query("""
        SELECT COALESCE(SUM(r.valorTotal), 0)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
    """)
    BigDecimal faturamentoTotal(@Param("empresaId") Long empresaId);

    //FATURAMENTO DAS RESERVAS CONFIRMADAS
    @Query("""
        SELECT COALESCE(SUM(r.valorTotal), 0)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
        AND YEAR(r.dataHoraInicio) = :ano
        AND MONTH(r.dataHoraInicio) = :mes
    """)
    BigDecimal faturamentoPorMes(
            @Param("empresaId") Long empresaId,
            @Param("ano") int ano,
            @Param("mes") int mes
    );

    //TOTAL DE RESERVAS POR STATUS DA EMPRESA
    @Query("""
        SELECT COUNT(r)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = :status
    """)
    long contarPorStatus(
            @Param("empresaId") Long empresaId,
            @Param("status") StatusReserva status
    );

    // TOTAL GERAL DE RESERVAS
    @Query("""
        SELECT COUNT(r)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
    """)
    long contarTotal(@Param("empresaId") Long empresaId);

    //TIKET MÉDIO POR RESERVA
    @Query("""
        SELECT COALESCE(AVG(r.valorTotal), 0)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
    """)
    BigDecimal ticketMedio(@Param("empresaId") Long empresaId);

    // RESERVAS CONFIRMADAS
    @Query("""
        SELECT COUNT(r)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
        AND r.dataHoraInicio >= :inicioDia
        AND r.dataHoraInicio < :fimDia
    """)
    long reservasHoje(
            @Param("empresaId") Long empresaId,
            @Param("inicioDia") LocalDateTime inicioDia,
            @Param("fimDia") LocalDateTime fimDia
    );

    //TOP 5 QUADRAS COM MAIS RESERVAS DA EMPRESA
    @Query("""
        SELECT r.quadra.nome, COUNT(r)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
        GROUP BY r.quadra.id, r.quadra.nome
        ORDER BY COUNT(r) DESC
    """)
    List<Object[]> topQuadrasMaisReservadas(@Param("empresaId") Long empresaId);

    //FATURAMENTO MENSAL/ ANUAL/ SEMANAL...
    @Query("""
        SELECT YEAR(r.dataHoraInicio), MONTH(r.dataHoraInicio), COALESCE(SUM(r.valorTotal), 0)
        FROM ReservaModel r
        WHERE r.quadra.arenas.empresa.id = :empresaId
        AND r.status = 'CONFIRMADA'
        AND r.dataHoraInicio >= :desde
        GROUP BY YEAR(r.dataHoraInicio), MONTH(r.dataHoraInicio)
        ORDER BY YEAR(r.dataHoraInicio), MONTH(r.dataHoraInicio)
    """)
    List<Object[]> faturamentoPorMesUltimos(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDateTime desde
    );
}