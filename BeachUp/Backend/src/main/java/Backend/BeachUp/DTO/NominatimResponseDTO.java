package Backend.BeachUp.DTO;

import com.fasterxml.jackson.annotation.JsonProperty;

public record NominatimResponseDTO(

        @JsonProperty("lat")
        String lat,

        @JsonProperty("lon")
        String lon,

        @JsonProperty("display_name")
        String displayName
) {
}
