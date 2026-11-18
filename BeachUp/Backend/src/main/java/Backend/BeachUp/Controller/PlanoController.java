package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.AssinaturaResponseDTO;
import Backend.BeachUp.DTO.CheckoutProResponseDTO;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.PagamentoService;
import Backend.BeachUp.Service.PlanoService;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/planos")
@AllArgsConstructor
public class PlanoController {

    private final PlanoService planoService;
    private final PagamentoService pagamentoService;

    @PreAuthorize("hasRole('EMPRESA')")
    @GetMapping("/minha-assinatura")
    public ResponseEntity<AssinaturaResponseDTO> minhaAssinatura(Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(planoService.buscarAssinatura(usuario));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/upgrade/basico")
    public ResponseEntity<CheckoutProResponseDTO> assinarBasico(Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(pagamentoService.iniciarPagamentoPlano(usuario, TipoPlano.BASICO));
    }

    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/upgrade/gold")
    public ResponseEntity<CheckoutProResponseDTO> assinarGold(Authentication authentication) {
        Usuario usuario = (Usuario) authentication.getPrincipal();
        return ResponseEntity.ok(pagamentoService.iniciarPagamentoPlano(usuario, TipoPlano.GOLD));
    }
}
