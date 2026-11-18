package Backend.BeachUp.Service;

import Backend.BeachUp.DTO.*;
import Backend.BeachUp.Model.*;
import Backend.BeachUp.Model.ENUMS.StatusCampeonato;
import Backend.BeachUp.Model.ENUMS.StatusInscricao;
import Backend.BeachUp.Model.ENUMS.StatusMembroTime;
import Backend.BeachUp.Model.ENUMS.StatusPartida;
import Backend.BeachUp.Repository.*;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;


@Service
@AllArgsConstructor
public class CampeonatoService {

    private final CampeonatoRepository campeonatoRepository;
    private final InscricaoCampeonatoRepository inscricaoRepository;
    private final PartidaRepository partidaRepository;
    private final EmpresaRepository empresaRepository;
    private final ArenaRepository arenaRepository;
    private final TimesRepository timesRepository;
    private final MembroTimeRepository membroTimeRepository;
    private final PlanoService planoService;

    private static final List<Integer> TAMANHHOS_VALIDOS = List.of(8,16);


    //CRIAR CAMPEONATO
    @Transactional
    public CampeonatoResponseDTO criar(CampeonatoCadastroDTO dto, Usuario usuarioLogado) {
        Empresa empresa = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa nao encontrada para este usuario"));

        // Apenas empresas com plano GOLD podem criar campeonatos
        planoService.validarPermissaoCampeonato(empresa);

        ArenaModel arena = arenaRepository.findById(dto.getArenaId())
                .orElseThrow(() -> new RuntimeException("Arena nao encontrada"));

        if (!arena.getEmpresa().getId().equals(empresa.getId())) {
            throw new RuntimeException("Arena nao pertence a sua empresa");
        }

        CampeonatoModel campeonato = CampeonatoModel.builder()
                .nome(dto.getNome())
                .descricao(dto.getDescricao())
                .categoria(dto.getCategoria())
                .dataInicio(dto.getDataInicio())
                .dataFim(dto.getDataFim())
                .taxaInscricao(dto.getTaxaInscricao() != null ? dto.getTaxaInscricao() : BigDecimal.ZERO)
                .status(StatusCampeonato.INSCRICOES_ABERTAS)
                .tokenInscricao(UUID.randomUUID().toString())
                .empresa(empresa)
                .arenas(arena)
                .build();

        return toResponse(campeonatoRepository.save(campeonato));
    }

    //INSCRIÇÕES DE TIMES
    @Transactional
    public InscricaoResponseDTO inscreverTime(String token, Long timeId, Usuario usuarioLogado) {
        CampeonatoModel campeonato = campeonatoRepository.findByTokenInscricao(token)
                .orElseThrow(() -> new RuntimeException("Token de inscricao invalido"));

        if (campeonato.getStatus() != StatusCampeonato.INSCRICOES_ABERTAS) {
            throw new RuntimeException("Inscricoes encerradas para este campeonato");
        }

        TimesModel time = timesRepository.findById(timeId)
                .orElseThrow(() -> new RuntimeException("Time nao encontrado"));

        if (!time.getJogador().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Apenas o dono do time pode inscrevê-lo");
        }

        int membrosAceitos = membroTimeRepository.countByTimeAndStatus(time, StatusMembroTime.ACEITO);
        if (membrosAceitos < 2) {
            throw new RuntimeException("O time precisa ter 2 jogadores aceitos para se inscrever");
        }

        inscricaoRepository.findByCampeonatoAndTime(campeonato, time).ifPresent(i -> {
            throw new RuntimeException("Time ja inscrito neste campeonato");
        });

        // Conta apenas inscricoes confirmadas para o limite de 16
        int totalConfirmados = inscricaoRepository.countByCampeonatoAndStatus(
                campeonato, StatusInscricao.CONFIRMADA);
        if (totalConfirmados >= 16) {
            throw new RuntimeException("Campeonato ja atingiu o limite de 16 times");
        }

        BigDecimal taxa = campeonato.getTaxaInscricao();
        boolean temTaxa = taxa != null && taxa.compareTo(BigDecimal.ZERO) > 0;

        InscricaoCampeonatoModel inscricao = InscricaoCampeonatoModel.builder()
                .campeonato(campeonato)
                .time(time)
                .dataInscricao(Instant.now())
                .status(temTaxa ? StatusInscricao.PAGAMENTO_PENDENTE : StatusInscricao.CONFIRMADA)
                .build();

        inscricaoRepository.save(inscricao);

        // Retorna apenas dados da inscricao sem checkout (sera pago via /pagamentos/inscricao/{id})
        return new InscricaoResponseDTO(
                inscricao.getId(),
                campeonato.getId(),
                campeonato.getNome(),
                time.getId(),
                time.getNome(),
                inscricao.getStatus(),
                taxa,
                null, null, null
        );
    }

