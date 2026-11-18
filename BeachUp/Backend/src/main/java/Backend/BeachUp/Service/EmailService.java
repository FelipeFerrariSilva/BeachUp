package Backend.BeachUp.Service;


import Backend.BeachUp.Model.ReservaModel;
import Backend.BeachUp.Model.Usuario;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import java.time.format.DateTimeFormatter;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    @Value("${spring.mail.username}")
    private String remetente;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm", new Locale("pt", "BR"));


        //EMAIL ENVIADO AO DONO DA QUADRA A CADA RESERVA
    @Async
    public void enviarEmailReservaConfirmada(ReservaModel reserva) {
        String emailEmpresa = reserva.getQuadra().getArenas().getEmpresa().getUsuario().getEmail();

        Context ctx = new Context(new Locale("pt", "BR"));
        ctx.setVariable("nomeEmpresa",  reserva.getQuadra().getArenas().getEmpresa().getUsuario().getNome());
        ctx.setVariable("nomeQuadra",   reserva.getQuadra().getNome());
        ctx.setVariable("nomeArena",    reserva.getQuadra().getArenas().getNome());
        ctx.setVariable("nomeJogador",  reserva.getJogador().getUsuario().getNome());
        ctx.setVariable("dataHoraInicio", reserva.getDataHoraInicio().format(FMT));
        ctx.setVariable("dataHoraFim",    reserva.getDataHoraFim().format(FMT));
        ctx.setVariable("valorTotal",   "R$ " + reserva.getValorTotal().toString().replace(".", ","));

        String html = templateEngine.process("email/reserva-confirmada", ctx);

        enviar(emailEmpresa, "Nova reserva confirmada — " + reserva.getQuadra().getNome(), html);
    }

    //EMAIL ENVIADO PARA CADA JOGADOR APÓS O FIM DE UMA RESERVA
    @Async
    public void enviarEmailSolicitacaoAvaliacao(ReservaModel reserva) {
        String emailJogador = reserva.getJogador().getUsuario().getEmail();
        String link = frontendUrl + "/avaliar/" + reserva.getId();

        Context ctx = new Context(new Locale("pt", "BR"));
        ctx.setVariable("nomeJogador",    reserva.getJogador().getUsuario().getNome());
        ctx.setVariable("nomeQuadra",     reserva.getQuadra().getNome());
        ctx.setVariable("nomeArena",      reserva.getQuadra().getArenas().getNome());
        ctx.setVariable("dataHoraInicio", reserva.getDataHoraInicio().format(FMT));
        ctx.setVariable("linkAvaliacao",  link);

        String html = templateEngine.process("email/solicitacao-avaliacao", ctx);

        enviar(emailJogador, "Como foi sua experiência na " + reserva.getQuadra().getNome() + "?", html);
    }

    //REDEFINIR SENHA
    @Async
    public void enviarEmailResetSenha(Usuario usuario, String token) {
        String link = frontendUrl + "/redefinir-senha?token=" + token;

        Context ctx = new Context(new Locale("pt", "BR"));
        ctx.setVariable("nomeUsuario",    usuario.getNome());
        ctx.setVariable("linkRedefinicao", link);

        String html = templateEngine.process("email/reset-senha", ctx);

        enviar(usuario.getEmail(), "Redefinição de senha — BeachUp", html);
    }

    private void enviar(String destinatario, String assunto, String html) {
        try {
            MimeMessage msg = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true, "UTF-8");
            helper.setFrom(remetente);
            helper.setTo(destinatario);
            helper.setSubject(assunto);
            helper.setText(html, true);
            mailSender.send(msg);
            log.info("Email enviado para {} — assunto: {}", destinatario, assunto);
        } catch (MessagingException e) {
            log.error("Falha ao enviar email para {}: {}", destinatario, e.getMessage());
        }
    }
}
