package Backend.BeachUp.DTO;

import com.fasterxml.jackson.annotation.JsonProperty;

public record CnpjResponseDTO(
        @JsonProperty("status")
        String status, // "OK" ou "ERROR"

        @JsonProperty("situacao")
        String situacao, // "ATIVA", "BAIXADA", "SUSPENSA"

        @JsonProperty("nome")
        String nome,

        @JsonProperty("fantasia")
        String fantasia,

        @JsonProperty("cnpj")
        String cnpj,

        @JsonProperty("message")
        String message // preenche quando status for = "ERROR"
) {
}
