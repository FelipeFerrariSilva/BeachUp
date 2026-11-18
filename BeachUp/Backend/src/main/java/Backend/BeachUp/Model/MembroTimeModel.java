package Backend.BeachUp.Model;

import Backend.BeachUp.Model.ENUMS.StatusMembroTime;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "membro_time")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class MembroTimeModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusMembroTime status;

    @ManyToOne
    @JoinColumn(name = "time_id", nullable = false)
    private TimesModel time;

    @ManyToOne
    @JoinColumn(name = "jogador_id", nullable = false)
    private JogadorModel jogador;


}
