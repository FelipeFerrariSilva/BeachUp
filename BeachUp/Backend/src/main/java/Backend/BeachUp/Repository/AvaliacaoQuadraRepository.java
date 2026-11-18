package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.AvaliacaoQuadraModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AvaliacaoQuadraRepository extends JpaRepository<AvaliacaoQuadraModel, Long> {
    Optional<AvaliacaoQuadraModel> findByReservaId(Long reservaId);

    boolean existsByReservaId(Long reservaId);

    List<AvaliacaoQuadraModel> findByQuadraId(Long quadraId);

    @Query("SELECT AVG(a.nota) FROM AvaliacaoQuadraModel a WHERE a.quadra.id = :quadraId")
    Double calcularMediaPorQuadra(Long quadraId);

    @Query("SELECT COUNT(a) FROM AvaliacaoQuadraModel a WHERE a.quadra.id = :quadraId")
    Long contarPorQuadra(Long quadraId);
}
