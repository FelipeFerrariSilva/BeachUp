package Backend.BeachUp.Model;

import Backend.BeachUp.Model.ENUMS.StatusAssinatura;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "assinatura_empresa")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class AssinaturaEmpresaModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "empresa_id", nullable = false)
    private Empresa empresa;

    @ManyToOne
    @JoinColumn(name = "plano_id", nullable = false)
    private PlanoModel plano;

    @Column(name = "data_inicio", nullable = false)
    private LocalDateTime dataInicio;


    @Column(name = "data_fim")
    private LocalDateTime dataFim;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusAssinatura status;

    @Column(name = "renovacao_automatica")
    private Boolean renovacaoAutomatica;

    @Column(name = "mp_payment_id")
    private String mpPaymentId;


    public boolean isBasicoAtivo() {
        return plano.getTipo() == TipoPlano.BASICO
                && status == StatusAssinatura.ATIVA
                && (dataFim == null || dataFim.isAfter(LocalDateTime.now()));
    }


    public boolean isGoldAtivo() {
        return plano.getTipo() == TipoPlano.GOLD
                && status == StatusAssinatura.ATIVA
                && (dataFim == null || dataFim.isAfter(LocalDateTime.now()));
    }

        public boolean isPagoAtivo () {
            return isBasicoAtivo() || isGoldAtivo();
        }


        public boolean isPremiumAtivo () {
            return isPagoAtivo();
        }

        public boolean isGratuito () {
            return plano.getTipo() == TipoPlano.GRATUITO;
        }

    public double getTaxaBeachUp() {
        return switch (plano.getTipo()) {
            case GRATUITO -> 0.03;
            case BASICO   -> 0.01;
            case GOLD     -> 0.00;
        };
    }
}
