package Backend.BeachUp.Model;


import Backend.BeachUp.Model.ENUMS.StatusCampeonato;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name = "campeonato")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class CampeonatoModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    @Column(length = 50, nullable = false)
    private String nome;

    @Column(length = 70)
    private String descricao;

    @Column(length = 20)
    private String categoria;

    private LocalDate dataInicio;
    private LocalDate dataFim;

    @Column(name = "token_inscricao", unique = true)
    private String tokenInscricao;

    @Column(name = "taxa_inscricao", precision = 8, scale = 2)
    private BigDecimal taxaInscricao;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusCampeonato status;

    @ManyToOne
    @JoinColumn(name = "empresa_id", nullable = false)
    private Empresa empresa;


    @ManyToOne
    @JoinColumn(name = "arena_id")
    private ArenaModel arenas;


    @ManyToOne
    @JoinColumn(name = "time_vencedor_id")
    private TimesModel timeVencedor;

    @OneToMany(mappedBy = "campeonato", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<InscricaoCampeonatoModel> inscricoes;

    @OneToMany(mappedBy = "campeonato", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<PartidaModel> partidas;
}
