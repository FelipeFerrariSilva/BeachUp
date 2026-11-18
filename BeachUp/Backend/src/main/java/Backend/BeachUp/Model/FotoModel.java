package Backend.BeachUp.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "fotos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(of = "id")

public class FotoModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 255)
    private String url;

    @ManyToOne
    @JoinColumn(name = "arenas_id")
    @JsonIgnoreProperties("foto")
    private ArenaModel arenas;

    // Nullable: preenchido quando a foto pertence a uma quadra
    @ManyToOne
    @JoinColumn(name = "quadra_id")
    @JsonIgnoreProperties("fotos")
    private QuadraModel quadra;
}