package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.*;
import Backend.BeachUp.Model.*;
import Backend.BeachUp.Model.ENUMS.StatusAssinatura;
import Backend.BeachUp.Model.ENUMS.StatusInscricao;
import Backend.BeachUp.Model.ENUMS.StatusReserva;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Repository.*;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Service
@AllArgsConstructor
@Slf4j
public class PagamentoService {

    private final MercadoPagoService mpService;
    private final ReservaRepository reservaRepository;
    private final AssinaturaEmpresaRepository assinaturaRepository;
    private final EmpresaRepository empresaRepository;
    private final PlanoRepository planoRepository;
    private final InscricaoCampeonatoRepository inscricaoRepository;

    // PAGAMENTO PLANO
public CheckoutProResponseDTO iniciarPagamentoPlano(Usuario usuarioLogado, TipoPlano tipoPlano) {
        if (tipoPlano == TipoPlano.GRATUITO) {
            throw new RuntimeException("Nao e possivel pagar pelo plano gratuito");
        }

        Empresa empresa = buscarEmpresa(usuarioLogado);
        AssinaturaEmpresaModel assinatura = buscarAssinatura(empresa);

        if (assinatura.getPlano().getTipo() == tipoPlano && assinatura.isPagoAtivo()) {
            throw new RuntimeException("Empresa ja possui o plano " + tipoPlano + " ativo");
        }

        PlanoModel plano = planoRepository.findByTipo(tipoPlano)
                .orElseThrow(() -> new RuntimeException("Plano " + tipoPlano + " nao encontrado"));

        return mpService.criarPreferenciaPlano(plano.getNome(), plano.getValorMensal(), empresa.getId());
    }
    // PAGAMENTO RESERVA
    public CheckoutProResponseDTO iniciarPagamentoReserva(Long reservaId, Usuario usuarioLogado) {
        ReservaModel reserva = buscarReservaDoJogador(reservaId, usuarioLogado);
        Empresa empresa = reserva.getQuadra().getArenas().getEmpresa();

        double taxaBeachUp = assinaturaRepository.findByEmpresaId(empresa.getId())
                .map(AssinaturaEmpresaModel::getTaxaBeachUp)
                .orElse(0.03);

        CheckoutProResponseDTO checkout = mpService.criarPreferenciaReserva(
                reserva.getValorTotal(), reservaId, empresa, taxaBeachUp);

        reserva.setMpPaymentId(checkout.preferenceId());
        reserva.setMpPaymentStatus("pending");
        reservaRepository.save(reserva);

        return checkout;
    }

 // PAGAMENTO INSCRICAO

    @Transactional
    public InscricaoResponseDTO iniciarPagamentoInscricao(Long inscricaoId, Usuario usuarioLogado) {
        InscricaoCampeonatoModel inscricao = inscricaoRepository.findById(inscricaoId)
                .orElseThrow(() -> new RuntimeException("Inscricao nao encontrada"));

        if (!inscricao.getTime().getJogador().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado");
        }

        if (inscricao.getStatus() == StatusInscricao.CONFIRMADA) {
            throw new RuntimeException("Inscricao ja esta confirmada");
        }

        CampeonatoModel campeonato = inscricao.getCampeonato();
        BigDecimal taxa = campeonato.getTaxaInscricao();

        if (taxa == null || taxa.compareTo(BigDecimal.ZERO) == 0) {
            inscricao.setStatus(StatusInscricao.CONFIRMADA);
            inscricao.setMpPaymentStatus("approved");
            inscricaoRepository.save(inscricao);
            return toInscricaoResponse(inscricao, null);
        }

        Empresa empresa = campeonato.getEmpresa();
        CheckoutProResponseDTO checkout = mpService.criarPreferenciaInscricao(
                taxa, campeonato.getId(), inscricao.getTime().getId(),
                campeonato.getNome(), empresa);

        inscricao.setMpPaymentId(checkout.preferenceId());
        inscricao.setMpPaymentStatus("pending");
        inscricaoRepository.save(inscricao);

        return toInscricaoResponse(inscricao, checkout);
    }

  // WEBHOOK

