package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.*;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.PagamentoService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Map;

@RestController
@RequestMapping("/pagamentos")
@AllArgsConstructor
public class PagamentoController {

    private final PagamentoService pagamentoService;

    // PAGAMENTO PLANO ( CHECKOUT PRO )
    @PreAuthorize("hasRole('EMPRESA')")
    @PostMapping("/plano/iniciar")
    public ResponseEntity<CheckoutProResponseDTO> iniciarPagamentoPlano(@RequestParam TipoPlano tipoPlano,
Authentication auth) {
        Usuario usuario = (Usuario) auth.getPrincipal();
        return ResponseEntity.ok(pagamentoService.iniciarPagamentoPlano(usuario, tipoPlano));
    }
    // PAGAMENTO RESERVAS ( CHECKOUT PRO )
    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping("/reserva/{reservaId}/iniciar")
    public ResponseEntity<CheckoutProResponseDTO> iniciarPagamentoReserva(@PathVariable Long reservaId, Authentication auth) {
        Usuario usuario = (Usuario) auth.getPrincipal();
        return ResponseEntity.ok(pagamentoService.iniciarPagamentoReserva(reservaId, usuario));
    }

    //PAGAMENTO INSCRIÇÃO CHECKOUT PRO
    @PreAuthorize("hasRole('JOGADOR')")
    @PostMapping("/inscricao/{inscricaoId}/iniciar")
    public ResponseEntity<InscricaoResponseDTO> iniciarPagamentoInscricao(@PathVariable Long inscricaoId, Authentication auth) {
        Usuario usuario = (Usuario) auth.getPrincipal();
        return ResponseEntity.ok(pagamentoService.iniciarPagamentoInscricao(inscricaoId, usuario));
    }

    //CONEXÃO OAUTH EMPRESA AO MERCADO PAGO
    @PreAuthorize("hasRole('EMPRESA')")
    @GetMapping("/oauth/conectar")
    public ResponseEntity<String> conectarContaMP(Authentication auth) {
        Usuario usuario = (Usuario) auth.getPrincipal();
        return ResponseEntity.ok(pagamentoService.gerarUrlOAuth(usuario));
    }

    @GetMapping("/oauth/callback")
    public ResponseEntity<String> oauthCallback(@RequestParam String code, @RequestParam String state) {
        pagamentoService.processarCallbackOAuth(code, state);
        return ResponseEntity.status(HttpStatus.FOUND)
                .location(URI.create("https://www.beachup.com.br/configuracoes?mp_status=success"))
                .build();
    }

    //WEBHOOKS
    @PostMapping("/webhook")
    public ResponseEntity<Void> webhook(@RequestBody Map<String, Object> payload) {
        pagamentoService.processarWebhook(payload);
        return ResponseEntity.ok().build();
    }
}
