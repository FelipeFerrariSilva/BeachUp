package Backend.BeachUp.Controller;

import Backend.BeachUp.DTO.MetricasEmpresaDTO;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Service.MetricasService;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/metricas")
@AllArgsConstructor
public class MetricasController {

    private final MetricasService metricasService;

    @PreAuthorize("hasRole('ROLE_EMPRESA')")
    @GetMapping("/empresa")
    public ResponseEntity<MetricasEmpresaDTO> obterMetricas(Authentication auth) {
        Usuario usuario = (Usuario) auth.getPrincipal();
        return ResponseEntity.ok(metricasService.obterMetricas(usuario));
    }
}
