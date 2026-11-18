package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.ReservaCadastroDTO;
import Backend.BeachUp.DTO.ReservaResponseDTO;
import Backend.BeachUp.Model.ReservaModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.ReservaService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reservas")
@AllArgsConstructor
public class ReservaController {
    private final ReservaService reservaService;

    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping
    public ResponseEntity<ReservaResponseDTO> criar(@RequestBody @Valid ReservaCadastroDTO dto, Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(reservaService.criar(dto, usuario));
    }


    @PreAuthorize("hasRole('EMPRESA')")  // Empresa confirma a reserva
    @PatchMapping("/{id}/confirmar")
    public ResponseEntity<ReservaResponseDTO> confirmar(@PathVariable Long id, Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(reservaService.confirmar(id, usuario));
    }


    @PatchMapping("/{id}/cancelar") // Jogador ou Empresa cancela (com 24h de antecedência)
    public ResponseEntity<ReservaResponseDTO> cancelar(
            @PathVariable Long id,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(reservaService.cancelar(id, usuario));
    }


    @PreAuthorize("hasRole('JOGADOR')")  // Jogador vê suas próprias reservas
    @GetMapping("/minhas")
    public ResponseEntity<List<ReservaResponseDTO>> minhasReservas(Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(reservaService.listarMinhasReservas(usuario));
    }


    @PreAuthorize("hasRole('EMPRESA')")  // Empresa vê reservas de uma quadra cadastrada
    @GetMapping("/quadra/{quadraId}")
    public ResponseEntity<List<ReservaResponseDTO>> porQuadra(
            @PathVariable Long quadraId,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(reservaService.listarPorQuadra(quadraId, usuario));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReservaResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(reservaService.buscarPorId(id));
    }

}
