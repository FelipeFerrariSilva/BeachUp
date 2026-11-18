package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.*;
import Backend.BeachUp.Model.ArenaModel;
import Backend.BeachUp.Model.EnderecoModel;
import Backend.BeachUp.Model.Empresa;
import Backend.BeachUp.Model.FotoModel;
import Backend.BeachUp.Model.ENUMS.TipoPlano;
import Backend.BeachUp.Model.Usuario;
import Backend.BeachUp.Repository.ArenaRepository;
import Backend.BeachUp.Repository.AssinaturaEmpresaRepository;
import Backend.BeachUp.Repository.EmpresaRepository;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@AllArgsConstructor
public class ArenaService {

    private final ArenaRepository arenaRepository;
    private final EmpresaRepository empresaRepository;
    private final AssinaturaEmpresaRepository assinaturaRepository;
    private final GeocodingService geocodingService;
    private final FileStorageService fileStorageService;

    public ArenaResponseDTO create(ArenaCadastroDTO dto, Usuario usuarioLogado, MultipartFile foto) {

        Empresa empresa = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));

        EnderecoDTO endDto = dto.getEndereco();

        double[] coordenadas = geocodingService.geocodificar(
                endDto.getLogradouro(), endDto.getNumero(),
                endDto.getCidade(), endDto.getEstado(), endDto.getCep()
        );

        EnderecoModel endereco = EnderecoModel.builder()
                .logradouro(endDto.getLogradouro())
                .numero(endDto.getNumero())
                .bairro(endDto.getBairro())
                .cidade(endDto.getCidade())
                .estado(endDto.getEstado())
                .cep(endDto.getCep())
                .latitude(coordenadas[0])
                .longitude(coordenadas[1])
                .build();

        ArenaModel arena = ArenaModel.builder()
                .nome(dto.getNome())
                .descricao(dto.getDescricao())
                .endereco(endereco)
                .empresa(empresa)
                .foto(new ArrayList<>())
                .build();

        String urlFoto = fileStorageService.salvar(foto, "arenas");
        if (urlFoto != null) {
            FotoModel fotoModel = FotoModel.builder()
                    .url(urlFoto)
                    .arenas(arena)
                    .build();
            arena.getFoto().add(fotoModel);
        }

        return toResponse(arenaRepository.save(arena), null);
    }

    public List<ArenaResponseDTO> buscarPorProximidade(LocalizacaoDTO localizacao) {

        double latUsuario = localizacao.getLatitude();
        double lonUsuario = localizacao.getLongitude();
        double raioKm = localizacao.getRaioKm();

        return arenaRepository.findAll().stream()
                .filter(a -> a.getEndereco() != null
                        && a.getEndereco().getLatitude() != null
                        && a.getEndereco().getLongitude() != null)
                .map(arena -> {
                    double dist = geocodingService.calcularDistanciaKm(
                            latUsuario, lonUsuario,
                            arena.getEndereco().getLatitude(),
                            arena.getEndereco().getLongitude()
                    );
                    return toResponse(arena, dist);
                })
                .filter(dto -> dto.getDistanciaKm() <= raioKm)
                .sorted(Comparator.comparingDouble(ArenaResponseDTO::getDistanciaKm))
                .toList();
    }

    public ArenaResponseDTO getById(Long id) {
        return toResponse(arenaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada")), null);
    }

    public List<ArenaResponseDTO> getAll() {
        return arenaRepository.findAll().stream()
                .map(a -> toResponse(a, null))
                .toList();
    }

    public ArenaResponseDTO update(Long id, ArenaCadastroDTO dto, Usuario usuarioLogado, MultipartFile foto) {
        ArenaModel arena = arenaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada"));

        if (!arena.getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        if (dto.getNome() != null) arena.setNome(dto.getNome());
        if (dto.getDescricao() != null) arena.setDescricao(dto.getDescricao());

        if (dto.getEndereco() != null) {
            EnderecoDTO endDto = dto.getEndereco();
            double[] coordenadas = geocodingService.geocodificar(
                    endDto.getLogradouro(), endDto.getNumero(),
                    endDto.getCidade(), endDto.getEstado(), endDto.getCep()
            );

            EnderecoModel endereco = EnderecoModel.builder()
                    .logradouro(endDto.getLogradouro())
                    .numero(endDto.getNumero())
                    .bairro(endDto.getBairro())
                    .cidade(endDto.getCidade())
                    .estado(endDto.getEstado())
                    .cep(endDto.getCep())
                    .latitude(coordenadas[0])
                    .longitude(coordenadas[1])
                    .build();

            arena.setEndereco(endereco);
        }

        if (foto != null && !foto.isEmpty()) {
            if (arena.getFoto() != null) {
                arena.getFoto().forEach(f -> fileStorageService.remover(f.getUrl()));
                arena.getFoto().clear();
            } else {
                arena.setFoto(new ArrayList<>());
            }

            String urlFoto = fileStorageService.salvar(foto, "arenas");
            FotoModel fotoModel = FotoModel.builder()
                    .url(urlFoto)
                    .arenas(arena)
                    .build();
            arena.getFoto().add(fotoModel);
        }

        return toResponse(arenaRepository.save(arena), null);
    }

    public void delete(Long id, Usuario usuarioLogado) {
        ArenaModel arena = arenaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Arena não encontrada"));

        if (!arena.getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado!");
        }

        arenaRepository.delete(arena);
    }

    public List<ArenaResponseDTO> getByEmpresa(Usuario usuarioLogado) {
        Empresa empresa = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa não encontrada"));

        return arenaRepository.findByEmpresaId(empresa.getId())
                .stream()
                .map(a -> toResponse(a, null))
                .toList();
    }

    public ArenaResponseDTO converterParaDTO(ArenaModel arena) {
        return toResponse(arena, null);
    }

    private ArenaResponseDTO toResponse(ArenaModel arena, Double distanciaKm) {
        Empresa empresa = arena.getEmpresa();

        UsuarioDTO usuarioDTO = new UsuarioDTO(
                empresa.getUsuario().getNome(),
                empresa.getUsuario().getEmail(),
                empresa.getUsuario().getRole().name(),
                empresa.getUsuario().getFotoUrl()
        );

        EmpresaResponseDTO empresaDTO = new EmpresaResponseDTO(
                empresa.getId(),
                empresa.getCnpj(),
                assinaturaRepository.findByEmpresaId(empresa.getId())
                        .map(a -> a.getPlano().getTipo())
                        .orElse(TipoPlano.GRATUITO),
                usuarioDTO
        );

        EnderecoDTO enderecoDTO = null;
        Double lat = null, lon = null;

        if (arena.getEndereco() != null) {
            EnderecoModel e = arena.getEndereco();
            enderecoDTO = new EnderecoDTO();
            enderecoDTO.setLogradouro(e.getLogradouro());
            enderecoDTO.setNumero(e.getNumero());
            enderecoDTO.setBairro(e.getBairro());
            enderecoDTO.setCidade(e.getCidade());
            enderecoDTO.setEstado(e.getEstado());
            enderecoDTO.setCep(e.getCep());
            lat = e.getLatitude();
            lon = e.getLongitude();
        }

        String fotoUrl = null;
        if (arena.getFoto() != null && !arena.getFoto().isEmpty()) {
            fotoUrl = arena.getFoto().get(0).getUrl();
        }

        return new ArenaResponseDTO(arena.getId(), arena.getNome(), arena.getDescricao(), enderecoDTO, lat, lon, distanciaKm, empresaDTO, fotoUrl);
    }
}