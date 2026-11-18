import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';

export type StatusReserva = 'PENDENTE' | 'CONFIRMADA' | 'CANCELADA';

export interface Reserva {
  id: number;
  quadraId: number;
  nomeQuadra: string;
  jogadorId: number;
  nomeJogador: string;
  dataHoraInicio: string;
  dataHoraFim: string;
  valorTotal: number;
  status: StatusReserva;
}

export interface AvaliacaoPayload {
  reservaId: number;
  notaArena: number;
  notaQuadra: number;
  comentarioArena: string;
  comentarioQuadra: string;
}

export interface Avaliacao {
  id: number;
  reservaId: number;
  notaArena: number;
  notaQuadra: number;
  comentarioArena: string;
  comentarioQuadra: string;
}

@Component({
  selector: 'app-minhas-reservas',
  standalone: true,
  imports: [CommonModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './minhas-reservas.html',
  styleUrl: './minhas-reservas.css',
})
export class MinhasReservas implements OnInit {
  private readonly API = 'http://localhost:8080';

  isJogador = false;
  minhasReservas: Reserva[] = [];
  carregandoReservas = false;

  // Modal de avaliação
  reservaSelecionada: Reserva | null = null;
  jaAvaliou = false;
  enviandoAvaliacao = false;
  reservasAvaliadas = new Set<number>();
  pagandoReservaId: number | null = null;

  notaArena = 0;
  notaQuadra = 0;
  comentarioArena = '';
  comentarioQuadra = '';
  hoveredArena = 0;
  hoveredQuadra = 0;
  starsArray = [1, 2, 3, 4, 5];

  constructor(
    private http: HttpClient,
    private alertService: AlertService,
    public navigation: NavigationService,
    public auth: AuthService,
  ) {}

  ngOnInit(): void {
    this.isJogador = this.auth.isJogador();
    this.carregarMinhasReservas();
  }

  carregarMinhasReservas(): void {
    this.carregandoReservas = true;
    this.http.get<Reserva[]>(`${this.API}/reservas/minhas`).subscribe({
      next: (reservas) => {
        this.minhasReservas = reservas.sort(
          (a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime(),
        );
        this.carregandoReservas = false;
        this.verificarAvaliacoes();
      },
      error: (err) => {
        this.carregandoReservas = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  verificarAvaliacoes(): void {
    const concluidas = this.minhasReservas.filter((r) => this.podeAvaliar(r));
    concluidas.forEach((r) => {
      this.http.get<Avaliacao>(`${this.API}/avaliacoes/reserva/${r.id}`).subscribe({
        next: () => this.reservasAvaliadas.add(r.id),
        error: () => {},
      });
    });
  }

  podeAvaliar(reserva: Reserva): boolean {
    if (reserva.status === 'CANCELADA') return false;
    const fim = new Date(reserva.dataHoraFim).getTime();
    return fim < Date.now();
  }

  abrirAvaliacao(reserva: Reserva): void {
    this.reservaSelecionada = reserva;
    this.notaArena = 0;
    this.notaQuadra = 0;
    this.comentarioArena = '';
    this.comentarioQuadra = '';
    this.hoveredArena = 0;
    this.hoveredQuadra = 0;
    this.jaAvaliou = false;

    this.http.get<Avaliacao>(`${this.API}/avaliacoes/reserva/${reserva.id}`).subscribe({
      next: (av) => {
        this.jaAvaliou = true;
        this.notaArena = av.notaArena;
        this.notaQuadra = av.notaQuadra;
        this.comentarioArena = av.comentarioArena ?? '';
        this.comentarioQuadra = av.comentarioQuadra ?? '';
      },
      error: () => {
        this.jaAvaliou = false;
      },
    });
  }

  fecharAvaliacao(): void {
    this.reservaSelecionada = null;
  }

  get podeConcluir(): boolean {
    return this.notaArena > 0 && this.notaQuadra > 0;
  }

  enviarAvaliacao(): void {
    if (!this.podeConcluir || !this.reservaSelecionada) return;

    const payload: AvaliacaoPayload = {
      reservaId: this.reservaSelecionada.id,
      notaArena: this.notaArena,
      notaQuadra: this.notaQuadra,
      comentarioArena: this.comentarioArena.trim(),
      comentarioQuadra: this.comentarioQuadra.trim(),
    };

    this.enviandoAvaliacao = true;
    this.http.post<Avaliacao>(`${this.API}/avaliacoes`, payload).subscribe({
      next: () => {
        this.enviandoAvaliacao = false;
        if (this.reservaSelecionada) {
          this.reservasAvaliadas.add(this.reservaSelecionada.id);
        }
        this.fecharAvaliacao();
        this.alertService.sucesso('Avaliação enviada! Obrigado pelo feedback.');
      },
      error: (err) => {
        this.enviandoAvaliacao = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  getLabelNota(nota: number): string {
    const labels: Record<number, string> = {
      1: 'Péssimo',
      2: 'Ruim',
      3: 'Regular',
      4: 'Bom',
      5: 'Excelente',
    };
    return labels[nota] ?? '';
  }

  cancelarReservaJogador(reserva: Reserva): void {
    this.alertService.confirmarExclusao(`a reserva em ${reserva.nomeQuadra}`).then((result) => {
      if (!result.isConfirmed) return;

      this.http.patch<Reserva>(`${this.API}/reservas/${reserva.id}/cancelar`, {}).subscribe({
        next: (atualizada) => {
          this.minhasReservas = this.minhasReservas.map((r) =>
            r.id === atualizada.id ? atualizada : r,
          );
          this.alertService.sucesso('Reserva cancelada com sucesso.');
        },
        error: (err) => this.alertService.erroHttp(err),
      });
    });
  }

  podeCancelar(reserva: Reserva): boolean {
    if (reserva.status === 'CANCELADA') return false;
    const inicio = new Date(reserva.dataHoraInicio).getTime();
    return inicio - Date.now() > 24 * 3_600_000;
  }

  podePagar(reserva: Reserva): boolean {
    return reserva.status === 'PENDENTE';
  }

  pagarAgora(reserva: Reserva): void {
    this.pagandoReservaId = reserva.id;
    this.http
      .post<{
        preferenceId: string;
        initPoint: string;
        sandboxInitPoint: string;
      }>(`${this.API}/pagamentos/reserva/${reserva.id}/iniciar`, {})
      .subscribe({
        next: (checkout) => {
          window.location.href = checkout.initPoint;
        },
        error: (err) => {
          this.pagandoReservaId = null;
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

  formatarValor(valor: number): string {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor);
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: { id: number }) {
    return item.id;
  }
}
