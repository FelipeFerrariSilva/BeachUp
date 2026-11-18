package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.CnpjResponseDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

@Service
@Slf4j
public class CnpjService {

    private static final String RECEITA_WS_URL = "https://receitaws.com.br/v1/cnpj/";

    private final RestTemplate restTemplate;

    public CnpjService (){
        this.restTemplate = new RestTemplate();
    }

    public void validarCnpjAtivo(String cnpj){
        String cnpjLimpo = cnpj.replaceAll("[^0-9]","");

        if (cnpjLimpo.length()!=14){
            throw new RuntimeException("CNPJ inválido: Precisa conter 14 digitos");
        }

        CnpjResponseDTO resposta = consultarCnpj(cnpjLimpo);

        if (!"OK".equalsIgnoreCase(resposta.status())){ // Caso API retorne ERRO (cnpj inexistente ou limite de requisições)
            String mensagem = resposta.message() != null
                    ? resposta.message() : "CNPJ não encontrado na Receita Federal";
            throw new RuntimeException("Falha na validação do CNPJ: " + mensagem);
        }

        if (!"ATIVA".equalsIgnoreCase(resposta.situacao())){
            throw new RuntimeException("CNPJ com situação irregular na Receita Federal: " + resposta.situacao() +
                    ". Apenas empresas com situação ATIVA podem se cadastrar."
            );
        }

        log.info("CNPJ {} validado com sucesso - empresa: {}", cnpjLimpo, resposta.nome());
    }

    private CnpjResponseDTO consultarCnpj(String cnpj) {
        try {
            return restTemplate.getForObject(RECEITA_WS_URL + cnpj, CnpjResponseDTO.class);

        } catch (HttpClientErrorException.TooManyRequests e) {
            // ReceitaWS tem limite de 3 req/min no plano gratuito
            throw new RuntimeException(
                    "Serviço de validação de CNPJ temporariamente indisponível. " +
                            "Tente novamente em alguns segundos."
            );

        } catch (ResourceAccessException e) {
            // Timeout ou serviço fora do ar
            log.error("Erro ao consultar ReceitaWS para CNPJ {}: {}", cnpj, e.getMessage());
            throw new RuntimeException(
                    "Não foi possível validar o CNPJ no momento. " +
                            "Verifique sua conexão ou tente novamente mais tarde."
            );

        } catch (Exception e) {
            log.error("Erro inesperado ao validar CNPJ {}: {}", cnpj, e.getMessage());
            throw new RuntimeException("Erro ao validar CNPJ: " + e.getMessage());
        }
    }
}
