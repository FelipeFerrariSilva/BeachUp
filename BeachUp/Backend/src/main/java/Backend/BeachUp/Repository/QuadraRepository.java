package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.QuadraModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuadraRepository extends JpaRepository<QuadraModel, Long> {

    // Conta quantas quadras a empresa tem no total (somando todas as arenas)
    @Query("""
        SELECT COUNT(q) FROM QuadraModel q
        WHERE q.arenas.empresa.id = :empresaId
    """)
    int countByEmpresaId(@Param("empresaId") Long empresaId);

    // Busca quadras de uma arena específica
    List<QuadraModel> findByArenasId(Long arenaId);
}