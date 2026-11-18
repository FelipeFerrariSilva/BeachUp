package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.QuadraCadastroDTO;
import Backend.BeachUp.DTO.QuadraResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.QuadraService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/quadras")
public class QuadraController {

    @Autowired
    private QuadraService quadraService;

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/{arenaId}")
    public ResponseEntity<QuadraResponseDTO> create(
            @PathVariable Long arenaId,
            @RequestBody QuadraCadastroDTO dto,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(quadraService.create(arenaId, dto, usuario));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/{id}/fotos")
    public ResponseEntity<QuadraResponseDTO> adicionarFotos(
            @PathVariable Long id,
            @RequestParam("fotos") List<MultipartFile> fotos,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(quadraService.adicionarFotos(id, fotos, usuario));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @DeleteMapping("/{quadraId}/fotos/{fotoId}")
    public ResponseEntity<Void> removerFoto(
            @PathVariable Long quadraId,
            @PathVariable Long fotoId,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        quadraService.removerFoto(quadraId, fotoId, usuario);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<QuadraResponseDTO>> getAll() {
        return ResponseEntity.ok(quadraService.getAll());
    }

    // Retorna quadras de uma arena específica
    @GetMapping("/arena/{arenaId}")
    public ResponseEntity<List<QuadraResponseDTO>> getByArena(@PathVariable Long arenaId) {
        return ResponseEntity.ok(quadraService.getByArena(arenaId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<QuadraResponseDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(quadraService.getById(id));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PutMapping("/{id}")
    public ResponseEntity<QuadraResponseDTO> update(
            @PathVariable Long id,
            @RequestBody QuadraCadastroDTO dto,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(quadraService.update(id, dto, usuario));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();
        quadraService.delete(id, usuario);
        return ResponseEntity.noContent().build();
    }
}