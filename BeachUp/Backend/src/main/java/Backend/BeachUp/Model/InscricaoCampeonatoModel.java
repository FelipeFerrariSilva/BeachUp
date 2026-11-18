package Backend.BeachUp.Model;


import Backend.BeachUp.Model.ENUMS.StatusInscricao;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "inscricao_campeonato",
        uniqueConstraints = @UniqueConstraint(columnNames = {"campeonato_id", "time_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode( of = "id")
public class InscricaoCampeonatoModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    @Column(name = "data_inscricao", nullable = false)
    private Instant dataInscricao;

    @ManyToOne
    @JoinColumn(name = "campeonato_id",nullable = false)
    private CampeonatoModel campeonato;

    @ManyToOne
    @JoinColumn(name = "time_id", nullable = false)
    private TimesModel time;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusInscricao status;

    @Column(name = "mp_payment_id")
    private String mpPaymentId;

    @Column(name = "mp_payment_status")
    private String mpPaymentStatus;
}
