package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.ENUMS.StatusMembroTime;
import Backend.BeachUp.Model.JogadorModel;
import Backend.BeachUp.Model.MembroTimeModel;
import Backend.BeachUp.Model.TimesModel;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MembroTimeRepository extends JpaRepository<MembroTimeModel, Long> {
    List<MembroTimeModel> findByTime(TimesModel time);
    List<MembroTimeModel> findByTimeAndStatus(TimesModel time, StatusMembroTime status);
    Optional<MembroTimeModel> findByTimeAndJogador(TimesModel time, JogadorModel jogador);
    int countByTimeAndStatus(TimesModel time, StatusMembroTime status);
}
