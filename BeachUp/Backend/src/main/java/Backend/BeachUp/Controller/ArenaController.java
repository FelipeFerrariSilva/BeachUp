package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.ArenaCadastroDTO;
import Backend.BeachUp.DTO.ArenaResponseDTO;
import Backend.BeachUp.DTO.LocalizacaoDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.ArenaService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/arenas")
@AllArgsConstructor
public class ArenaController {


    private final ArenaService arenaService;

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping(consumes = {"multipart/form-data"})
    public ResponseEntity<ArenaResponseDTO> create(
            @RequestPart("dados") @Valid ArenaCadastroDTO dto,
            @RequestPart(value = "foto", required = false) MultipartFile foto,
            Authentication authentication) {

        Usuario usuario = (Usuario) authentication.getPrincipal();

        return ResponseEntity.ok(arenaService.create(dto, usuario, foto));
    }

    @PostMapping("/proximidade")
    public ResponseEntity<List<ArenaResponseDTO>> buscarPorProximidade(@RequestBody @Valid LocalizacaoDTO localizacao){
        return ResponseEntity.ok(arenaService.buscarPorProximidade(localizacao));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @GetMapping("/minhas")
    public ResponseEntity<List<ArenaResponseDTO>> minhas(Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(arenaService.getByEmpresa(usuario));
    }

    @GetMapping
    public ResponseEntity<List<ArenaResponseDTO>> getAll(){

        return ResponseEntity.ok(arenaService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ArenaResponseDTO> getById(@PathVariable Long id){

        return ResponseEntity.ok(arenaService.getById(id));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PutMapping(value = "/{id}", consumes = {"multipart/form-data"})
    public ResponseEntity<ArenaResponseDTO> update(
            @PathVariable Long id,
            @RequestPart("dados") @Valid ArenaCadastroDTO dto,
            @RequestPart(value = "foto", required = false) MultipartFile foto,
            Authentication authentication){

        Usuario usuario = (Usuario) authentication.getPrincipal();

        return ResponseEntity.ok(arenaService.update(id, dto, usuario, foto)
        );
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id, Authentication authentication){

        Usuario usuario = (Usuario) authentication.getPrincipal();

        arenaService.delete(id, usuario);

        return ResponseEntity.noContent().build();
    }
}