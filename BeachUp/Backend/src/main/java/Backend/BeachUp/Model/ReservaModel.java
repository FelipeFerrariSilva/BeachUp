package Backend.BeachUp.Model;


import Backend.BeachUp.Model.ENUMS.StatusReserva;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reserva")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")
public class ReservaModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    @Column(name = "data_hora_inicio", nullable = false)
    private LocalDateTime dataHoraInicio;

    @Column(name = "data_hora_fim", nullable = false)
    private LocalDateTime dataHoraFim;

    @Column(name = "valor_total", nullable = false, precision = 8, scale = 2)
    private BigDecimal valorTotal;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusReserva status;

    @Column(name = "mp_payment_id")
    private String mpPaymentId;

    @Column(name = "mp_payment_status") // status do pagamento ( pendente, aprovado, recusado
    private String mpPaymentStatus;

    // Controle de email de avaliação: evita reenvio
    @Column(name = "email_avaliacao_enviado", nullable = false)
    @Builder.Default
    private boolean emailAvaliacaoEnviado = false;

    @ManyToOne
    @JoinColumn(name = "jogador_id", nullable = false)
    private JogadorModel jogador;

    @ManyToOne
    @JoinColumn(name = "quadra_id", nullable = false)
    private QuadraModel quadra;
}
