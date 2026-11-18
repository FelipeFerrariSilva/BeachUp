import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { ArenaService } from '../../shared/services/arena.service';
import { ArenaResponse } from '../../shared/services/models/arena.model';
import { CampeonatoService } from '../../shared/services/campeonato.service';
import {
  CampeonatoResponse,
  STATUS_CAMPEONATO_LABEL,
} from '../../shared/services/models/campeonato.model';

const TAMANHOS_VALIDOS = [8, 16];

@Component({
  selector: 'app-campeonatos-dono',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MenuLateral, NavBar],
  templateUrl: './campeonatos-dono.html',
  styleUrl: './campeonatos-dono.css',
})
export class CampeonatosDono implements OnInit {
  arenas: ArenaResponse[] = [];
  meusCampeonatos: CampeonatoResponse[] = [];

  carregandoArenas = true;
  carregandoCampeonatos = false;
  salvando = false;
  iniciandoId: number | null = null;

  modalAberto = false;
  campeonatoForm: FormGroup;

  readonly statusLabel = STATUS_CAMPEONATO_LABEL;

  constructor(
    private fb: FormBuilder,
    private arenaService: ArenaService,
    private campeonatoService: CampeonatoService,
    private alertService: AlertService,
    public navigation: NavigationService,
  ) {
    this.campeonatoForm = this.fb.group({
      nome: ['', [Validators.required, Validators.maxLength(50)]],
      descricao: ['', Validators.maxLength(60)],
      categoria: ['', Validators.maxLength(20)],
      dataInicio: ['', Validators.required],
      dataFim: [''],
      arenaId: [null, Validators.required],
    });
  }

  ngOnInit(): void {
    this.carregarArenas();
  }

  carregarArenas(): void {
    this.carregandoArenas = true;
    this.arenaService.getMinhas().subscribe({
      next: (arenas) => {
        this.arenas = arenas;
        this.carregandoArenas = false;
        this.carregarMeusCampeonatos();
      },
      error: (err) => {
        this.carregandoArenas = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  carregarMeusCampeonatos(): void {
    this.carregandoCampeonatos = true;
    this.campeonatoService.listarTodos().subscribe({
      next: (todos) => {
        const minhasArenasIds = new Set(this.arenas.map((a) => a.id));
        this.meusCampeonatos = todos
          .filter((c) => minhasArenasIds.has(c.idArena))
          .sort((a, b) => new Date(b.dataInicio).getTime() - new Date(a.dataInicio).getTime());
        this.carregandoCampeonatos = false;
      },
      error: (err) => {
        this.carregandoCampeonatos = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  abrirModalNovo(): void {
    if (this.arenas.length === 0) {
      this.alertService.aviso('Cadastre uma arena antes de criar um campeonato.');
      return;
    }
    this.campeonatoForm.reset();
    this.modalAberto = true;
  }

  fecharModal(): void {
    this.modalAberto = false;
  }

  criarCampeonato(): void {
    if (this.campeonatoForm.invalid) {
      this.campeonatoForm.markAllAsTouched();
      return;
    }

    const valores = this.campeonatoForm.value;
    this.salvando = true;

    this.campeonatoService
      .criar({
        nome: valores.nome,
        descricao: valores.descricao || undefined,
        categoria: valores.categoria || undefined,
        dataInicio: valores.dataInicio,
        dataFim: valores.dataFim || undefined,
        arenaId: valores.arenaId,
      })
      .subscribe({
        next: (novo) => {
          this.meusCampeonatos = [novo, ...this.meusCampeonatos];
          this.salvando = false;
          this.modalAberto = false;
          this.alertService.sucesso(`Campeonato "${novo.nome}" criado! Compartilhe o link de inscrição com os times.`);
        },
        error: (err) => {
          this.salvando = false;
          this.alertService.erroHttp(err);
        },
      });
  }

  podeIniciar(c: CampeonatoResponse): boolean {
    return c.status === 'INSCRICOES_ABERTAS' && TAMANHOS_VALIDOS.includes(c.totalInscritos);
  }

  motivoBloqueio(c: CampeonatoResponse): string {
    if (c.status !== 'INSCRICOES_ABERTAS') return '';
    if (!TAMANHOS_VALIDOS.includes(c.totalInscritos)) {
      return `São necessários exatamente 8 ou 16 times inscritos (atual: ${c.totalInscritos}).`;
    }
    return '';
  }

  iniciarCampeonato(c: CampeonatoResponse): void {
    this.alertService
      .confirmar('Iniciar campeonato?', `Isso fecha as inscrições de "${c.nome}" e sorteia o chaveamento. Não será possível desfazer.`)
      .then((result) => {
        if (!result.isConfirmed) return;

        this.iniciandoId = c.id;
        this.campeonatoService.iniciar(c.id).subscribe({
          next: () => {
            this.iniciandoId = null;
            this.meusCampeonatos = this.meusCampeonatos.map((m) =>
              m.id === c.id ? { ...m, status: 'EM_ANDAMENTO' } : m,
            );
            this.alertService.sucesso('Chaveamento sorteado com sucesso!');
            this.navigation.irPara(`campeonatos/${c.id}`);
          },
          error: (err) => {
            this.iniciandoId = null;
            this.alertService.erroHttp(err);
          },
        });
      });
  }

  copiarLinkInscricao(c: CampeonatoResponse): void {
    if (!c.tokenInscricao) return;
    const link = `${window.location.origin}/campeonatos/inscrever/${c.tokenInscricao}`;
    navigator.clipboard
      .writeText(link)
      .then(() => this.alertService.sucesso('Link de inscrição copiado!'))
      .catch(() => this.alertService.erro('Não foi possível copiar o link.'));
  }

  formatarData(data: string | null): string {
    if (!data) return '—';
    return new Date(`${data}T00:00:00`).toLocaleDateString('pt-BR');
  }

  campoInvalido(campo: string): boolean {
    const c = this.campeonatoForm.get(campo);
    return !!(c && c.invalid && c.touched);
  }

  verDetalhes(id: number): void {
    this.navigation.irPara(`campeonatos/${id}`);
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: CampeonatoResponse) {
    return item.id;
  }
}
