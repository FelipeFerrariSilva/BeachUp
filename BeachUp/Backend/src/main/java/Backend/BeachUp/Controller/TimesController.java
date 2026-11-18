package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.TimesCadastroDTO;
import Backend.BeachUp.DTO.TimesResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.TimesService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/times")
@AllArgsConstructor
public class TimesController {

    private final TimesService timesService;

    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping
    public ResponseEntity<TimesResponseDTO> criar(@RequestBody @Valid TimesCadastroDTO dto, Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(timesService.criar(dto, usuario));
    }

    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping("/{id}/convite/regenar")
    public ResponseEntity<String> regerarConvite(@PathVariable Long id, Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(timesService.gerarConvite(id, usuario));
    }


    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping("/entrar/{token}")  // Jogador acessa o link de convite e entra no time
    public ResponseEntity<TimesResponseDTO> aceitarConvite(@PathVariable String token, Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(timesService.aceitarConvite(token, usuario));
    }

    @GetMapping
    public ResponseEntity<List<TimesResponseDTO>> listarTodos() {
        return ResponseEntity.ok(timesService.listarTodos());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TimesResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(timesService.buscarPorId(id));
    }
}
