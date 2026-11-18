package Backend.BeachUp.Model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "times")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class TimesModel {

    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)

    private Long id;

    @Column(length = 50, nullable = false)
    private String nome;

    @Column(length = 50)
    private String descricao;

    @Column(name = "url_convite", unique = true)
    private String urlConvite;

    @ManyToOne
    @JoinColumn(name = "jogador_id", nullable = false) //jogador dono do time
    private JogadorModel jogador;

    @OneToMany(mappedBy = "time", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<MembroTimeModel> membros;
}
