import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { CampeonatoService } from '../../shared/services/campeonato.service';
import {
  CampeonatoResponse,
  STATUS_CAMPEONATO_LABEL,
  StatusCampeonato,
} from '../../shared/services/models/campeonato.model';

@Component({
  selector: 'app-campeonatos',
  standalone: true,
  imports: [CommonModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './campeonatos.html',
  styleUrl: './campeonatos.css',
})
export class Campeonatos implements OnInit {
  campeonatos: CampeonatoResponse[] = [];
  carregando = true;
  erro = '';

  filtroStatus: StatusCampeonato | 'TODOS' = 'TODOS';
  filtroBusca = '';

  readonly statusLabel = STATUS_CAMPEONATO_LABEL;
  readonly opcoesStatus: { valor: StatusCampeonato | 'TODOS'; label: string }[] = [
    { valor: 'TODOS', label: 'Todos' },
    { valor: 'INSCRICOES_ABERTAS', label: 'Inscrições abertas' },
    { valor: 'EM_ANDAMENTO', label: 'Em andamento' },
    { valor: 'FINALIZADO', label: 'Finalizado' },
  ];

  constructor(
    private campeonatoService: CampeonatoService,
    private alertService: AlertService,
    public auth: AuthService,
    public navigation: NavigationService,
  ) {}

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.erro = '';
    this.campeonatoService.listarTodos().subscribe({
      next: (campeonatos) => {
        this.campeonatos = campeonatos.sort(
          (a, b) => new Date(b.dataInicio).getTime() - new Date(a.dataInicio).getTime(),
        );
        this.carregando = false;
      },
      error: (err) => {
        this.carregando = false;
        this.erro = 'Não foi possível carregar os campeonatos.';
        this.alertService.erroHttp(err);
      },
    });
  }

  get campeonatosFiltrados(): CampeonatoResponse[] {
    return this.campeonatos.filter((c) => {
      const statusOk = this.filtroStatus === 'TODOS' || c.status === this.filtroStatus;
      const buscaOk =
        !this.filtroBusca.trim() ||
        c.nome.toLowerCase().includes(this.filtroBusca.trim().toLowerCase()) ||
        (c.categoria ?? '').toLowerCase().includes(this.filtroBusca.trim().toLowerCase());
      return statusOk && buscaOk;
    });
  }

  formatarData(data: string | null): string {
    if (!data) return '—';
    return new Date(`${data}T00:00:00`).toLocaleDateString('pt-BR');
  }

  badgeClasse(status: StatusCampeonato): string {
    switch (status) {
      case 'INSCRICOES_ABERTAS':
        return 'badge-aberto';
      case 'EM_ANDAMENTO':
        return 'badge-andamento';
      case 'FINALIZADO':
        return 'badge-finalizado';
      default:
        return 'badge-fechado';
    }
  }

  abrirCampeonato(id: number): void {
    this.navigation.irPara(`campeonatos/${id}`);
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: CampeonatoResponse) {
    return item.id;
  }
}
