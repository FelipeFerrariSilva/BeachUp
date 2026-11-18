package Backend.BeachUp.DTO;

import Backend.BeachUp.Model.ENUMS.StatusMembroTime;

import java.util.List;

public record TimesResponseDTO(
        Long id,
        String nome,
        String descricao,
        String urlConvite,
        Long idJogadorDono,
        List<MembroResponseDTO> membros
) {
    public record MembroResponseDTO(Long idJogador, String nomeUsuario, StatusMembroTime status) {}
}
