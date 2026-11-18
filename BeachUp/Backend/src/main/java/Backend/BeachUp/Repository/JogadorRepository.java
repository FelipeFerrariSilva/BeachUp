package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.JogadorModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface JogadorRepository extends JpaRepository<JogadorModel, Long> {
    Optional<JogadorModel> findByUsuarioId(Long usuarioId);
}
