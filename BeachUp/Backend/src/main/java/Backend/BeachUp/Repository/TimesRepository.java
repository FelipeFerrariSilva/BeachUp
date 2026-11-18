package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.TimesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TimesRepository extends JpaRepository<TimesModel, Long> {
    Optional<TimesModel> findByUrlConvite(String urlConvite);

}
