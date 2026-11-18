package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.CampeonatoModel;
import Backend.BeachUp.Model.InscricaoCampeonatoModel;
import Backend.BeachUp.Model.TimesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InscricaoCampeonatoRepository extends JpaRepository<InscricaoCampeonatoModel, Long> {

    List<InscricaoCampeonatoModel> findByCampeonato(CampeonatoModel campeonato);
    Optional<InscricaoCampeonatoModel> findByCampeonatoAndTime(CampeonatoModel campeonato, TimesModel time);
    Optional<InscricaoCampeonatoModel> findByCampeonatoIdAndTimeId(Long campeonatoId, Long timeId);
    int countByCampeonato(CampeonatoModel campeonato);
    int countByCampeonatoAndStatus(CampeonatoModel campeonato, Backend.BeachUp.Model.ENUMS.StatusInscricao status);
}
