package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.JogadorAtualizadoDTO;
import Backend.BeachUp.DTO.JogadorCadastroDTO;
import Backend.BeachUp.DTO.JogadorResponseDTO;
import Backend.BeachUp.DTO.UsuarioDTO;
import Backend.BeachUp.Model.ENUMS.Role;
import Backend.BeachUp.Factory.UsuarioFactory;
import Backend.BeachUp.Model.JogadorModel;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.JogadorRepository;
import Backend.BeachUp.Repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class JogadorService {

    @Autowired
    private JogadorRepository repository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private UsuarioFactory usuarioFactory;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private TokenService tokenService;

    public JogadorResponseDTO create(JogadorCadastroDTO dto) {

        if (!dto.getSenha().equals(dto.getConfirmarSenha())) {
            throw new RuntimeException("Senha inválida");
        }

        if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new RuntimeException("Email já cadastrado");
        }

        Usuario usuario = usuarioFactory.criarUsuario(
                dto.getNome(),
                dto.getEmail(),
                dto.getSenha(),
                Role.ROLE_JOGADOR
        );

        JogadorModel jogador = new JogadorModel();
        jogador.setCpf(dto.getCpf());
        jogador.setUsuario(usuario);

        JogadorModel salvo = repository.save(jogador);

        return new JogadorResponseDTO(
                salvo.getId(),
                salvo.getCpf(),
                new UsuarioDTO(
                        salvo.getUsuario().getNome(),
                        salvo.getUsuario().getEmail(),
                        salvo.getUsuario().getRole().name(),
                        salvo.getUsuario().getFotoUrl()
                )
        );
    }

    public List<JogadorResponseDTO> getAll() {
        return repository.findAll()
                .stream()
                .map(j -> new JogadorResponseDTO(j.getId(), j.getCpf(),
                        new UsuarioDTO(
                                j.getUsuario().getNome(),
                                j.getUsuario().getEmail(),
                                j.getUsuario().getRole().name(),
                                j.getUsuario().getFotoUrl()
                        )))
                .collect(Collectors.toList());
    }

    public JogadorResponseDTO getById(Long id) {

        JogadorModel jogador = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        return new JogadorResponseDTO(jogador.getId(), jogador.getCpf(),
                new UsuarioDTO(
                        jogador.getUsuario().getNome(),
                        jogador.getUsuario().getEmail(),
                        jogador.getUsuario().getRole().name(),
                        jogador.getUsuario().getFotoUrl()
                ));
    }

    public void deleteById(Long id, Usuario usuarioLogado) {

        JogadorModel jogador = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        if (!jogador.getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        repository.delete(jogador);
    }

    public JogadorResponseDTO getMe(Usuario usuarioLogado) {
        JogadorModel jogador = repository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        return new JogadorResponseDTO(
                jogador.getId(),
                jogador.getCpf(),
                new UsuarioDTO(
                        jogador.getUsuario().getNome(),
                        jogador.getUsuario().getEmail(),
                        jogador.getUsuario().getRole().name(),
                        jogador.getUsuario().getFotoUrl()
                )
        );
    }

    public JogadorAtualizadoDTO putById(Long id, JogadorCadastroDTO dto, Usuario usuarioLogado, MultipartFile foto) {

        JogadorModel jogador = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Jogador não encontrado"));

        if (!jogador.getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        Usuario usuario = jogador.getUsuario();
        boolean emailAlterado = false;

        if (dto.getNome() != null) {
            usuario.setNome(dto.getNome());
        }

        if (dto.getEmail() != null && !dto.getEmail().equals(usuario.getEmail())) {
            usuarioRepository.findByEmail(dto.getEmail())
                    .filter(u -> !u.getId().equals(usuario.getId()))
                    .ifPresent(u -> {
                        throw new RuntimeException("Email já cadastrado");
                    });

            usuario.setEmail(dto.getEmail());
            emailAlterado = true;
        }

        if (dto.getSenha() != null) {
            if (!dto.getSenha().equals(dto.getConfirmarSenha())) {
                throw new RuntimeException("Senhas não coincidem");
            }
            usuario.setSenha(passwordEncoder.encode(dto.getSenha()));
        }

        if (dto.getCpf() != null) {
            jogador.setCpf(dto.getCpf());
        }

        if (foto != null && !foto.isEmpty()) {
            String tipo = foto.getContentType();
            if (tipo == null || !tipo.startsWith("image/")) {
                throw new RuntimeException("O arquivo enviado precisa ser uma imagem.");
            }

            String fotoAntiga = usuario.getFotoUrl();
            usuario.setFotoUrl(fileStorageService.salvar(foto, "usuarios"));

            if (fotoAntiga != null) {
                fileStorageService.remover(fotoAntiga);
            }
        }

        // Se o email mudou, gera novos tokens para evitar que o usuário seja deslogado
        String novoAccessToken  = null;
        String novoRefreshToken = null;

        if (emailAlterado) {
            String sessionId = UUID.randomUUID().toString();
            usuario.setCurrentSessionId(sessionId);
            novoAccessToken  = tokenService.generateToken(usuario, sessionId);
            novoRefreshToken = tokenService.generateRefreshToken(usuario);
            usuario.setRefreshToken(novoRefreshToken);
        }

        JogadorModel atualizado = repository.save(jogador);

        return new JogadorAtualizadoDTO(
                atualizado.getId(),
                atualizado.getCpf(),
                new UsuarioDTO(
                        atualizado.getUsuario().getNome(),
                        atualizado.getUsuario().getEmail(),
                        atualizado.getUsuario().getRole().name(),
                        atualizado.getUsuario().getFotoUrl()
                ),
                novoAccessToken,
                novoRefreshToken
        );
    }
}