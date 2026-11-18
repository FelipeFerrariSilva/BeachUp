import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { ArenaService } from '../../shared/services/arena.service';
import { CampeonatoService } from '../../shared/services/campeonato.service';
import { TimesService } from '../../shared/services/times.service';
import {
  CampeonatoResponse,
  ORDEM_FASES,
  PartidaResponse,
  STATUS_CAMPEONATO_LABEL,
} from '../../shared/services/models/campeonato.model';
import { TimesResponse } from '../../shared/services/models/times.model';

@Component({
  selector: 'app-campeonato-detalhe',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, MenuLateral, NavBar],
  templateUrl: './campeonato-detalhe.html',
  styleUrl: './campeonato-detalhe.css',
})
export class CampeonatoDetalhe implements OnInit {
  campeonatoId!: number;
  campeonato: CampeonatoResponse | null = null;
  partidas: PartidaResponse[] = [];

  carregando = true;
  erro = '';

  souDono = false;
  meusTimesElegiveis: TimesResponse[] = [];
  timeSelecionadoId: number | null = null;
  inscrevendo = false;
  carregandoTimes = false;

  partidaEditandoId: number | null = null;
  resultadoForm: FormGroup;
  salvandoResultado = false;

  readonly statusLabel = STATUS_CAMPEONATO_LABEL;

  constructor(
    private route: ActivatedRoute,
    private fb: FormBuilder,
    private campeonatoService: CampeonatoService,
    private arenaService: ArenaService,
    private timesService: TimesService,
    private alertService: AlertService,
    public auth: AuthService,
    public navigation: NavigationService,
  ) {
    this.resultadoForm = this.fb.group({
      placarTimeCasa: [null, [Validators.required, Validators.min(0)]],
      placarTimeVisitante: [null, [Validators.required, Validators.min(0)]],
    });
  }

  ngOnInit(): void {
    this.campeonatoId = Number(this.route.snapshot.paramMap.get('id'));
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.erro = '';

    this.campeonatoService.buscarPorId(this.campeonatoId).subscribe({
      next: (campeonato) => {
        this.campeonato = campeonato;
        this.verificarDono(campeonato);
        this.carregarPartidas();

        if (this.auth.isJogador() && campeonato.status === 'INSCRICOES_ABERTAS') {
          this.carregarMeusTimes();
        }
      },
      error: (err) => {
        this.carregando = false;
        this.erro = 'Campeonato não encontrado.';
        this.alertService.erroHttp(err);
      },
    });
  }

  private verificarDono(campeonato: CampeonatoResponse): void {
    if (!this.auth.isEmpresa()) return;
    this.arenaService.getMinhas().subscribe({
      next: (arenas) => {
        this.souDono = arenas.some((a) => a.id === campeonato.idArena);
      },
    });
  }

  carregarPartidas(): void {
    this.campeonatoService.listarPartidas(this.campeonatoId).subscribe({
      next: (partidas) => {
        this.partidas = partidas;
        this.carregando = false;
      },
      error: (err) => {
        this.carregando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  carregarMeusTimes(): void {
    this.carregandoTimes = true;
    this.timesService.meusTimes().subscribe({
      next: (times) => {
        this.meusTimesElegiveis = times.filter(
          (t) => t.membros.filter((m) => m.status === 'ACEITO').length >= 2,
        );
        this.carregandoTimes = false;
      },
      error: () => {
        this.carregandoTimes = false;
      },
    });
  }

  get fasesOrdenadas(): string[] {
    const presentes = new Set(this.partidas.map((p) => p.fase));
    return ORDEM_FASES.filter((f) => presentes.has(f));
  }

  partidasDaFase(fase: string): PartidaResponse[] {
    return this.partidas
      .filter((p) => p.fase === fase)
      .sort((a, b) => a.rodada - b.rodada);
  }

  inscreverTime(): void {
    if (!this.campeonato?.tokenInscricao || !this.timeSelecionadoId) return;

    this.inscrevendo = true;
    this.campeonatoService
      .inscreverTime(this.campeonato.tokenInscricao, this.timeSelecionadoId)
      .subscribe({
        next: (atualizado) => {
          this.campeonato = atualizado;
          this.timeSelecionadoId = null;
          this.inscrevendo = false;
          this.alertService.sucesso('Time inscrito no campeonato!');
        },
        error: (err) => {
          this.inscrevendo = false;
          this.alertService.erroHttp(err);
        },
      });
  }

  abrirFormResultado(partida: PartidaResponse): void {
    this.partidaEditandoId = partida.id;
    this.resultadoForm.reset({
      placarTimeCasa: partida.placarTimeCasa,
      placarTimeVisitante: partida.placarTimeVisitante,
    });
  }

  fecharFormResultado(): void {
    this.partidaEditandoId = null;
  }

  salvarResultado(partida: PartidaResponse): void {
    if (this.resultadoForm.invalid) {
      this.resultadoForm.markAllAsTouched();
      return;
    }

    const { placarTimeCasa, placarTimeVisitante } = this.resultadoForm.value;
    if (placarTimeCasa === placarTimeVisitante) {
      this.alertService.aviso('Empate não é permitido em eliminatória simples.');
      return;
    }

    this.salvandoResultado = true;
    this.campeonatoService.registrarResultado(partida.id, { placarTimeCasa, placarTimeVisitante }).subscribe({
      next: () => {
        this.salvandoResultado = false;
        this.partidaEditandoId = null;
        this.alertService.sucesso('Resultado registrado!');
        this.carregar();
      },
      error: (err) => {
        this.salvandoResultado = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  podeRegistrarResultado(partida: PartidaResponse): boolean {
    return (
      this.souDono &&
      partida.status === 'AGUARDANDO' &&
      partida.idTimeCasa != null &&
      partida.idTimeVisitante != null
    );
  }

  copiarLinkInscricao(): void {
    if (!this.campeonato?.tokenInscricao) return;
    const link = `${window.location.origin}/campeonatos/inscrever/${this.campeonato.tokenInscricao}`;
    navigator.clipboard
      .writeText(link)
      .then(() => this.alertService.sucesso('Link de inscrição copiado!'))
      .catch(() => this.alertService.erro('Não foi possível copiar o link.'));
  }

  nomeCampeao(): string {
    const final = this.partidasDaFase('Final')[0];
    if (!final || final.idTimeVencedor == null) return '';
    return final.idTimeVencedor === final.idTimeCasa
      ? final.nomeTimeCasa ?? ''
      : final.nomeTimeVisitante ?? '';
  }

  formatarData(data: string | null): string {
    if (!data) return '—';
    return new Date(`${data}T00:00:00`).toLocaleDateString('pt-BR');
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: PartidaResponse) {
    return item.id;
  }
}
