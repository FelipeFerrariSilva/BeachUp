import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { Reserva } from '../minhas-reservas/minhas-reservas';

export interface AvaliacaoPayload {
  reservaId: number;
  nota: number;
  comentario?: string;
}

export interface AvaliacaoResponse {
  id: number;
  reservaId: number;
  quadraId: number;
  nomeQuadra: string;
  nomeJogador: string;
  nota: number;
  comentario: string | null;
  criadoEm: string;
}

@Component({
  selector: 'app-avaliacao-reserva',
  standalone: true,
  imports: [CommonModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './avaliacao-reserva.html',
  styleUrl: './avaliacao-reserva.css',
})
export class AvaliacaoReserva implements OnInit {
  private readonly API = 'http://localhost:8080';

  reserva: Reserva | null = null;
  carregando = true;
  enviando = false;
  jaAvaliou = false;

  nota = 0;
  comentario = '';

  hoveredStar = 0;
  starsArray = [1, 2, 3, 4, 5];

  readonly LABELS: Record<number, string> = {
    1: 'Péssimo',
    2: 'Ruim',
    3: 'Regular',
    4: 'Bom',
    5: 'Excelente',
  };

  readonly DESCRIPTIONS: Record<number, string> = {
    1: 'Ficou bem abaixo das expectativas',
    2: 'Deixou a desejar em vários pontos',
    3: 'Atendeu o básico, mas tem espaço para melhorar',
    4: 'Boa experiência, voltaria com prazer',
    5: 'Perfeita! Superou todas as expectativas',
  };

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private alertService: AlertService,
    public navigation: NavigationService,
  ) {}

  ngOnInit(): void {
    const idParam =
      this.route.snapshot.paramMap.get('id') ?? this.route.snapshot.queryParamMap.get('reservaId');

    if (!idParam || isNaN(Number(idParam))) {
      this.alertService.erro('Reserva não identificada.');
      this.navigation.irPara('minhas-reservas');
      return;
    }
    this.carregarReserva(Number(idParam));
  }

  carregarReserva(id: number): void {
    this.carregando = true;
    this.http.get<Reserva>(`${this.API}/reservas/${id}`).subscribe({
      next: (reserva) => {
        this.reserva = reserva;
        this.verificarAvaliacao(id);
      },
      error: (err) => {
        this.carregando = false;
        this.alertService.erroHttp(err);
        this.navigation.irPara('minhas-reservas');
      },
    });
  }

  verificarAvaliacao(reservaId: number): void {
    this.http.get<AvaliacaoResponse>(`${this.API}/avaliacoes/reserva/${reservaId}`).subscribe({
      next: (av) => {
        this.jaAvaliou = true;
        this.nota = av.nota;
        this.comentario = av.comentario ?? '';
        this.carregando = false;
      },
      error: () => {
        // 404 = reserva ainda não avaliada
        this.jaAvaliou = false;
        this.carregando = false;
      },
    });
  }

  setNota(n: number): void {
    if (!this.jaAvaliou) this.nota = n;
  }

  get notaAtiva(): number {
    return this.hoveredStar || this.nota;
  }

  get podeConcluir(): boolean {
    return this.nota > 0;
  }

  get labelAtual(): string {
    return this.LABELS[this.notaAtiva] ?? '';
  }

  get descricaoAtual(): string {
    return this.DESCRIPTIONS[this.notaAtiva] ?? '';
  }

  enviarAvaliacao(): void {
    if (!this.podeConcluir || !this.reserva || this.enviando) return;

    const payload: AvaliacaoPayload = {
      reservaId: this.reserva.id,
      nota: this.nota,
      comentario: this.comentario.trim() || undefined,
    };

    this.enviando = true;
    this.http.post<AvaliacaoResponse>(`${this.API}/avaliacoes`, payload).subscribe({
      next: () => {
        this.enviando = false;
        this.alertService
          .sucesso('Avaliação enviada! Obrigado pelo seu feedback.')
          .then(() => this.navigation.irPara('minhas-reservas'));
      },
      error: (err) => {
        this.enviando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  formatarData(iso: string): string {
    return new Date(iso).toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatarDuracao(): string {
    if (!this.reserva) return '';
    const inicio = new Date(this.reserva.dataHoraInicio);
    const fim = new Date(this.reserva.dataHoraFim);
    const minutos = Math.round((fim.getTime() - inicio.getTime()) / 60000);
    if (minutos < 60) return `${minutos} min`;
    const h = Math.floor(minutos / 60);
    const m = minutos % 60;
    return m ? `${h}h ${m}min` : `${h}h`;
  }

  formatarValor(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }
}
