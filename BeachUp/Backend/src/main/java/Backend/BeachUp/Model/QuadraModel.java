package Backend.BeachUp.Model;

import Backend.BeachUp.Model.ENUMS.TipoCobertura;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Entity
@Table(name = "quadra")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class QuadraModel {

    @Id
    @GeneratedValue( strategy = GenerationType.IDENTITY)

    private Long id;
    private String nome;

    @Enumerated(EnumType.STRING)
    private TipoCobertura tipoCobertura;

    @Column(name = "valor_hora", nullable = false, precision = 8, scale = 2)
    private BigDecimal valorHora;

    @ManyToOne
    @JoinColumn(name = "arena_id")
    @JsonIgnoreProperties("quadra")
    private ArenaModel arenas;

    @OneToMany(mappedBy = "quadra", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnoreProperties("quadra")
    private List<FotoModel> fotos;
}
