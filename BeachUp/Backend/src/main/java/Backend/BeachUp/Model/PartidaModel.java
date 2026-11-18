package Backend.BeachUp.Model;

import Backend.BeachUp.Model.ENUMS.StatusPartida;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "partida")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class PartidaModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;


    @Column(length = 20) //"Quartas de final", "Semifinal", "Final"
    private String fase;


    private Integer rodada; // Número da rodada dentro da fase

    private Integer placarTimeCasa;
    private Integer placarTimeVisitante;

    private LocalDateTime dataHoraJogo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusPartida status;

    @ManyToOne
    @JoinColumn(name = "campeonato_id", nullable = false)
    private CampeonatoModel campeonato;

    @ManyToOne
    @JoinColumn(name = "time_casa_id")
    private TimesModel timeCasa;

    @ManyToOne
    @JoinColumn(name = "time_visitante_id")
    private TimesModel timeVisitante;

    @ManyToOne
    @JoinColumn(name = "time_vencedor_id")
    private TimesModel timeVencedor;

    @ManyToOne
    @JoinColumn(name = "quadra_id")
    private QuadraModel quadra;
}
