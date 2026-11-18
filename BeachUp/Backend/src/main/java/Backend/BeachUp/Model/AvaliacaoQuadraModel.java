package Backend.BeachUp.Model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "avaliacao_quadra",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_avaliacao_reserva",
                columnNames = "reserva_id"
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class AvaliacaoQuadraModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Min(1) @Max(5)
    @Column(nullable = false)
    private Integer nota;

    @Column(length = 500)
    private String comentario;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    @OneToOne
    @JoinColumn(name = "reserva_id", nullable = false, unique = true)
    private ReservaModel reserva;

    @ManyToOne
    @JoinColumn(name = "jogador_id", nullable = false)
    private JogadorModel jogador;

    @ManyToOne
    @JoinColumn(name = "quadra_id", nullable = false)
    private QuadraModel quadra;

    @PrePersist
    void prePersist() {
        criadoEm = LocalDateTime.now();
    }
}
