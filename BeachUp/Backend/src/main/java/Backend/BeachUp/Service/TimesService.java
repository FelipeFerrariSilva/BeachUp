package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.TimesCadastroDTO;
import Backend.BeachUp.DTO.TimesResponseDTO;
import Backend.BeachUp.Model.ENUMS.StatusMembroTime;
import Backend.BeachUp.Model.JogadorModel;
import Backend.BeachUp.Model.MembroTimeModel;
import Backend.BeachUp.Model.TimesModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.JogadorRepository;
import Backend.BeachUp.Repository.MembroTimeRepository;
import Backend.BeachUp.Repository.TimesRepository;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@AllArgsConstructor
public class TimesService {

    private final TimesRepository timesRepository;
    private final MembroTimeRepository membroTimeRepository;
    private final JogadorRepository jogadorRepository;

    @Transactional
    public TimesResponseDTO criar(TimesCadastroDTO dto, Usuario usuarioLogado) {

        JogadorModel jogador = buscarJogadorPorUsuario(usuarioLogado);

        TimesModel time = TimesModel.builder()
                .nome(dto.getNome())
                .descricao(dto.getDescricao())
                .jogador(jogador)
                .urlConvite(UUID.randomUUID().toString())
                .build();

        TimesModel salvo = timesRepository.save(time);

        // Dono já entra como membro ACEITO automaticamente
        MembroTimeModel membroDono = MembroTimeModel.builder()
                .time(salvo)
                .jogador(jogador)
                .status(StatusMembroTime.ACEITO)
                .build();
        membroTimeRepository.save(membroDono);

        return toResponse(salvo);
    }

    @Transactional
    public String gerarConvite(Long timeId, Usuario usuarioLogado) {
        TimesModel time = buscarTime(timeId);
        validarDono(time, usuarioLogado);
        time.setUrlConvite(UUID.randomUUID().toString());
        timesRepository.save(time);
        return time.getUrlConvite();
    }

    @Transactional
    public TimesResponseDTO aceitarConvite(String token, Usuario usuarioLogado) {

        TimesModel time = timesRepository.findByUrlConvite(token)
                .orElseThrow(() -> new RuntimeException("Convite inválido ou expirado"));

        JogadorModel jogador = buscarJogadorPorUsuario(usuarioLogado);

        // Verifica se já é membro
        membroTimeRepository.findByTimeAndJogador(time, jogador).ifPresent(m -> {
            throw new RuntimeException("Você já faz parte deste time");
        });

        // Valida limite de dupla (2 membros aceitos)
        int membrosAceitos = membroTimeRepository.countByTimeAndStatus(time, StatusMembroTime.ACEITO);
        if (membrosAceitos >= 2) {
            throw new RuntimeException("O time já está completo (máximo 2 jogadores)");
        }

        MembroTimeModel membro = MembroTimeModel.builder()
                .time(time)
                .jogador(jogador)
                .status(StatusMembroTime.ACEITO)
                .build();
        membroTimeRepository.save(membro);

        // Invalida o token após o parceiro entrar
        time.setUrlConvite(null);
        timesRepository.save(time);

        return toResponse(time);
    }

    public TimesResponseDTO buscarPorId(Long id) {
        return toResponse(buscarTime(id));
    }

    public List<TimesResponseDTO> listarTodos() {
        return timesRepository.findAll().stream().map(this::toResponse).toList();
    }

    // ---- helpers ----

    private TimesModel buscarTime(Long id) {
        return timesRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Time não encontrado"));
    }

    private void validarDono(TimesModel time, Usuario usuarioLogado) {
        if (!time.getJogador().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado: você não é o dono deste time");
        }
    }

    private JogadorModel buscarJogadorPorUsuario(Usuario usuario) {
        return jogadorRepository.findByUsuarioId(usuario.getId())
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado para este usuário"));
    }

    private TimesResponseDTO toResponse(TimesModel time) {
        List<TimesResponseDTO.MembroResponseDTO> membros = membroTimeRepository.findByTime(time)
                .stream()
                .map(m -> new TimesResponseDTO.MembroResponseDTO(
                        m.getJogador().getId(),
                        m.getJogador().getUsuario().getNome(),
                        m.getStatus()))
                .toList();

        return new TimesResponseDTO(
                time.getId(),
                time.getNome(),
                time.getDescricao(),
                time.getUrlConvite(),
                time.getJogador().getId(),
                membros
        );
    }
}
