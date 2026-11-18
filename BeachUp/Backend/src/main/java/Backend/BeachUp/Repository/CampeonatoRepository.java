package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.CampeonatoModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CampeonatoRepository extends JpaRepository<CampeonatoModel, Long> {
    Optional<CampeonatoModel> findByTokenInscricao(String token);

    List<CampeonatoModel> findByEmpresaId(Long empresaId);

}
