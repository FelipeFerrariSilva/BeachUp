import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin, of } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import { QuadraService } from '../../shared/services/quadra.service';
import { ArenaService } from '../../shared/services/arena.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { ReservaResponse } from '../../shared/services/models/quadra.model';
import { ArenaResponse } from '../../shared/services/models/arena.model';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';

interface KpiCard {
  label: string;
  valor: string | number;
  sub: string;
  icone: string;
  cor: 'laranja' | 'verde' | 'azul' | 'roxo';
  tendencia?: 'up' | 'down' | 'neutral';
}

interface RankingQuadra {
  nome: string;
  arenaNome: string;
  totalReservas: number;
  confirmadas: number;
  faturamento: number;
  taxaOcupacao: number;
}

interface ReservasPorMes {
  mes: string;
  confirmadas: number;
  canceladas: number;
  pendentes: number;
  faturamento: number;
}

interface ReservaPorDia {
  dia: string;
  total: number;
}

@Component({
  selector: 'app-metricas-dono',
  standalone: true,
  imports: [CommonModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './metricas-dono.html',
  styleUrl: './metricas-dono.css',
})
export class MetricasDono implements OnInit {
  private quadraService = inject(QuadraService);
  private arenaService = inject(ArenaService);
  public navigation = inject(NavigationService);
  private alertService = inject(AlertService);

  carregando = true;
  todasReservas: ReservaResponse[] = [];
  arenas: ArenaResponse[] = [];

  kpis: KpiCard[] = [];
  ranking: RankingQuadra[] = [];
  reservasPorMes: ReservasPorMes[] = [];
  reservasPorDia: ReservaPorDia[] = [];

  periodoSelecionado: '30' | '90' | '365' | 'todos' = '30';

  readonly NOMES_MESES = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
  readonly NOMES_DIAS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;

    this.arenaService.getMinhas().pipe(
      catchError(() => of([] as ArenaResponse[])),
      switchMap((arenas) => {
        this.arenas = arenas;
        if (!arenas.length) return of([]);

        const quadraReqs = arenas.map((a) =>
          this.quadraService.getQuadrasPorArena(a.id).pipe(
            catchError(() => of([])),
            map((quadras: any[]) => quadras.map((q) => ({ ...q, arenaNome: a.nome, arenaId: a.id })))
          )
        );

        return forkJoin(quadraReqs).pipe(
          map((listas) => listas.flat()),
          switchMap((quadras) => {
            if (!quadras.length) return of({ quadras, reservas: [] });

            const reservaReqs = quadras.map((q) =>
              this.quadraService.getReservasPorQuadra(q.id).pipe(
                catchError(() => of([] as ReservaResponse[])),
                map((reservas) => reservas.map((r) => ({ ...r, quadraNomeArena: q.arenaNome })))
              )
            );

            return forkJoin(reservaReqs).pipe(
              map((listas) => ({ quadras, reservas: listas.flat() }))
            );
          })
        );
      }),
      catchError(() => of({ quadras: [], reservas: [] }))
    ).subscribe((result: any) => {
      this.todasReservas = result.reservas ?? [];
      this.calcular(result.quadras ?? []);
      this.carregando = false;
    });
  }

  reservasFiltradas(): ReservaResponse[] {
    if (this.periodoSelecionado === 'todos') return this.todasReservas;
    const dias = parseInt(this.periodoSelecionado);
    const limite = new Date();
    limite.setDate(limite.getDate() - dias);
    return this.todasReservas.filter((r) => new Date(r.dataHoraInicio) >= limite);
  }

  calcular(quadras: any[]): void {
    const reservas = this.reservasFiltradas();
    const confirmadas = reservas.filter((r) => r.status === 'CONFIRMADA');
    const canceladas = reservas.filter((r) => r.status === 'CANCELADA');
    const pendentes = reservas.filter((r) => r.status === 'PENDENTE');

    const faturamentoTotal = confirmadas.reduce((s, r) => s + (r.valorTotal ?? 0), 0);
    const taxaOcupacao = reservas.length ? Math.round((confirmadas.length / reservas.length) * 100) : 0;
    const ticketMedio = confirmadas.length ? faturamentoTotal / confirmadas.length : 0;

    this.kpis = [
      {
        label: 'Faturamento total',
        valor: this.formatarValor(faturamentoTotal),
        sub: `${confirmadas.length} reservas confirmadas`,
        icone: 'bi-cash-coin',
        cor: 'verde',
        tendencia: faturamentoTotal > 0 ? 'up' : 'neutral',
      },
      {
        label: 'Total de reservas',
        valor: reservas.length,
        sub: `${pendentes.length} pendente${pendentes.length !== 1 ? 's' : ''}`,
        icone: 'bi-calendar-check-fill',
        cor: 'laranja',
        tendencia: reservas.length > 0 ? 'up' : 'neutral',
      },
      {
        label: 'Taxa de ocupação',
        valor: taxaOcupacao + '%',
        sub: `${canceladas.length} cancelamento${canceladas.length !== 1 ? 's' : ''}`,
        icone: 'bi-graph-up-arrow',
        cor: 'azul',
        tendencia: taxaOcupacao >= 50 ? 'up' : taxaOcupacao > 0 ? 'neutral' : 'down',
      },
      {
        label: 'Ticket médio',
        valor: this.formatarValor(ticketMedio),
        sub: `por reserva confirmada`,
        icone: 'bi-receipt',
        cor: 'roxo',
        tendencia: 'neutral',
      },
    ];

    this.ranking = quadras.map((q) => {
      const rq = reservas.filter((r) => r.quadraId === q.id);
      const conf = rq.filter((r) => r.status === 'CONFIRMADA');
      const fat = conf.reduce((s, r) => s + (r.valorTotal ?? 0), 0);
      return {
        nome: q.nome,
        arenaNome: q.arenaNome,
        totalReservas: rq.length,
        confirmadas: conf.length,
        faturamento: fat,
        taxaOcupacao: rq.length ? Math.round((conf.length / rq.length) * 100) : 0,
      } as RankingQuadra;
    }).sort((a, b) => b.faturamento - a.faturamento);

    this.reservasPorMes = this.calcularPorMes(reservas);
    this.reservasPorDia = this.calcularPorDia(reservas);
  }

  private calcularPorMes(reservas: ReservaResponse[]): ReservasPorMes[] {
    const mapa = new Map<string, ReservasPorMes>();
    const agora = new Date();

    for (let i = 5; i >= 0; i--) {
      const d = new Date(agora.getFullYear(), agora.getMonth() - i, 1);
      const chave = `${d.getFullYear()}-${d.getMonth()}`;
      mapa.set(chave, {
        mes: `${this.NOMES_MESES[d.getMonth()]}/${String(d.getFullYear()).slice(2)}`,
        confirmadas: 0, canceladas: 0, pendentes: 0, faturamento: 0,
      });
    }

    reservas.forEach((r) => {
      const d = new Date(r.dataHoraInicio);
      const chave = `${d.getFullYear()}-${d.getMonth()}`;
      if (!mapa.has(chave)) return;
      const entry = mapa.get(chave)!;
      if (r.status === 'CONFIRMADA') { entry.confirmadas++; entry.faturamento += r.valorTotal ?? 0; }
      else if (r.status === 'CANCELADA') entry.canceladas++;
      else entry.pendentes++;
    });

    return Array.from(mapa.values());
  }

  private calcularPorDia(reservas: ReservaResponse[]): ReservaPorDia[] {
    const contagem = new Array(7).fill(0);
    reservas.filter((r) => r.status === 'CONFIRMADA').forEach((r) => {
      contagem[new Date(r.dataHoraInicio).getDay()]++;
    });
    return this.NOMES_DIAS.map((dia, i) => ({ dia, total: contagem[i] }));
  }

  mudarPeriodo(p: '30' | '90' | '365' | 'todos'): void {
    this.periodoSelecionado = p;
    const quadras = this.ranking.map((r) => ({ id: 0, nome: r.nome, arenaNome: r.arenaNome }));
    this.calcular(quadras);
    this.carregar();
  }

  maxPorMes(campo: 'confirmadas' | 'faturamento'): number {
    return Math.max(...this.reservasPorMes.map((m) => m[campo]), 1);
  }

  maxPorDia(): number {
    return Math.max(...this.reservasPorDia.map((d) => d.total), 1);
  }

  alturaBarraMes(valor: number, campo: 'confirmadas' | 'faturamento'): string {
    return Math.round((valor / this.maxPorMes(campo)) * 100) + '%';
  }

  alturaBarraDia(valor: number): string {
    return Math.round((valor / this.maxPorDia()) * 100) + '%';
  }

  get confirmadasCount(): number {
    return this.reservasFiltradas().filter((r) => r.status === 'CONFIRMADA').length;
  }

  get pendentesCount(): number {
    return this.reservasFiltradas().filter((r) => r.status === 'PENDENTE').length;
  }

  get canceladasCount(): number {
    return this.reservasFiltradas().filter((r) => r.status === 'CANCELADA').length;
  }

  formatarValor(valor: number): string {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor);
  }

  formatarValorCompacto(valor: number): string {
    if (valor >= 1000) return `R$ ${(valor / 1000).toFixed(1)}k`;
    return this.formatarValor(valor);
  }
}
