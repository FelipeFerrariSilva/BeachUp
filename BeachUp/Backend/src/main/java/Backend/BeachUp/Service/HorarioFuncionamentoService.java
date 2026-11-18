package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.HorarioFuncionamentoDTO;
import Backend.BeachUp.DTO.HorarioFuncionamentoResponseDTO;
import Backend.BeachUp.Model.ArenaModel;
import Backend.BeachUp.Model.HorarioFuncionamentoModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.ArenaRepository;
import Backend.BeachUp.Repository.HorarioFuncionamentoRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class HorarioFuncionamentoService {

    private final HorarioFuncionamentoRepository horarioRepository;
    private final ArenaRepository arenaRepository;

    private static final Map<DayOfWeek, String> LABELS = Map.of(
            DayOfWeek.MONDAY,    "Segunda-feira",
            DayOfWeek.TUESDAY,   "Terça-feira",
            DayOfWeek.WEDNESDAY, "Quarta-feira",
            DayOfWeek.THURSDAY,  "Quinta-feira",
            DayOfWeek.FRIDAY,    "Sexta-feira",
            DayOfWeek.SATURDAY,  "Sábado",
            DayOfWeek.SUNDAY,    "Domingo"
    );

    @Transactional
    public HorarioFuncionamentoResponseDTO salvar(Long arenaId, HorarioFuncionamentoDTO dto, Usuario usuarioLogado) {
        ArenaModel arena = buscarArenaComPermissao(arenaId, usuarioLogado);

        if (dto.horaAbertura().isAfter(dto.horaFechamento()) ||
                dto.horaAbertura().equals(dto.horaFechamento())) {
            throw new RuntimeException("Hora de abertura deve ser anterior ao fechamento");
        }
        HorarioFuncionamentoModel horario = horarioRepository
                .findByArenaIdAndDiaSemana(arenaId, dto.diaSemana())
                .orElse(HorarioFuncionamentoModel.builder().arena(arena).diaSemana(dto.diaSemana()).build());

        horario.setHoraAbertura(dto.horaAbertura());
        horario.setHoraFechamento(dto.horaFechamento());

        return toResponse(horarioRepository.save(horario));
    }

    @Transactional
    public void remover(Long arenaId, DayOfWeek diaSemana, Usuario usuarioLogado) {
        buscarArenaComPermissao(arenaId, usuarioLogado);
        horarioRepository.deleteByArenaIdAndDiaSemana(arenaId, diaSemana);
    }

    public List<HorarioFuncionamentoResponseDTO> listar(Long arenaId) {
        arenaRepository.findById(arenaId)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada"));
        return horarioRepository.findByArenaId(arenaId)
                .stream().map(this::toResponse).toList();
    }

    private ArenaModel buscarArenaComPermissao(Long arenaId, Usuario usuarioLogado) {
        ArenaModel arena = arenaRepository.findById(arenaId)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada"));
        if (!arena.getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado: você não é o dono desta arena");
        }
        return arena;
    }

    private HorarioFuncionamentoResponseDTO toResponse(HorarioFuncionamentoModel h) {
        return new HorarioFuncionamentoResponseDTO(
                h.getId(),
                h.getDiaSemana(),
                LABELS.getOrDefault(h.getDiaSemana(), h.getDiaSemana().name()),
                h.getHoraAbertura(),
                h.getHoraFechamento()
        );
    }

}
