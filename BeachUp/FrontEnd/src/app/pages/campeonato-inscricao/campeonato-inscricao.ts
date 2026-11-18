import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { CampeonatoService } from '../../shared/services/campeonato.service';
import { TimesService } from '../../shared/services/times.service';
import {
  CampeonatoResponse,
  STATUS_CAMPEONATO_LABEL,
} from '../../shared/services/models/campeonato.model';
import { TimesResponse } from '../../shared/services/models/times.model';

@Component({
  selector: 'app-campeonato-inscricao',
  standalone: true,
  imports: [CommonModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './campeonato-inscricao.html',
  styleUrl: './campeonato-inscricao.css',
})
export class CampeonatoInscricao implements OnInit {
  token = '';
  campeonato: CampeonatoResponse | null = null;

  carregando = true;
  naoEncontrado = false;

  meusTimesElegiveis: TimesResponse[] = [];
  timeSelecionadoId: number | null = null;
  carregandoTimes = false;
  inscrevendo = false;
  inscricaoConcluida = false;

  readonly statusLabel = STATUS_CAMPEONATO_LABEL;

  constructor(
    private route: ActivatedRoute,
    private campeonatoService: CampeonatoService,
    private timesService: TimesService,
    private alertService: AlertService,
    public auth: AuthService,
    public navigation: NavigationService,
  ) {}

  ngOnInit(): void {
    this.token = this.route.snapshot.paramMap.get('token') ?? '';
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.naoEncontrado = false;

    if (!this.auth.isLoggedIn()) {
      this.carregando = false;
      return;
    }

    this.campeonatoService.listarTodos().subscribe({
      next: (todos) => {
        this.campeonato = todos.find((c) => c.tokenInscricao === this.token) ?? null;
        this.naoEncontrado = !this.campeonato;
        this.carregando = false;

        if (this.campeonato && this.auth.isJogador() && this.campeonato.status === 'INSCRICOES_ABERTAS') {
          this.carregarMeusTimes();
        }
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

  inscrever(): void {
    if (!this.timeSelecionadoId) return;

    this.inscrevendo = true;
    this.campeonatoService.inscreverTime(this.token, this.timeSelecionadoId).subscribe({
      next: (atualizado) => {
        this.campeonato = atualizado;
        this.inscrevendo = false;
        this.inscricaoConcluida = true;
        this.alertService.sucesso('Seu time foi inscrito no campeonato!');
      },
      error: (err) => {
        this.inscrevendo = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  formatarData(data: string | null): string {
    if (!data) return '—';
    return new Date(`${data}T00:00:00`).toLocaleDateString('pt-BR');
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }
}
