package Backend.BeachUp.DTO;


import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ArenaResponseDTO {
    private Long id;
    private String nome;
    private String descricao;
    private EnderecoDTO endereco;
    private Double latitute;
    private Double longitude;
    private Double distanciaKm;
    private EmpresaResponseDTO empresa;
    private String fotoUrl;
}