    // INICIAR CAMPEONATO
    @Transactional
    public List<PartidaResponseDTO> iniciarCampeonato(Long campeonatoId, Usuario usuarioLogado) {
        CampeonatoModel campeonato = buscarCampeonato(campeonatoId);
        validarDonoCampeonato(campeonato, usuarioLogado);

        if (campeonato.getStatus() != StatusCampeonato.INSCRICOES_ABERTAS) {
            throw new RuntimeException("Campeonato nao esta com inscricoes abertas");
        }

        // Conta apenas times com inscricao CONFIRMADA (pagamento aprovado)
        int totalConfirmados = inscricaoRepository.countByCampeonatoAndStatus(
                campeonato, StatusInscricao.CONFIRMADA);

        if (!TAMANHHOS_VALIDOS.contains(totalConfirmados)) {
            throw new RuntimeException(
                    "Numero de times invalido. Sao necessarios exatamente 8 ou 16 times com inscricao confirmada. " +
                            "Times confirmados: " + totalConfirmados);
        }

        campeonato.setStatus(StatusCampeonato.EM_ANDAMENTO);
        campeonatoRepository.save(campeonato);

        // Apenas inscricoes confirmadas participam do chaveamento
        List<InscricaoCampeonatoModel> inscricoes = inscricaoRepository
                .findByCampeonato(campeonato)
                .stream()
                .filter(i -> i.getStatus() == StatusInscricao.CONFIRMADA)
                .toList();

        List<TimesModel> times = new ArrayList<>(inscricoes.stream().map(InscricaoCampeonatoModel::getTime).toList());
        Collections.shuffle(times);

        String fase = totalConfirmados == 16 ? "Oitavas de final" : "Quartas de final";
        List<PartidaModel> partidas = new ArrayList<>();

        for (int i = 0; i < times.size(); i += 2) {
            PartidaModel partida = PartidaModel.builder()
                    .campeonato(campeonato)
                    .fase(fase)
                    .rodada(i / 2 + 1)
                    .timeCasa(times.get(i))
                    .timeVisitante(times.get(i + 1))
                    .status(StatusPartida.AGUARDANDO)
                    .build();
            partidas.add(partidaRepository.save(partida));
        }

        return partidas.stream().map(this::toPartidaResponse).toList();
    }

    //REGISTRAR RESULTADOS
    @Transactional
    public PartidaResponseDTO registrarResultado(Long partidaId, ResultadoPartidaDTO dto, Usuario usuarioLogado) {
        PartidaModel partida = partidaRepository.findById(partidaId)
                .orElseThrow(() -> new RuntimeException("Partida nao encontrada"));

        validarDonoCampeonato(partida.getCampeonato(), usuarioLogado);

        if (partida.getStatus() == StatusPartida.FINALIZADA) {
            throw new RuntimeException("Esta partida ja foi finalizada");
        }
        if (dto.getPlacarTimeCasa().equals(dto.getPlacarTimeVisitante())) {
            throw new RuntimeException("Empate nao e permitido em eliminatoria simples");
        }

        TimesModel vencedor = dto.getPlacarTimeCasa() > dto.getPlacarTimeVisitante()
                ? partida.getTimeCasa()
                : partida.getTimeVisitante();

        partida.setPlacarTimeCasa(dto.getPlacarTimeCasa());
        partida.setPlacarTimeVisitante(dto.getPlacarTimeVisitante());
        partida.setTimeVencedor(vencedor);
        partida.setStatus(StatusPartida.FINALIZADA);
        partidaRepository.save(partida);

        avancarFaseSeNecessario(partida.getCampeonato(), partida.getFase());

        return toPartidaResponse(partida);
    }

