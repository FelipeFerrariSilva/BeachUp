package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.*;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.CampeonatoService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/campeonatos")
@AllArgsConstructor
public class CampeonatoController {

    private final CampeonatoService campeonatoService;

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping
    public ResponseEntity<CampeonatoResponseDTO> criar(@RequestBody @Valid CampeonatoCadastroDTO dto, Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(campeonatoService.criar(dto, usuario));
    }


    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping("/inscrever/{token}/time/{timeId}")
    public ResponseEntity<InscricaoResponseDTO> inscreverTime(@PathVariable String token, @PathVariable Long timeId, Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(campeonatoService.inscreverTime(token, timeId, usuario));
    }


    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/{id}/iniciar")
    public ResponseEntity<List<PartidaResponseDTO>> iniciar(@PathVariable Long id, Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(campeonatoService.iniciarCampeonato(id, usuario));
    }


    @PreAuthorize("hasRole('EMPRESA')") // REGISTRAR RESULTADO DE UMA PARTIDA
    @PutMapping("/partidas/{partidaId}/resultado")
    public ResponseEntity<PartidaResponseDTO> registrarResultado(
            @PathVariable Long partidaId,
            @RequestBody @Valid ResultadoPartidaDTO dto,
            Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(campeonatoService.registrarResultado(partidaId, dto, usuario));
    }

    @GetMapping
    public ResponseEntity<List<CampeonatoResponseDTO>> listarTodos() {
        return ResponseEntity.ok(campeonatoService.listarTodos());
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @GetMapping("/meus")
    public ResponseEntity<List<CampeonatoResponseDTO>> listarMeus(Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(campeonatoService.listarPorEmpresa(usuario));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CampeonatoResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(campeonatoService.buscarPorId(id));
    }

    @GetMapping("/{id}/partidas")
    public ResponseEntity<List<PartidaResponseDTO>> listarPartidas(@PathVariable Long id) {
        return ResponseEntity.ok(campeonatoService.listarPartidas(id));
    }
}
