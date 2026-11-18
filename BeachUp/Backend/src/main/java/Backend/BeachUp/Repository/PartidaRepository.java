package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.CampeonatoModel;
import Backend.BeachUp.Model.ENUMS.StatusPartida;
import Backend.BeachUp.Model.PartidaModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PartidaRepository extends JpaRepository<PartidaModel, Long> {
    List<PartidaModel> findByCampeonato(CampeonatoModel campeonato);
    List<PartidaModel> findByCampeonatoAndFase(CampeonatoModel campeonato, String fase);
    int countByCampeonatoAndStatus(CampeonatoModel campeonato, StatusPartida status);
    int countByCampeonatoAndFase(CampeonatoModel campeonato, String fase);
}
