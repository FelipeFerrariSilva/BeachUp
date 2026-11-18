package Backend.BeachUp.DTO;

public record CheckoutProResponseDTO(
        String preferenceId,  // ID da preferência criada no MP
        String initPoint,     // URL de pagamento (redirecionar o usuário)
        String sandboxInitPoint // URL teste
) {
}
