package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.NominatimResponseDTO;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class GeocodingService {

    private static final String VIACEP_URL = "https://viacep.com.br/ws/{cep}/json/";

    private static final String NOMINATIM_URL  = "https://nominatim.openstreetmap.org/search";

    private static final String USER_AGENT = "BeachUpApp/1.0 (contato@beachup.com.br)";

    private final RestTemplate restTemplate = new RestTemplate();

    public double[] geocodificar(String logradouro, String numero,
                                 String cidade, String estado, String cep) {

        String cepLimpo = cep.replaceAll("[^0-9]", "");

        // Etapa 1: normalizar endereço via ViaCEP
        String logradouroNorm = logradouro;
        String bairroNorm     = "";
        String cidadeNorm     = cidade;
        String estadoNorm     = estado;

        try {
            Map dadosCep = restTemplate.getForObject(VIACEP_URL, Map.class, cepLimpo);

            if (dadosCep != null && !dadosCep.containsKey("erro")) {
                // Usa os dados do ViaCEP se disponíveis (mais confiáveis)
                String logViaCep  = (String) dadosCep.get("logradouro");
                String bairroViaCep = (String) dadosCep.get("bairro");
                String cidadeViaCep = (String) dadosCep.get("localidade");
                String ufViaCep     = (String) dadosCep.get("uf");

                if (logViaCep  != null && !logViaCep.isBlank())   logradouroNorm = logViaCep;
                if (bairroViaCep != null)                          bairroNorm     = bairroViaCep;
                if (cidadeViaCep != null && !cidadeViaCep.isBlank()) cidadeNorm   = cidadeViaCep;
                if (ufViaCep    != null && !ufViaCep.isBlank())    estadoNorm     = ufViaCep;

                log.info("ViaCEP: CEP {} -> {}, {}, {}", cepLimpo, logradouroNorm, cidadeNorm, estadoNorm);
            } else {
                log.warn("ViaCEP: CEP {} nao encontrado, usando dados informados pelo usuario", cepLimpo);
            }
        } catch (Exception e) {
            log.warn("ViaCEP indisponivel para CEP {}: {} — usando dados informados", cepLimpo, e.getMessage());
        }

        // 2 Nominatim com fallbacks progressivos
        double[] coords;

        // Tentativa 1 endereço completo com número e bairro
        coords = buscarNominatim(numero + " " + logradouroNorm, bairroNorm, cidadeNorm, estadoNorm);
        if (coords != null) {
            log.info("Nominatim (completo): lat={}, lon={}", coords[0], coords[1]);
            return coords;
        }

        // Tentativa 2: sem número
        coords = buscarNominatim(logradouroNorm, bairroNorm, cidadeNorm, estadoNorm);
        if (coords != null) {
            log.info("Nominatim (sem numero): lat={}, lon={}", coords[0], coords[1]);
            return coords;
        }

        // Tentativa 3: só logradouro + cidade + UF (sem bairro)
        coords = buscarNominatim(logradouroNorm, "", cidadeNorm, estadoNorm);
        if (coords != null) {
            log.info("Nominatim (logradouro+cidade): lat={}, lon={}", coords[0], coords[1]);
            return coords;
        }

        // Tentativa 4: somente cidade + UF (garante que sempre há resultado)
        coords = buscarNominatimCidade(cidadeNorm, estadoNorm);
        if (coords != null) {
            log.warn("Nominatim: endereco especifico nao encontrado, usando centro da cidade {}/{}", cidadeNorm, estadoNorm);
            return coords;
        }

        throw new RuntimeException(
                "Nao foi possivel determinar a localizacao para o endereço informado. " + "Verifique o CEP e o logradouro.");
    }

    public double calcularDistanciaKm(double lat1, double lon1, double lat2, double lon2) {
        final double RAIO_TERRA_KM = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return RAIO_TERRA_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
    private double[] buscarNominatim(String rua, String bairro, String cidade, String estado) {
        try {
            UriComponentsBuilder builder = UriComponentsBuilder.newInstance()
                    .scheme("https")
                    .host("nominatim.openstreetmap.org")
                    .path("/search")
                    .queryParam("format", "json")
                    .queryParam("limit", "1")
                    .queryParam("countrycodes", "br")
                    .queryParam("addressdetails", "0");

            String street = rua.isBlank() ? "" : rua;
            if (!street.isBlank()) builder.queryParam("street", street);
            if (!bairro.isBlank()) builder.queryParam("county", bairro);
            builder.queryParam("city",  cidade);
            builder.queryParam("state", estadoParaNome(estado));
            builder.queryParam("country", "Brazil");

            URI uri = builder.build().encode().toUri();
            return executarRequisicaoNominatim(uri);
        } catch (Exception e) {
            log.debug("Nominatim erro para rua='{}', cidade='{}': {}", rua, cidade, e.getMessage());
            return null;
        }
    }


    private double[] buscarNominatimCidade(String cidade, String estado) {
        try {
            URI uri = UriComponentsBuilder.newInstance()
                    .scheme("https")
                    .host("nominatim.openstreetmap.org")
                    .path("/search")
                    .queryParam("format", "json")
                    .queryParam("limit", "1")
                    .queryParam("countrycodes", "br")
                    .queryParam("city",  cidade)
                    .queryParam("state", estadoParaNome(estado))
                    .queryParam("country", "Brazil")
                    .build().encode().toUri();

            return executarRequisicaoNominatim(uri);
        } catch (Exception e) {
            log.debug("Nominatim erro para cidade='{}': {}", cidade, e.getMessage());
            return null;
        }
    }

    private double[] executarRequisicaoNominatim(URI uri) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("User-Agent", USER_AGENT);
        headers.setAccept(java.util.List.of(MediaType.APPLICATION_JSON));

        ResponseEntity<NominatimResponseDTO[]> response = restTemplate.exchange(
                uri, HttpMethod.GET,
                new HttpEntity<>(headers),
                NominatimResponseDTO[].class
        );

        NominatimResponseDTO[] resultados = response.getBody();
        if (resultados != null && resultados.length > 0) {
            NominatimResponseDTO r = resultados[0];
            return new double[]{Double.parseDouble(r.lat()), Double.parseDouble(r.lon())};
        }
        return null;
    }


    private String estadoParaNome(String uf) {
        return switch (uf.toUpperCase()) {
            case "AC" -> "Acre";
            case "AL" -> "Alagoas";
            case "AP" -> "Amapa";
            case "AM" -> "Amazonas";
            case "BA" -> "Bahia";
            case "CE" -> "Ceara";
            case "DF" -> "Distrito Federal";
            case "ES" -> "Espirito Santo";
            case "GO" -> "Goias";
            case "MA" -> "Maranhao";
            case "MT" -> "Mato Grosso";
            case "MS" -> "Mato Grosso do Sul";
            case "MG" -> "Minas Gerais";
            case "PA" -> "Para";
            case "PB" -> "Paraiba";
            case "PR" -> "Parana";
            case "PE" -> "Pernambuco";
            case "PI" -> "Piaui";
            case "RJ" -> "Rio de Janeiro";
            case "RN" -> "Rio Grande do Norte";
            case "RS" -> "Rio Grande do Sul";
            case "RO" -> "Rondonia";
            case "RR" -> "Roraima";
            case "SC" -> "Santa Catarina";
            case "SP" -> "Sao Paulo";
            case "SE" -> "Sergipe";
            case "TO" -> "Tocantins";
            default   -> uf;
        };
    }
}
