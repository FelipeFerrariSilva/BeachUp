package Backend.BeachUp.Repository;

import Backend.BeachUp.Model.PasswordResetTokenModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetTokenModel, Long> {

    Optional<PasswordResetTokenModel> findByToken(String token);

    @Modifying // Remove tokens antigos do usuario que solicita o esqueceu senha
    @Query("DELETE FROM PasswordResetTokenModel t WHERE t.usuario.id = :usuarioId")
    void deleteByUsuarioId(Long usuarioId);

    // Limpeza periódica de tokens expirados
    @Modifying
    @Query("DELETE FROM PasswordResetTokenModel t WHERE t.expiraEm < :agora")
    void deleteExpirados(LocalDateTime agora);

}