    public List<CampeonatoResponseDTO> listarTodos() {
        return campeonatoRepository.findAll().stream().map(this::toResponse).toList();
    }

    public List<CampeonatoResponseDTO> listarPorEmpresa(Usuario usuarioLogado) {
        Empresa empresa = empresaRepository.findByUsuarioId(usuarioLogado.getId())
                .orElseThrow(() -> new RuntimeException("Empresa nao encontrada para este usuario"));

        return campeonatoRepository.findByEmpresaId(empresa.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public CampeonatoResponseDTO buscarPorId(Long id) {
        return toResponse(buscarCampeonato(id));
    }

    public List<PartidaResponseDTO> listarPartidas(Long campeonatoId) {
        return partidaRepository.findByCampeonato(buscarCampeonato(campeonatoId))
                .stream().map(this::toPartidaResponse).toList();
    }

    //LÓGICA AVANÇO DE FASE
    private void avancarFaseSeNecessario(CampeonatoModel campeonato, String faseAtual) {
        List<PartidaModel> partidasDaFase = partidaRepository.findByCampeonatoAndFase(campeonato, faseAtual);
        boolean todasFinalizadas = partidasDaFase.stream()
                .allMatch(p -> p.getStatus() == StatusPartida.FINALIZADA);

        if (!todasFinalizadas) return;

        List<TimesModel> vencedores = partidasDaFase.stream().map(PartidaModel::getTimeVencedor).toList();

        if (vencedores.size() == 1) {
            campeonato.setTimeVencedor(vencedores.get(0));
            campeonato.setStatus(StatusCampeonato.FINALIZADO);
            campeonatoRepository.save(campeonato);
            return;
        }

        String proximaFase = proximaFase(faseAtual);
        for (int i = 0; i < vencedores.size(); i += 2) {
            PartidaModel nova = PartidaModel.builder()
                    .campeonato(campeonato)
                    .fase(proximaFase)
                    .rodada(i / 2 + 1)
                    .timeCasa(vencedores.get(i))
                    .timeVisitante(vencedores.get(i + 1))
                    .status(StatusPartida.AGUARDANDO)
                    .build();
            partidaRepository.save(nova);
        }
    }

    private String proximaFase(String faseAtual) {
        return switch (faseAtual) {
            case "Oitavas de final" -> "Quartas de final";
            case "Quartas de final" -> "Semifinal";
            case "Semifinal"        -> "Final";
            default -> throw new RuntimeException("Fase desconhecida: " + faseAtual);
        };
    }


    private CampeonatoModel buscarCampeonato(Long id) {
        return campeonatoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Campeonato nao encontrado"));
    }

    private void validarDonoCampeonato(CampeonatoModel campeonato, Usuario usuarioLogado) {
        if (!campeonato.getEmpresa().getUsuario().getId().equals(usuarioLogado.getId())) {
            throw new RuntimeException("Acesso negado: voce nao e o dono deste campeonato");
        }
    }

    private CampeonatoResponseDTO toResponse(CampeonatoModel c) {
        return new CampeonatoResponseDTO(
                c.getId(), c.getNome(), c.getDescricao(), c.getCategoria(),
                c.getDataInicio(), c.getDataFim(), c.getStatus(), c.getTokenInscricao(),
                c.getEmpresa().getId(),
                c.getArenas() != null ? c.getArenas().getId() : null,
                c.getTimeVencedor() != null ? c.getTimeVencedor().getId() : null,
                inscricaoRepository.countByCampeonato(c),
                c.getTaxaInscricao()
        );
    }

    private PartidaResponseDTO toPartidaResponse(PartidaModel p) {
        return new PartidaResponseDTO(
                p.getId(), p.getFase(), p.getRodada(),
                p.getTimeCasa() != null ? p.getTimeCasa().getId() : null,
                p.getTimeCasa() != null ? p.getTimeCasa().getNome() : null,
                p.getTimeVisitante() != null ? p.getTimeVisitante().getId() : null,
                p.getTimeVisitante() != null ? p.getTimeVisitante().getNome() : null,
                p.getPlacarTimeCasa(), p.getPlacarTimeVisitante(),
                p.getTimeVencedor() != null ? p.getTimeVencedor().getId() : null,
                p.getDataHoraJogo(), p.getStatus()
        );
    }
}

