package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.ArenaModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ArenaRepository extends JpaRepository<ArenaModel, Long> {
    List<ArenaModel> findByEmpresaId(Long empresaId);
}