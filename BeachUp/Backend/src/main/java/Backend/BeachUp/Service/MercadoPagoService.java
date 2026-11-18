package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.CheckoutProResponseDTO;
import Backend.BeachUp.Model.Empresa;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class MercadoPagoService {

    @Value("${mp.access-token}")
    private String accessToken;

    @Value("${mp.client-id}")
    private String clientId;

    @Value("${mp.client-secret}")
    private String clientSecret;

    @Value("${mp.redirect-uri}")
    private String redirectUri;

    @Value("${mp.success-url:http://localhost:4200/plano/sucesso}")
    private String successUrl;

    @Value("${mp.failure-url:http://localhost:4200/plano/falha}")
    private String failureUrl;

    @Value("${mp.pending-url:http://localhost:4200/plano/pendente}")
    private String pendingUrl;

    @Value("${mp.webhook-url}")
    private String webhookUrl;

    private static final String MP_PREFERENCES_API = "https://api.mercadopago.com/checkout/preferences";
    private static final String MP_PAYMENTS_API    = "https://api.mercadopago.com/v1/payments/";
    private static final String MP_OAUTH_URL       = "https://auth.mercadopago.com/authorization";
    private static final String MP_TOKEN_URL       = "https://api.mercadopago.com/oauth/token";

    private final RestTemplate restTemplate = new RestTemplate();
  // PAGAMENTO PLANO

    public CheckoutProResponseDTO criarPreferenciaPlano(String nomePlano, BigDecimal valor, Long empresaId) {
        Map<String, Object> item = new HashMap<>();
        item.put("title", "Plano " + nomePlano + " BeachUp");
        item.put("quantity", 1);
        item.put("unit_price", valor);
        item.put("currency_id", "BRL");

        Map<String, Object> body = new HashMap<>();
        body.put("items", List.of(item));
        body.put("back_urls", backUrls());
        body.put("auto_approve", false);
        body.put("external_reference", "PLANO_" + nomePlano.toUpperCase() + "_" + empresaId);
        body.put("notification_url", webhookUrl);

        return executarCriacaoPreferencia(body, accessToken);
    }


    // PAGAMENTO RESERVA

    public CheckoutProResponseDTO criarPreferenciaReserva(
            BigDecimal valorTotal, Long reservaId, Empresa empresa, double taxaBeachUp) {

        validarContaEmpresa(empresa);

        Map<String, Object> item = new HashMap<>();
        item.put("title", "Reserva de Quadra BeachUp #" + reservaId);
        item.put("quantity", 1);
        item.put("unit_price", valorTotal);
        item.put("currency_id", "BRL");

        Map<String, Object> body = new HashMap<>();
        body.put("items", List.of(item));
        body.put("back_urls", backUrls());
        body.put("auto_approve", false);
        body.put("external_reference", "RESERVA_" + reservaId);
        body.put("notification_url", webhookUrl);

        if (taxaBeachUp > 0) {
            BigDecimal fee = valorTotal
                    .multiply(BigDecimal.valueOf(taxaBeachUp))
                    .setScale(2, RoundingMode.HALF_UP);
            body.put("marketplace_fee", fee);
        }
        return executarCriacaoPreferencia(body, empresa.getMpAccessToken());
    }

  // PAGAMENTO INSCRICAO


    public CheckoutProResponseDTO criarPreferenciaInscricao(
            BigDecimal taxaInscricao, Long campeonatoId, Long timeId,
            String nomeCampeonato, Empresa empresa) {

        validarContaEmpresa(empresa);

        Map<String, Object> item = new HashMap<>();
        item.put("title", "Inscricao no Campeonato: " + nomeCampeonato);
        item.put("quantity", 1);
        item.put("unit_price", taxaInscricao);
        item.put("currency_id", "BRL");

        Map<String, Object> body = new HashMap<>();
        body.put("items", List.of(item));
        body.put("back_urls", backUrls());
        body.put("auto_approve", false);
        body.put("external_reference", "INSCRICAO_" + campeonatoId + "_" + timeId);
        body.put("notification_url", webhookUrl);

        return executarCriacaoPreferencia(body, empresa.getMpAccessToken());
    }


    // WEBHOOK — buscar detalhes do pagamento na API do MP

    public String getAccessToken() {
        return accessToken;
    }

    public Map<String, Object> buscarPagamento(String paymentId, String token) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(token);

            ResponseEntity<Map> response = restTemplate.exchange(
                    MP_PAYMENTS_API + paymentId,
                    HttpMethod.GET,
                    new HttpEntity<>(headers),
                    Map.class
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                return response.getBody();
            }
        } catch (Exception e) {
            log.error("Erro ao buscar pagamento {} na API do MP: {}", paymentId, e.getMessage());
        }
        return null;
    }

 // OAUTH

    public String gerarUrlOAuth(Long empresaId) {
        return MP_OAUTH_URL
                + "?client_id=" + clientId
                + "&response_type=code"
                + "&platform_id=mp"
                + "&redirect_uri=" + redirectUri
                + "&state=" + empresaId;
    }

    public Map<String, String> processarCallbackOAuth(String code) {
        Map<String, Object> body = new HashMap<>();
        body.put("client_id", clientId);
        body.put("client_secret", clientSecret);
        body.put("grant_type", "authorization_code");
        body.put("code", code);
        body.put("redirect_uri", redirectUri);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        ResponseEntity<Map> response = restTemplate.exchange(
                MP_TOKEN_URL, HttpMethod.POST,
                new HttpEntity<>(body, headers), Map.class
        );

        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new RuntimeException("Erro ao autenticar no Mercado Pago");
        }

        Map resultado = response.getBody();
        if (resultado == null || resultado.get("access_token") == null) {
            throw new RuntimeException("Token nao retornado pelo Mercado Pago");
        }

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", (String) resultado.get("access_token"));
        tokens.put("refreshToken", (String) resultado.get("refresh_token"));
        tokens.put("userId", String.valueOf(resultado.get("user_id")));
        return tokens;
    }


    private CheckoutProResponseDTO executarCriacaoPreferencia(Map<String, Object> body, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(token);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    MP_PREFERENCES_API, HttpMethod.POST,
                    new HttpEntity<>(body, headers), Map.class
            );

            Map resultado = response.getBody();
            if (resultado == null) throw new RuntimeException("Resposta vazia do Mercado Pago");

            String preferenceId     = (String) resultado.get("id");
            String initPoint        = (String) resultado.get("init_point");
            String sandboxInitPoint = (String) resultado.get("sandbox_init_point");

            log.info("Preferencia Checkout Pro criada: id={}", preferenceId);
            return new CheckoutProResponseDTO(preferenceId, initPoint, sandboxInitPoint);

        } catch (Exception e) {
            log.error("Erro ao criar preferencia Checkout Pro: {}", e.getMessage());
            throw new RuntimeException("Erro ao criar preferencia de pagamento: " + e.getMessage());
        }
    }

    private Map<String, Object> backUrls() {
        Map<String, Object> urls = new HashMap<>();
        urls.put("success", successUrl);
        urls.put("failure", failureUrl);
        urls.put("pending", pendingUrl);
        return urls;
    }

    private void validarContaEmpresa(Empresa empresa) {
        if (!empresa.temContaMpConectada()) {
            throw new RuntimeException(
                    "A empresa ainda nao conectou sua conta do Mercado Pago. " +
                            "Acesse /pagamentos/oauth/conectar para autorizar."
            );
        }
    }
}