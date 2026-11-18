package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.HorarioFuncionamentoDTO;
import Backend.BeachUp.DTO.HorarioFuncionamentoResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.HorarioFuncionamentoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.util.List;

@RestController
@RequestMapping("/arenas/{arenaId}/horarios")
@RequiredArgsConstructor
public class HorarioFuncionamentoController {

    private final HorarioFuncionamentoService horarioService;

    @GetMapping
    public ResponseEntity<List<HorarioFuncionamentoResponseDTO>> listar(@PathVariable Long arenaId) {
        return ResponseEntity.ok(horarioService.listar(arenaId));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping
    public ResponseEntity<HorarioFuncionamentoResponseDTO> salvar(
            @PathVariable Long arenaId,
            @RequestBody @Valid HorarioFuncionamentoDTO dto,
            @AuthenticationPrincipal Usuario usuarioLogado) {

        return ResponseEntity.ok(horarioService.salvar(arenaId, dto, usuarioLogado));
    }


    @PreAuthorize("hasRole('EMPRESA')")
    @DeleteMapping("/{diaSemana}")
    public ResponseEntity<Void> remover(
            @PathVariable Long arenaId,
            @PathVariable DayOfWeek diaSemana,
            @AuthenticationPrincipal Usuario usuarioLogado) {

        horarioService.remover(arenaId, diaSemana, usuarioLogado);
        return ResponseEntity.noContent().build();
    }
}
