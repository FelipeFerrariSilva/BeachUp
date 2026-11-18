package Backend.BeachUp.Model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import lombok.*;
import org.hibernate.validator.constraints.br.CNPJ;

import java.util.List;

@Entity
@Table (name = "empresa")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)


    private Long id;

    @Column(unique = true, nullable = false)
    @CNPJ
    private String cnpj;
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    //OAuth mercado Pago Marketplace
    @Column(name = "mp_access_token", length = 500)
    private String mpAccessToken;

    @Column(name = "mp_refresh_token", length = 500)
    private String mpRefreshToken;

    @Column(name = "mp_user_id")
    private String mpUserId;

    public boolean temContaMpConectada(){
        return mpAccessToken != null && !mpAccessToken.isBlank();
    }

    @OneToMany(mappedBy = "empresa", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<ArenaModel> arenas;

    @OneToOne(mappedBy = "empresa", cascade = CascadeType.ALL)
    @JsonIgnore
    private AssinaturaEmpresaModel assinatura;
}
