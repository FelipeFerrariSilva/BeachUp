package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.AvaliacaoCadastroDTO;
import Backend.BeachUp.DTO.AvaliacaoResponseDTO;
import Backend.BeachUp.DTO.QuadraAvaliacaoResumoDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.AvaliacaoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/avaliacoes")
@RequiredArgsConstructor
public class AvaliacaoController {

    private final AvaliacaoService avaliacaoService;

    @PostMapping
    public ResponseEntity<AvaliacaoResponseDTO> avaliar(
            @RequestBody @Valid AvaliacaoCadastroDTO dto,
            @AuthenticationPrincipal Usuario usuarioLogado) {
        return ResponseEntity.ok(avaliacaoService.avaliar(dto, usuarioLogado));
    }

    @GetMapping("/quadra/{quadraId}")
    public ResponseEntity<List<AvaliacaoResponseDTO>> listarPorQuadra(@PathVariable Long quadraId) {
        return ResponseEntity.ok(avaliacaoService.listarPorQuadra(quadraId));
    }

    @GetMapping("/quadra/{quadraId}/resumo")
    public ResponseEntity<QuadraAvaliacaoResumoDTO> resumoPorQuadra(@PathVariable Long quadraId) {
        return ResponseEntity.ok(avaliacaoService.resumoPorQuadra(quadraId));
    }
}
