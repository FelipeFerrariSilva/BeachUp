package Backend.BeachUp.Model;

import Backend.BeachUp.Model.ENUMS.TipoPlano;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "plano")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class PlanoModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, unique = true)
    private TipoPlano tipo;

    @Column(nullable = false, length = 30)
    private String nome;

    @Column(length = 100)
    private String descricao;

    // null = ilimitado (PREMIUM), 2 = GRATUITO
    @Column(name = "limite_quadras")
    private Integer limiteQuadras;

    @Column(name = "valor_mensal", precision = 8, scale = 2)
    private BigDecimal valorMensal;
}
