package Backend.BeachUp.Service;

import Backend.BeachUp.Model.ReservaModel;
import Backend.BeachUp.Repository.ReservaRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificacaoAgendadaService {


    private final ReservaRepository reservaRepository;
    private final EmailService emailService;
    private final PasswordResetService passwordResetService;

    @Scheduled(fixedDelay = 30 * 60 * 1000) // 30 minutos em ms
    @Transactional
    public void enviarEmailsDeAvaliacao() {
        List<ReservaModel> pendentes =
                reservaRepository.findReservasEncerradasSemEmailAvaliacao(LocalDateTime.now());

        if (pendentes.isEmpty()) return;

        log.info("Enviando email de avaliacao para {} reserva(s) encerrada(s)", pendentes.size());

        for (ReservaModel reserva : pendentes) {
            try {
                emailService.enviarEmailSolicitacaoAvaliacao(reserva);
                reserva.setEmailAvaliacaoEnviado(true);
                reservaRepository.save(reserva);
            } catch (Exception e) {
                log.error("Erro ao enviar email de avaliacao para reserva {}: {}",
                        reserva.getId(), e.getMessage());
            }
        }
    }

    @Scheduled(fixedDelay = 60 * 60 * 1000) // RODA 1X POR HORA PARA RESETAR TOKENS EXPIRADOS
    @Transactional
    public void limparTokensResetExpirados() {
        passwordResetService.limparTokensExpirados();
        log.debug("Limpeza de tokens de reset executada");
    }
}
