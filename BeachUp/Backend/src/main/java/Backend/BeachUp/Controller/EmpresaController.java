package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.EmpresaAtualizadaDTO;
import Backend.BeachUp.DTO.EmpresaCadastroDTO;
import Backend.BeachUp.DTO.EmpresaResponseDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.EmpresaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/empresa")
public class EmpresaController {

    @Autowired
    private EmpresaService service;

    @PostMapping("/cadastro")
    public EmpresaResponseDTO create(@RequestBody EmpresaCadastroDTO dto){
        return service.create(dto);
    }


    @GetMapping
    public List<EmpresaResponseDTO> getAll(){
        return service.getAll();
    }


    @GetMapping("/{id}")
    public EmpresaResponseDTO getById(@PathVariable Long id){
        return service.getById(id);
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PutMapping(value = "/{id}", consumes = {"multipart/form-data"})
    public EmpresaAtualizadaDTO putById(
            @PathVariable Long id,
            @RequestPart("dados") EmpresaCadastroDTO dto,
            @RequestPart(value = "foto", required = false) MultipartFile foto,
            Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return service.putById(id, dto, usuario, foto);
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @GetMapping("/me")
    public EmpresaResponseDTO getMe(Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return service.getMe(usuario);
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @DeleteMapping("/{id}")
    public void deleteById(@PathVariable Long id, Authentication authentication){
        Usuario usuario = (Usuario) authentication.getPrincipal();
        service.deleteById(id, usuario);
    }

}