package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.QuadraCadastroDTO;
import Backend.BeachUp.DTO.QuadraResponseDTO;
import Backend.BeachUp.Model.*;
import Backend.BeachUp.Repository.ArenaRepository;
import Backend.BeachUp.Repository.EmpresaRepository;
import Backend.BeachUp.Repository.FotoRepository;
import Backend.BeachUp.Repository.QuadraRepository;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
@AllArgsConstructor
public class QuadraService {

    private final QuadraRepository quadraRepository;
    private final ArenaRepository arenaRepository;
    private final EmpresaRepository empresaRepository;
    private final PlanoService planoService;
    private final FotoRepository fotoRepository;
    private final FileStorageService fileStorageService;

    public QuadraResponseDTO converterParaDTO(QuadraModel quadra) {
        List<String> urls = quadra.getFotos() == null ? List.of()
                : quadra.getFotos().stream().map(FotoModel::getUrl).toList();
        return new QuadraResponseDTO(
                quadra.getId(),
                quadra.getNome(),
                quadra.getTipoCobertura(),
                quadra.getValorHora(),
                urls
        );
    }

    public QuadraResponseDTO create(Long arenaId, QuadraCadastroDTO dto, Usuario usuarioLogado) {
        ArenaModel arena = arenaRepository.findById(arenaId)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada"));

        if (!arena.getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        Empresa empresa = arena.getEmpresa();

        int totalQuadras = quadraRepository.countByEmpresaId(empresa.getId());
        planoService.validarLimiteQuadras(empresa, totalQuadras);

        QuadraModel quadra = QuadraModel.builder()
                .nome(dto.getNome())
                .tipoCobertura(dto.getTipoCobertura())
                .valorHora(dto.getValorHora())
                .arenas(arena)
                .build();

        return converterParaDTO(quadraRepository.save(quadra));
    }
    //
    public QuadraResponseDTO adicionarFotos(Long quadraId, List<MultipartFile> arquivos, Usuario usuarioLogado) {
        QuadraModel quadra = quadraRepository.findById(quadraId)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        if (!quadra.getArenas().getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        for (MultipartFile arquivo : arquivos) {
            String url = fileStorageService.salvar(arquivo, "quadras");
            if (url != null) {
                FotoModel foto = FotoModel.builder()
                        .url(url)
                        .quadra(quadra)
                        .build();
                fotoRepository.save(foto);
            }
        }

        // Recarrega para incluir as novas fotos
        QuadraModel atualizada = quadraRepository.findById(quadraId).orElseThrow();
        return converterParaDTO(atualizada);
    }

    public void removerFoto(Long quadraId, Long fotoId, Usuario usuarioLogado) {
        QuadraModel quadra = quadraRepository.findById(quadraId)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        if (!quadra.getArenas().getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        FotoModel foto = fotoRepository.findById(fotoId)
                .orElseThrow(() -> new RuntimeException("Foto não encontrada"));

        if (!foto.getQuadra().getId().equals(quadraId)) {
            throw new RuntimeException("Foto não pertence a esta quadra");
        }

        fileStorageService.remover(foto.getUrl());
        fotoRepository.delete(foto);
    }

    public QuadraResponseDTO getById(Long id) {
        return converterParaDTO(quadraRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada")));
    }

    public List<QuadraResponseDTO> getAll() {
        return quadraRepository.findAll().stream().map(this::converterParaDTO).toList();
    }

    public List<QuadraResponseDTO> getByArena(Long arenaId) {
        return quadraRepository.findByArenasId(arenaId)
                .stream()
                .map(this::converterParaDTO)
                .toList();
    }

    public QuadraResponseDTO update(Long id, QuadraCadastroDTO dto, Usuario usuarioLogado) {
        QuadraModel quadra = quadraRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        if (!quadra.getArenas().getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        if (dto.getNome() != null) quadra.setNome(dto.getNome());
        if (dto.getTipoCobertura() != null) quadra.setTipoCobertura(dto.getTipoCobertura());
        if (dto.getValorHora() != null) quadra.setValorHora(dto.getValorHora());

        return converterParaDTO(quadraRepository.save(quadra));
    }

    public void delete(Long id, Usuario usuarioLogado) {
        QuadraModel quadra = quadraRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Quadra não encontrada"));

        if (!quadra.getArenas().getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }
        quadraRepository.delete(quadra);
    }

}