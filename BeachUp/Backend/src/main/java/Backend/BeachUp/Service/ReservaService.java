package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.ReservaCadastroDTO;
import Backend.BeachUp.DTO.ReservaResponseDTO;
import Backend.BeachUp.Model.*;
import Backend.BeachUp.Model.ENUMS.StatusReserva;
import Backend.BeachUp.Repository.*;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@AllArgsConstructor
public class ReservaService {

    private final ReservaRepository reservaRepository;
    private final QuadraRepository quadraRepository;
    private final JogadorRepository jogadorRepository;
    private final EmpresaRepository empresaRepository;
    private final HorarioFuncionamentoRepository horarioRepository;

    private static final DateTimeFormatter FMT_HORA = DateTimeFormatter.ofPattern("HH:mm");

    @Transactional
    public ReservaResponseDTO criar(ReservaCadastroDTO dto, Usuario usuarioLogado) {
        JogadorModel jogador = jogadorRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        QuadraModel quadra = quadraRepository.findById(dto.getQuadraId())
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        if (!dto.getDataHoraInicio().isBefore(dto.getDataHoraFim())) {
            throw new RuntimeException("O início da reserva deve ser antes do fim");
        }

        long minutos = Duration.between(dto.getDataHoraInicio(), dto.getDataHoraFim()).toMinutes();

        if (minutos < 60) {
            throw new RuntimeException("A reserva mínima é de uma hora");
        }

        // Validação 1: horário de funcionamento da arena
        validarHorarioFuncionamento(quadra, dto.getDataHoraInicio(), dto.getDataHoraFim());

        // Validação 2: conflito com outra reserva — mensagem detalhada
        validarConflito(quadra, dto.getDataHoraInicio(), dto.getDataHoraFim());

        BigDecimal horas = BigDecimal.valueOf(minutos).divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP);
        BigDecimal valorTotal = quadra.getValorHora().multiply(horas).setScale(2, RoundingMode.HALF_UP);

        ReservaModel reserva = ReservaModel.builder()
                .jogador(jogador)
                .quadra(quadra)
                .dataHoraInicio(dto.getDataHoraInicio())
                .dataHoraFim(dto.getDataHoraFim())
                .valorTotal(valorTotal)
                .status(StatusReserva.PENDENTE)
                .build();

