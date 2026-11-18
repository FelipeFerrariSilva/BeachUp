package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.JogadorAtualizadoDTO;
import Backend.BeachUp.DTO.JogadorCadastroDTO;
import Backend.BeachUp.DTO.JogadorResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.JogadorService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/jogador")
public class JogadorController {
    @Autowired
    private JogadorService service;

    @PostMapping("/cadastro")
    public JogadorResponseDTO create(@RequestBody JogadorCadastroDTO dto){
        return service.create(dto);
    }

    @GetMapping
    public List<JogadorResponseDTO> getAll(){
        return service.getAll();
    }

    @GetMapping("/{id}")
    public JogadorResponseDTO getById(@PathVariable Long id){
        return service.getById(id);
    }

    @PreAuthorize("hasRole('JOGADOR')")
    @PutMapping(value = "/{id}", consumes = {"multipart/form-data"})
    public JogadorAtualizadoDTO putById(
            @PathVariable Long id,
            @RequestPart("dados") JogadorCadastroDTO dto,
            @RequestPart(value = "foto", required = false) MultipartFile foto,
            Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return service.putById(id, dto, usuario, foto);
    }
    @PreAuthorize("hasRole('JOGADOR')")
    @GetMapping("/me")
    public JogadorResponseDTO getMe(Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return service.getMe(usuario);
    }

    @PreAuthorize("hasRole('JOGADOR')")
    @DeleteMapping("/{id}")
    public void deleteById(@PathVariable Long id, Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        service.deleteById(id, usuario);
    }
}