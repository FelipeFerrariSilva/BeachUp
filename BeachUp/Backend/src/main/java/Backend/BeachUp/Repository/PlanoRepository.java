package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.PlanoModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PlanoRepository extends JpaRepository<PlanoModel, Long> {
    Optional<PlanoModel> findByTipo(TipoPlano tipo);
}
