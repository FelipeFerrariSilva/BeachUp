package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.AssinaturaEmpresaModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface AssinaturaEmpresaRepository extends JpaRepository<AssinaturaEmpresaModel, Long> {

    Optional<AssinaturaEmpresaModel> findByEmpresaId(Long empresaId);
    Optional<AssinaturaEmpresaModel> findByMpPaymentId(String mpPaymentId);

    // Busca assinaturas BASICO ou GOLD que expiraram para rebaixar ao plano gratuito
    @Query("""
        SELECT a FROM AssinaturaEmpresaModel a
        WHERE a.plano.tipo IN ('BASICO', 'GOLD')
        AND a.status = 'ATIVA'
        AND a.dataFim < :agora
    """)
    List<AssinaturaEmpresaModel> findAssinaturasExpiradas(LocalDateTime agora);
}