    @Transactional
    public void processarWebhook(Map<String, Object> payload) {
        String tipo = (String) payload.get("type");
        if (!"payment".equals(tipo)) return;

        Map<String, Object> data = (Map<String, Object>) payload.get("data");
        if (data == null) return;

        String paymentId = String.valueOf(data.get("id"));
        log.info("Webhook recebido: paymentId={}", paymentId);
        Map<String, Object> pagamentoMp = mpService.buscarPagamento(paymentId, mpService.getAccessToken());
        if (pagamentoMp == null) {
            log.warn("Nao foi possivel buscar pagamento {} na API do MP", paymentId);
            return;
        }

        String status = (String) pagamentoMp.get("status");
        String externalRef = (String) pagamentoMp.get("external_reference");

        if (!"approved".equals(status) || externalRef == null) {
            log.info("Pagamento {} ignorado. Status: {}, Ref: {}", paymentId, status, externalRef);
            return;
        }

        if (externalRef.startsWith("RESERVA_")) {
            Long reservaId = Long.parseLong(externalRef.replace("RESERVA_", ""));
            reservaRepository.findById(reservaId).ifPresent(reserva -> {
                if (!"approved".equals(reserva.getMpPaymentStatus())) {
                    reserva.setMpPaymentId(paymentId);
                    reserva.setMpPaymentStatus("approved");
                    reserva.setStatus(StatusReserva.CONFIRMADA);
                    reservaRepository.save(reserva);
                    log.info("Reserva {} confirmada via webhook", reservaId);
                }
            });

        } else if (externalRef.startsWith("PLANO_")) {
            String[] partes = externalRef.split("_");
            if (partes.length == 3) {
                TipoPlano tipoPlano = TipoPlano.valueOf(partes[1]);
                Long empresaId = Long.parseLong(partes[2]);
                assinaturaRepository.findByEmpresaId(empresaId).ifPresent(assinatura -> {
                    if (assinatura.getStatus() != StatusAssinatura.ATIVA) {
                        PlanoModel plano = planoRepository.findByTipo(tipoPlano)
                                .orElseThrow(() -> new RuntimeException("Plano nao encontrado"));
                        assinatura.setMpPaymentId(paymentId);
                        ativarPlano(assinatura, plano);
                        assinaturaRepository.save(assinatura);
                        log.info("Plano {} ativado via webhook para empresa {}", tipoPlano, empresaId);
                    }
                });
            }

        } else if (externalRef.startsWith("INSCRICAO_")) {
            String[] partes = externalRef.replace("INSCRICAO_", "").split("_");
            if (partes.length == 2) {
                Long campeonatoId = Long.parseLong(partes[0]);
                Long timeId = Long.parseLong(partes[1]);
                inscricaoRepository.findByCampeonatoIdAndTimeId(campeonatoId, timeId).ifPresent(inscricao -> {
                    if (inscricao.getStatus() != StatusInscricao.CONFIRMADA) {
                        inscricao.setMpPaymentId(paymentId);
                        inscricao.setMpPaymentStatus("approved");
                        inscricao.setStatus(StatusInscricao.CONFIRMADA);
                        inscricaoRepository.save(inscricao);
                        log.info("Inscricao campeonato={} time={} confirmada via webhook", campeonatoId, timeId);
                    }
                });
            }
        }
    }

  // OAUTH

    @Transactional
    public String gerarUrlOAuth(Usuario usuarioLogado) {
        return mpService.gerarUrlOAuth(buscarEmpresa(usuarioLogado).getId());
    }

    @Transactional
    public void processarCallbackOAuth(String code, String state) {
        Long empresaId = Long.parseLong(state);
        Empresa empresa = empresaRepository.findById(empresaId)
                .orElseThrow(() -> new RuntimeException("Empresa nao encontrada"));

        Map<String, String> tokens = mpService.processarCallbackOAuth(code);
        empresa.setMpAccessToken(tokens.get("accessToken"));
        empresa.setMpRefreshToken(tokens.get("refreshToken"));
        empresa.setMpUserId(tokens.get("userId"));

        empresaRepository.save(empresa);
        log.info("Conta MP conectada para empresa {}", empresaId);
    }


    // Helpers

    private void ativarPlano(AssinaturaEmpresaModel assinatura, PlanoModel plano) {
        assinatura.setPlano(plano);
        assinatura.setDataInicio(LocalDateTime.now());
        assinatura.setDataFim(LocalDateTime.now().plusDays(30));
        assinatura.setStatus(StatusAssinatura.ATIVA);
    }

    private ReservaModel buscarReservaDoJogador(Long reservaId, Usuario usuarioLogado) {
        ReservaModel reserva = reservaRepository.findById(reservaId)
                .orElseThrow(() -> new RuntimeException("Reserva nao encontrada"));

        if (!reserva.getJogador().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado");
        }
        if (reserva.getStatus() == StatusReserva.CANCELADA) {
            throw new RuntimeException("Reserva cancelada nao pode ser paga");
        }
        if ("approved".equals(reserva.getMpPaymentStatus())) {
            throw new RuntimeException("Reserva ja esta paga");
        }
        return reserva;
    }

    private AssinaturaEmpresaModel buscarAssinatura(Empresa empresa) {
        return assinaturaRepository.findByEmpresaId(empresa.getId())
                .orElseThrow(() -> new RuntimeException("Assinatura nao encontrada"));
    }

    private Empresa buscarEmpresa(Usuario usuarioLogado) {
        return empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa nao encontrada"));
    }

    private InscricaoResponseDTO toInscricaoResponse(
            InscricaoCampeonatoModel inscricao, CheckoutProResponseDTO checkout) {
        return new InscricaoResponseDTO(
                inscricao.getId(),
                inscricao.getCampeonato().getId(),
                inscricao.getCampeonato().getNome(),
                inscricao.getTime().getId(),
                inscricao.getTime().getNome(),
                inscricao.getStatus(),
                inscricao.getCampeonato().getTaxaInscricao(),
                checkout != null ? checkout.preferenceId()     : null,
                checkout != null ? checkout.initPoint()        : null,
                checkout != null ? checkout.sandboxInitPoint() : null
        );
    }
}