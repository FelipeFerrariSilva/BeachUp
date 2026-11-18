package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.AvaliacaoCadastroDTO;
import Backend.BeachUp.DTO.AvaliacaoResponseDTO;
import Backend.BeachUp.DTO.QuadraAvaliacaoResumoDTO;
import Backend.BeachUp.Model.*;
import Backend.BeachUp.Model.ENUMS.StatusReserva;
import Backend.BeachUp.Repository.AvaliacaoQuadraRepository;
import Backend.BeachUp.Repository.JogadorRepository;
import Backend.BeachUp.Repository.QuadraRepository;
import Backend.BeachUp.Repository.ReservaRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AvaliacaoService {

    private final AvaliacaoQuadraRepository avaliacaoRepository;
    private final ReservaRepository reservaRepository;
    private final JogadorRepository jogadorRepository;
    private final QuadraRepository quadraRepository;

    @Transactional
    public AvaliacaoResponseDTO avaliar(AvaliacaoCadastroDTO dto, Usuario usuarioLogado) {
        JogadorModel jogador = jogadorRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        ReservaModel reserva = reservaRepository.findById(dto.reservaId())
                .orElseThrow(() -> new RuntimeException("Reserva não encontrada"));

        if (!reserva.getJogador().getId().equals(jogador.getId())) {
            throw new RuntimeException("Acesso negado: você não é o jogador desta reserva");
        }

        if (reserva.getStatus() != StatusReserva.CONFIRMADA) {
            throw new RuntimeException("Só é possível avaliar reservas confirmadas");
        }

        if (reserva.getDataHoraFim().isAfter(LocalDateTime.now())) {
            throw new RuntimeException("A reserva ainda não encerrou");
        }

        if (avaliacaoRepository.existsByReservaId(dto.reservaId())) {
            throw new RuntimeException("Você já avaliou esta reserva");
        }

        AvaliacaoQuadraModel avaliacao = AvaliacaoQuadraModel.builder()
                .nota(dto.nota())
                .comentario(dto.comentario())
                .reserva(reserva)
                .jogador(jogador)
                .quadra(reserva.getQuadra())
                .build();

        return toResponse(avaliacaoRepository.save(avaliacao));
    }

    public List<AvaliacaoResponseDTO> listarPorQuadra(Long quadraId) {
        quadraRepository.findById(quadraId)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));
        return avaliacaoRepository.findByQuadraId(quadraId)
                .stream().map(this::toResponse).toList();
    }

    //RESUMO DAS AVALIAÇÕES
    public QuadraAvaliacaoResumoDTO resumoPorQuadra(Long quadraId) {
        QuadraModel quadra = quadraRepository.findById(quadraId)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        Double media = avaliacaoRepository.calcularMediaPorQuadra(quadraId);
        Long total  = avaliacaoRepository.contarPorQuadra(quadraId);

        return new QuadraAvaliacaoResumoDTO(
                quadraId,
                quadra.getNome(),
                media != null ? Math.round(media * 10.0) / 10.0 : null,
                total
        );
    }

    private AvaliacaoResponseDTO toResponse(AvaliacaoQuadraModel a) {
        return new AvaliacaoResponseDTO(
                a.getId(),
                a.getReserva().getId(),
                a.getQuadra().getId(),
                a.getQuadra().getNome(),
                a.getJogador().getUsuario().getNome(),
                a.getNota(),
                a.getComentario(),
                a.getCriadoEm()
        );
    }
}
