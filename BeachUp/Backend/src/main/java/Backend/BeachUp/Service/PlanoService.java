package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.AssinaturaResponseDTO;
import Backend.BeachUp.Model.AssinaturaEmpresaModel;
import Backend.BeachUp.Model.ENUMS.StatusAssinatura;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.Empresa;
import Backend.BeachUp.Model.PlanoModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.AssinaturaEmpresaRepository;
import Backend.BeachUp.Repository.EmpresaRepository;
import Backend.BeachUp.Repository.PlanoRepository;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@AllArgsConstructor
@Slf4j
public class PlanoService {

    private final PlanoRepository planoRepository;
    private final AssinaturaEmpresaRepository assinaturaRepository;
    private final EmpresaRepository empresaRepository;

    @jakarta.annotation.PostConstruct // Garantia de que os planos existem no banco ao iniciar a aplicação
    public void inicializarPlanos() {
        if (planoRepository.findByTipo(TipoPlano.GRATUITO).isEmpty()) {
            planoRepository.save(PlanoModel.builder()
                    .tipo(TipoPlano.GRATUITO)
                    .nome("Gratuito")
                    .descricao("Taxa de 3% por reserva. Ate 2 quadras cadastradas.")
                    .limiteQuadras(2)
                    .valorMensal(BigDecimal.ZERO)
                    .build());
        }

        if (planoRepository.findByTipo(TipoPlano.BASICO).isEmpty()) {
            planoRepository.save(PlanoModel.builder()
                    .tipo(TipoPlano.BASICO)
                    .nome("Basico")
                    .descricao("Taxa de 1% por reserva. Quadras ilimitadas.")
                    .limiteQuadras(null)
                    .valorMensal(new BigDecimal("199.90"))
                    .build());
        }

        if (planoRepository.findByTipo(TipoPlano.GOLD).isEmpty()) {
            planoRepository.save(PlanoModel.builder()
                    .tipo(TipoPlano.GOLD)
                    .nome("Gold")
                    .descricao("Sem taxa por reserva. Quadras ilimitadas. Criacao de campeonatos.")
                    .limiteQuadras(null)
                    .valorMensal(new BigDecimal("399.90"))
                    .build());
        }
    }

    // Chamado ao cadastrar empresa, entra automaticamente no gratuito

    @Transactional
    public void atribuirPlanoGratuito(Empresa empresa) {
        PlanoModel planoGratuito = planoRepository.findByTipo(TipoPlano.GRATUITO)
                .orElseThrow(() -> new RuntimeException("Plano gratuito nao encontrado"));

        AssinaturaEmpresaModel assinatura = AssinaturaEmpresaModel.builder()
                .empresa(empresa)
                .plano(planoGratuito)
                .dataInicio(LocalDateTime.now())
                .dataFim(null)
                .status(StatusAssinatura.ATIVA)
                .renovacaoAutomatica(false)
                .build();

        assinaturaRepository.save(assinatura);
    }

    public AssinaturaResponseDTO buscarAssinatura(Usuario usuarioLogado) {
        Empresa empresa = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa nao encontrada"));

        AssinaturaEmpresaModel assinatura = assinaturaRepository.findByEmpresaId(empresa.getId())
                .orElseThrow(() -> new RuntimeException("Assinatura nao encontrada"));

        return toResponse(assinatura);
    }

    // Verifica se empresa pode cadastrar mais quadras com seu plano atual.
    public void validarLimiteQuadras(Empresa empresa, int totalAtual) {
        AssinaturaEmpresaModel assinatura = assinaturaRepository.findByEmpresaId(empresa.getId())
                .orElseThrow(() -> new RuntimeException("Assinatura nao encontrada"));

        // Planos pagos ativos nao tem limite
        if (assinatura.isPagoAtivo()) return;

        Integer limite = assinatura.getPlano().getLimiteQuadras();
        if (limite != null && totalAtual >= limite) {
            throw new RuntimeException(
                    "Limite de " + limite + " quadras atingido no plano Gratuito. " +
                            "Faca upgrade para o plano Basico (R$199,90/mes, 1% de taxa) ou " +
                            "Gold (R$399,90/mes, sem taxa) para cadastrar quadras ilimitadas."
            );
        }
    }

    // Verifica se empresa tem permissao para criar campeonatos (apenas GOLD).
    public void validarPermissaoCampeonato(Empresa empresa) {
        AssinaturaEmpresaModel assinatura = assinaturaRepository.findByEmpresaId(empresa.getId())
                .orElseThrow(() -> new RuntimeException("Assinatura nao encontrada"));

        if (!assinatura.isGoldAtivo()) {
            throw new RuntimeException(
                    "Apenas empresas com o plano GOLD podem criar campeonatos. " +
                            "Faca upgrade por R$399,90/mes em /pagamentos/plano/iniciar."
            );
        }
    }

    // Roda todo dia a meia noite rebaixa planos expirados para gratuito.
    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void verificarAssinaturasExpiradas() {
        List<AssinaturaEmpresaModel> expiradas = assinaturaRepository
                .findAssinaturasExpiradas(LocalDateTime.now());

        if (expiradas.isEmpty()) return;

        PlanoModel planoGratuito = planoRepository.findByTipo(TipoPlano.GRATUITO)
                .orElseThrow(() -> new RuntimeException("Plano gratuito nao encontrado"));

        for (AssinaturaEmpresaModel assinatura : expiradas) {
            log.info("Rebaixando empresa {} para plano Gratuito — plano {} expirou em {}",
                    assinatura.getEmpresa().getId(),
                    assinatura.getPlano().getTipo(),
                    assinatura.getDataFim());

            assinatura.setPlano(planoGratuito);
            assinatura.setDataFim(null);
            assinatura.setStatus(StatusAssinatura.ATIVA);
            assinaturaRepository.save(assinatura);
        }

        log.info("{} assinatura(s) expirada(s) rebaixada(s) para gratuito", expiradas.size());
    }

    private AssinaturaResponseDTO toResponse(AssinaturaEmpresaModel a) {
        return new AssinaturaResponseDTO(
                a.getId(),
                a.getPlano().getTipo(),
                a.getPlano().getNome(),
                a.getPlano().getLimiteQuadras(),
                a.getPlano().getValorMensal(),
                a.getTaxaBeachUp(),
                a.getDataInicio(),
                a.getDataFim(),
                a.getStatus(),
                a.isPagoAtivo(),
                a.isGoldAtivo()
        );
    }
}