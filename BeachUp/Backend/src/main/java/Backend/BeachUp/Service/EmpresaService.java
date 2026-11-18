package Backend.BeachUp.Service;


import Backend.BeachUp.DTO.EmpresaAtualizadaDTO;
import Backend.BeachUp.DTO.EmpresaCadastroDTO;
import Backend.BeachUp.DTO.EmpresaResponseDTO;
import Backend.BeachUp.DTO.UsuarioDTO;
import Backend.BeachUp.Model.ENUMS.Role;
import Backend.BeachUp.Factory.UsuarioFactory;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.Empresa;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.AssinaturaEmpresaRepository;
import Backend.BeachUp.Repository.EmpresaRepository;
import Backend.BeachUp.Repository.UsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class EmpresaService {

    private final EmpresaRepository repository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioFactory usuarioFactory;
    private final PlanoService planoService;
    private final AssinaturaEmpresaRepository assinaturaRepository;
    private final CnpjService cnpjService;
    private final FileStorageService fileStorageService;
    private final TokenService tokenService;

    @Transactional
    public EmpresaResponseDTO create(EmpresaCadastroDTO dto) {

        if (!dto.getSenha().equals(dto.getConfirmarSenha())) {
            throw new RuntimeException("Senha inválida");
        }

        if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new RuntimeException("Email já cadastrado");
        }

        if (repository.findByCnpj(dto.getCnpj()).isPresent()){
            throw new RuntimeException("Email já cadastrado");
        }

        cnpjService.validarCnpjAtivo(dto.getCnpj());

        Usuario usuario = usuarioFactory.criarUsuario(
                dto.getNome(),
                dto.getEmail(),
                dto.getSenha(),
                Role.ROLE_EMPRESA
        );

        Empresa empresa = Empresa.builder()
                .cnpj(dto.getCnpj())
                .usuario(usuario)
                .build();

        Empresa salvo = repository.save(empresa);

        // Atribui plano gratuito automaticamente ao cadastrar
        planoService.atribuirPlanoGratuito(salvo);

        return toResponse(salvo);
    }

    public List<EmpresaResponseDTO> getAll() {
        return repository.findAll().stream().map(this::toResponse).toList();
    }

    public EmpresaResponseDTO getById(Long id) {
        return toResponse(repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada")));
    }

    public EmpresaResponseDTO getMe(Usuario usuarioLogado) {
        Empresa empresa = repository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));
        return toResponse(empresa);
    }

    @Transactional
    public void deleteById(Long id, Usuario usuarioLogado) {
        Empresa empresa = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));

        if (!empresa.getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        repository.delete(empresa);
    }

    @Transactional
    public EmpresaAtualizadaDTO putById(Long id, EmpresaCadastroDTO dto, Usuario usuarioLogado, MultipartFile foto) {
        Empresa empresa = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));

        if (!empresa.getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        Usuario usuario = empresa.getUsuario();
        boolean emailAlterado = false;

        if (dto.getNome() != null) usuario.setNome(dto.getNome());

        if (dto.getEmail() != null && !dto.getEmail().equals(usuario.getEmail())) {
            usuarioRepository.findByEmail(dto.getEmail())
                    .filter(u -> !u.getId().equals(usuario.getId()))
                    .ifPresent(u -> { throw new RuntimeException("Email já cadastrado"); });
            usuario.setEmail(dto.getEmail());
            emailAlterado = true;
        }

        if (dto.getSenha() != null) {
            if (!dto.getSenha().equals(dto.getConfirmarSenha())) {
                throw new RuntimeException("Senhas não coincidem");
            }
            usuario.setSenha(passwordEncoder.encode(dto.getSenha()));
        }

        if (dto.getCnpj() != null) empresa.setCnpj(dto.getCnpj());

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

        Empresa atualizada = repository.save(empresa);
        EmpresaResponseDTO dados = toResponse(atualizada);

        return new EmpresaAtualizadaDTO(
                dados.getId(),
                dados.getCnpj(),
                dados.getPlanoAtual(),
                dados.getUsuario(),
                novoAccessToken,
                novoRefreshToken
        );
    }

    private EmpresaResponseDTO toResponse(Empresa e) {
        TipoPlano plano = assinaturaRepository.findByEmpresaId(e.getId())
                .map(a -> a.getPlano().getTipo())
                .orElse(TipoPlano.GRATUITO);

        return new EmpresaResponseDTO(e.getId(), e.getCnpj(), plano,
                new UsuarioDTO(
                        e.getUsuario().getNome(),
                        e.getUsuario().getEmail(),
                        e.getUsuario().getRole().name(),
                        e.getUsuario().getFotoUrl()
                ));
    }
}