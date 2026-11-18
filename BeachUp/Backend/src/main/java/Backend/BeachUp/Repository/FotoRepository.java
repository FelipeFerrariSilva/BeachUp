package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.FotoModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;


@Repository
public interface FotoRepository extends JpaRepository<FotoModel, Long> {
    List<FotoModel> findByQuadraId(Long quadraId);
    List<FotoModel> findByArenasId(Long arenaId);
}