        return toResponse(reservaRepository.save(reserva));
    }

    @Transactional
    public ReservaResponseDTO confirmar(Long reservaId, Usuario usuarioLogado) {
        ReservaModel reserva = buscarReserva(reservaId);
        validarDonoQuadra(reserva.getQuadra(), usuarioLogado);

        if (reserva.getStatus() != StatusReserva.PENDENTE) {
            throw new RuntimeException("Apenas reservas PENDENTES podem ser confirmadas");
        }
        if (!"approved".equals(reserva.getMpPaymentStatus())) {
            throw new RuntimeException("Reserva ainda não foi paga. Aguarde a confirmação do pagamento.");
        }

        reserva.setStatus(StatusReserva.CONFIRMADA);
        return toResponse(reservaRepository.save(reserva));
    }

    @Transactional
    public ReservaResponseDTO cancelar(Long reservaId, Usuario usuarioLogado) {
        ReservaModel reserva = buscarReserva(reservaId);

        if (reserva.getStatus() == StatusReserva.CANCELADA) {
            throw new RuntimeException("Reserva já está cancelada");
        }

        boolean jogadorDono = reserva.getJogador().getUsuario().getId().equals(usuarioLogado.getId());
        boolean empresaDona = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .map(e -> e.getId().equals(reserva.getQuadra().getArenas().getEmpresa().getId())).orElse(false);

        if (!jogadorDono && !empresaDona) {
            throw new RuntimeException("Acesso negado: você não tem permissão para cancelar esta reserva");
        }

        LocalDateTime limiteParaCancelamento = reserva.getDataHoraInicio().minusHours(24);
        if (LocalDateTime.now().isAfter(limiteParaCancelamento)) {
            throw new RuntimeException("Cancelamento permitido apenas com 24h de antecedência");
        }

        reserva.setStatus(StatusReserva.CANCELADA);
        return toResponse(reservaRepository.save(reserva));
    }

    public List<ReservaResponseDTO> listarMinhasReservas(Usuario usuarioLogado) {
        JogadorModel jogador = jogadorRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));
        return reservaRepository.findByJogadorId(jogador.getId()).stream().map(this::toResponse).toList();
    }

    public List<ReservaResponseDTO> listarPorQuadra(Long quadraId, Usuario usuarioLogado) {
        QuadraModel quadra = quadraRepository.findById(quadraId)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));
        validarDonoQuadra(quadra, usuarioLogado);
        return reservaRepository.findByQuadraId(quadraId).stream().map(this::toResponse).toList();
    }

    public ReservaResponseDTO buscarPorId(Long id) {
        return toResponse(buscarReserva(id));
    }

    private void validarHorarioFuncionamento(QuadraModel quadra,
                                             LocalDateTime inicio, LocalDateTime fim) {
        Long arenaId = quadra.getArenas().getId();

        // Reserva que cruza meia-noite não é suportada
        if (!inicio.toLocalDate().equals(fim.toLocalDate())) {
            throw new RuntimeException(
                    "Reservas que ultrapassam a meia-noite não são permitidas. " +
                            "Divida em duas reservas separadas."
            );
        }

        HorarioFuncionamentoModel horario = horarioRepository
                .findByArenaIdAndDiaSemana(arenaId, inicio.getDayOfWeek())
                .orElseThrow(() -> new RuntimeException(
                        "A arena não funciona neste dia da semana. " +
                                "Consulte os horários disponíveis em /arenas/" + arenaId + "/horarios"
                ));

        LocalTime horaInicio  = inicio.toLocalTime();
        LocalTime horaFim     = fim.toLocalTime();
        LocalTime abertura    = horario.getHoraAbertura();
        LocalTime fechamento  = horario.getHoraFechamento();

        if (horaInicio.isBefore(abertura) || horaFim.isAfter(fechamento)) {
            throw new RuntimeException(String.format(
                    "Horário fora do funcionamento da arena. " +
                            "Neste dia a arena funciona das %s às %s.",
                    abertura.format(FMT_HORA), fechamento.format(FMT_HORA)
            ));
        }
    }

    private void validarConflito(QuadraModel quadra, LocalDateTime inicio, LocalDateTime fim) {
        List<ReservaModel> conflitos = reservaRepository
                .findConflitos(quadra, inicio, fim);

        if (!conflitos.isEmpty()) {
            ReservaModel c = conflitos.get(0);
            throw new RuntimeException(String.format(
                    "A quadra \"%s\" já está reservada das %s às %s neste horário. " +
                            "Escolha outro horário disponível.",
                    quadra.getNome(),
                    c.getDataHoraInicio().format(DateTimeFormatter.ofPattern("dd/MM HH:mm")),
                    c.getDataHoraFim().format(DateTimeFormatter.ofPattern("HH:mm"))
            ));
        }
    }

    private ReservaModel buscarReserva(Long id) {
        return reservaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Reserva não encontrada"));
    }

    private void validarDonoQuadra(QuadraModel quadra, Usuario usuarioLogado) {
        if (!quadra.getArenas().getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado: você não é o dono desta quadra");
        }
    }

    private ReservaResponseDTO toResponse(ReservaModel r) {
        List<String> fotos = r.getQuadra().getFotos() == null ? List.of()
                : r.getQuadra().getFotos().stream().map(FotoModel::getUrl).toList();

        return new ReservaResponseDTO(
                r.getId(),
                r.getQuadra().getId(),
                r.getQuadra().getNome(),
                r.getQuadra().getArenas().getNome(),
                r.getJogador().getId(),
                r.getJogador().getUsuario().getNome(),
                r.getDataHoraInicio(),
                r.getDataHoraFim(),
                r.getValorTotal(),
                r.getStatus(),
                fotos
        );
    }

}
