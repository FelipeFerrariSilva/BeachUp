import { Component, NgZone, OnDestroy, OnInit, PLATFORM_ID, inject } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators, } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { forkJoin, of } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { QuadraService } from '../../shared/services/quadra.service';
import { ArenaService } from '../../shared/services/arena.service';
import { ArenaCadastroPayload } from '../../shared/services/models/arena.model';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { AssinaturaResponse, HorarioFuncionamento, QuadraResponse, ReservaResponse, } from '../../shared/services/models/quadra.model';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { AuthService } from '../../shared/services/auth.service';
import { NavBar } from '../../shared/nav-bar/nav-bar';

@Component({
  selector: 'app-dashboard-dono',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule, MenuLateral, NavBar],
  templateUrl: './dashboard-dono.html',
  styleUrl: './dashboard-dono.css',
})

export class DashboardDono implements OnInit, OnDestroy {
  private quadraService = inject(QuadraService);
  private arenaService = inject(ArenaService);
  private alertService = inject(AlertService);
  private http = inject(HttpClient);
  private fb = inject(FormBuilder);
  public navigation = inject(NavigationService);
  private ngZone = inject(NgZone);
  private platformId = inject(PLATFORM_ID);
  private intervalId?: ReturnType<typeof setInterval>;

  private readonly backendUrl = 'http://localhost:8080';
  public auth = inject(AuthService);

  now = new Date();
  isJogador = false;
  isEmpresa = false;

  arenas: any[] = [];
  quadrasPorArena: Map<number, number> = new Map();
  arenaSelecionadaId: number | null = null;
  arenaSalvandoFotoId: number | null = null;
  quadras: QuadraResponse[] = [];
  reservas: ReservaResponse[] = [];
  assinatura: AssinaturaResponse | null = null;
  carregandoArenas = true;
  carregandoQuadras = false;
  carregandoReservas = false;
  mpConectada: boolean | null = null;
  salvandoQuadra = false;
  modalQuadraAberto = false;
  modoEdicao = false;
  quadraEditandoId: number | null = null;
  modalReservasAberto = false;
  quadraReservasSelecionada: QuadraResponse | null = null;
  modalQuadrasAberto = false;
  arenaModalSelecionada: any | null = null;
  abaAtiva: 'quadras' | 'reservas' | 'plano' = 'quadras';

  salvandoFotoQuadraId: number | null = null;
  quadraEmEdicao: QuadraResponse | null = null;
  previewFotoEdicao: string | null = null;
  removendoFotoId: number | null = null;

  fotosCadastro: File[] = [];
  previewsCadastro: string[] = [];

  modalDetalheAberto = false;
  quadraDetalhe: QuadraResponse | null = null;
  carrosselIndex = 0;

  horarios: HorarioFuncionamento[] = [];
  carregandoHorarios = false;
  modalHorariosAberto = false;
  arenaHorariosSelecionada: any | null = null;

  modalArenaEdicaoAberto = false;
  arenaEmEdicao: any | null = null;
  salvandoArena = false;

  quadraForm: FormGroup = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(2)]],
    tipoCobertura: ['COBERTA', Validators.required],
    valorHora: [null, [Validators.required, Validators.min(0.01)]],
  });

  get f() {
    return this.quadraForm.controls;
  }

  get isBrowser(): boolean {
    return isPlatformBrowser(this.platformId);
  }

  mapsUrl(arena: any): string {
    const e = arena.endereco;
    const q = `${e.logradouro} ${e.numero} ${e.cidade} ${e.estado}`;
    return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;
  }

  ngOnInit(): void {
    this.isJogador = this.auth.isJogador();
    this.isEmpresa = this.auth.isEmpresa();

    if (isPlatformBrowser(this.platformId)) {
      this.ngZone.runOutsideAngular(() => {
        this.intervalId = setInterval(() => {
          this.ngZone.run(() => (this.now = new Date()));
        }, 60000);
      });

      const precisaReload = sessionStorage.getItem('reloadAfterLogin');
      if (precisaReload === 'true') {
        sessionStorage.removeItem('reloadAfterLogin');
        window.location.reload();
        return;
      }

      this.carregarArenas();
      this.carregarAssinatura();
      this.verificarContaMP();
    }
  }

  ngOnDestroy(): void {
    if (this.intervalId) clearInterval(this.intervalId);
  }

  verificarContaMP(): void {
    const email = this.auth.getEmail();
    this.http.get<any[]>(`${this.backendUrl}/empresa`).subscribe({
      next: (lista) => {
        const empresa = lista.find((e) => e.usuario?.email === email);
        this.mpConectada = empresa?.mpConectada ?? false;
      },
      error: () => {
        this.mpConectada = null;
      },
    });
  }

  conectarMercadoPago(): void {
    this.http
      .get(`${this.backendUrl}/pagamentos/oauth/conectar`, { responseType: 'text' })
      .subscribe({
        next: (url) => (window.location.href = url),
        error: () =>
          this.alertService.erro('Não foi possível iniciar a conexão com o Mercado Pago.'),
      });
  }

  carregarArenas(): void {
    this.carregandoArenas = true;
    this.quadraService.getMinhasArenas().subscribe({
      next: (arenas) => {
        this.arenas = arenas;
        this.carregandoArenas = false;
        if (arenas.length > 0) this.selecionarArena(arenas[0].id);
        arenas.forEach((a) => {
          this.quadraService.getQuadrasPorArena(a.id).subscribe({
            next: (qs) => this.quadrasPorArena.set(a.id, qs.length),
            error: () => this.quadrasPorArena.set(a.id, 0),
          });
        });
      },
      error: () => {
        this.alertService.erro('Não foi possível carregar as arenas.');
        this.carregandoArenas = false;
      },
    });
  }

  selecionarArena(id: number): void {
    this.arenaSelecionadaId = id;
    this.carregarQuadras();
  }

  get arenaSelecionada() {
    return this.arenas.find((a) => a.id === this.arenaSelecionadaId);
  }

  getFotoUrl(arena: any): string | null {
    if (!arena?.fotoUrl) return null;
    return arena.fotoUrl.startsWith('http') ? arena.fotoUrl : `${this.backendUrl}${arena.fotoUrl}`;
  }

  trocarFotoArena(arena: any, event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    const file = input.files[0];
    if (!file.type.startsWith('image/')) {
      this.alertService.erro('Selecione um arquivo de imagem válido.');
      input.value = '';
      return;
    }
    this.arenaSalvandoFotoId = arena.id;
    const payload: ArenaCadastroPayload = {
      nome: arena.nome,
      descricao: arena.descricao,
      endereco: arena.endereco,
    };
    this.arenaService.atualizar(arena.id, payload, file).subscribe({
      next: (atualizada) => {
        this.arenas = this.arenas.map((a) => (a.id === atualizada.id ? atualizada : a));
        if (this.arenaModalSelecionada?.id === atualizada.id)
          this.arenaModalSelecionada = atualizada;
        this.arenaSalvandoFotoId = null;
        this.alertService.sucesso('Foto da arena atualizada!');
        input.value = '';
      },
      error: (err) => {
        this.arenaSalvandoFotoId = null;
        this.alertService.erro(err?.error?.message || 'Erro ao atualizar a foto.');
        input.value = '';
      },
    });
  }

  abrirModalQuadras(arena: any): void {
    this.arenaModalSelecionada = arena;
    this.modalQuadrasAberto = true;
    this.selecionarArena(arena.id);
  }

  fecharModalQuadras(): void {
    this.modalQuadrasAberto = false;
    this.arenaModalSelecionada = null;
  }

  carregarQuadras(): void {
    if (!this.arenaSelecionadaId) return;
    this.carregandoQuadras = true;
    this.quadraService.getQuadrasPorArena(this.arenaSelecionadaId).subscribe({
      next: (q) => {
        this.quadras = q;
        this.carregandoQuadras = false;
      },
      error: () => {
        this.carregandoQuadras = false;
      },
    });
  }

  abrirModalNovaQuadra(): void {
    this.modoEdicao = false;
    this.quadraEditandoId = null;
    this.quadraEmEdicao = null;
    this.previewFotoEdicao = null;
    this.fotosCadastro = [];
    this.previewsCadastro = [];
    this.quadraForm.reset({ tipoCobertura: 'COBERTA' });
    this.modalQuadraAberto = true;
  }

  abrirModalEdicao(q: QuadraResponse): void {
    this.modoEdicao = true;
    this.quadraEditandoId = q.id;
    this.quadraEmEdicao = { ...q };
    this.previewFotoEdicao = null;
    this.quadraForm.setValue({
      nome: q.nome,
      tipoCobertura: q.tipoCobertura,
      valorHora: q.valorHora,
    });
    this.modalQuadraAberto = true;
  }

  fecharModalQuadra(): void {
    this.modalQuadraAberto = false;
    this.quadraEditandoId = null;
    this.quadraEmEdicao = null;
    this.previewFotoEdicao = null;
    this.fotosCadastro = [];
    this.previewsCadastro = [];
    this.modoEdicao = false;
    this.quadraForm.reset({ tipoCobertura: 'COBERTA' });
  }

  salvarQuadra(): void {
    if (this.quadraForm.invalid) {
      this.quadraForm.markAllAsTouched();
      return;
    }
    this.modoEdicao ? this.atualizarQuadra() : this.criarQuadra();
  }

  criarQuadra(): void {
    if (!this.arenaSelecionadaId) return;
    this.salvandoQuadra = true;
    this.quadraService.criarQuadra(this.arenaSelecionadaId, this.quadraForm.value).subscribe({
      next: (nova) => {
        this.salvandoQuadra = false;
        if (this.fotosCadastro.length > 0) {
          this.enviarFotosAposCadastro(nova, this.fotosCadastro);
        } else {
          this.quadras = [...this.quadras, nova];
          this.fecharModalQuadra();
          this.alertService.sucesso(`Quadra "${nova.nome}" cadastrada!`);
        }
      },
      error: (err) => {
        this.alertService.erro(err?.error?.message || 'Erro ao cadastrar quadra.');
        this.salvandoQuadra = false;
      },
    });
  }

  private enviarFotosAposCadastro(quadra: QuadraResponse, arquivos: File[]): void {
    const formData = new FormData();
    arquivos.forEach((f) => formData.append('fotos', f));
    this.http
      .post<QuadraResponse>(`${this.backendUrl}/quadras/${quadra.id}/fotos`, formData)
      .subscribe({
        next: (atualizada) => {
          this.quadras = [...this.quadras, atualizada];
          this.fecharModalQuadra();
          this.alertService.sucesso(`Quadra "${atualizada.nome}" cadastrada com fotos!`);
        },
        error: () => {
          this.quadras = [...this.quadras, quadra];
          this.fecharModalQuadra();
          this.alertService.aviso(`Quadra criada! Não foi possível enviar as fotos.`);
        },
      });
  }

  atualizarQuadra(): void {
    if (!this.quadraEditandoId) return;
    this.salvandoQuadra = true;
    this.quadraService.atualizarQuadra(this.quadraEditandoId, this.quadraForm.value).subscribe({
      next: (atualizada) => {
        this.quadras = this.quadras.map((q) => (q.id === atualizada.id ? atualizada : q));
        if (this.quadraEmEdicao?.id === atualizada.id) this.quadraEmEdicao = atualizada;
        this.salvandoQuadra = false;
        this.fecharModalQuadra();
        this.alertService.sucesso(`Quadra "${atualizada.nome}" atualizada!`);
      },
      error: (err) => {
        this.alertService.erro(err?.error?.message || 'Erro ao atualizar quadra.');
        this.salvandoQuadra = false;
      },
    });
  }

  excluirQuadra(q: QuadraResponse): void {
    this.alertService.aviso(`Deseja excluir a quadra "${q.nome}"?`).then((conf: any) => {
      if (!conf?.isConfirmed) return;
      this.quadraService.deletarQuadra(q.id).subscribe({
        next: () => {
          this.quadras = this.quadras.filter((x) => x.id !== q.id);
          this.alertService.sucesso('Quadra removida.');
        },
        error: (err) => this.alertService.erro(err?.error?.message || 'Erro ao excluir.'),
      });
    });
  }

  adicionarFotoCadastro(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;
    const novos = Array.from(input.files).filter((f) => f.size <= 5 * 1024 * 1024);
    const permitidos = novos.slice(0, Math.max(0, 5 - this.fotosCadastro.length));
    if (this.fotosCadastro.length + novos.length > 5) this.alertService.aviso('Máximo de 5 fotos.');
    permitidos.forEach((f) => {
      this.fotosCadastro.push(f);
      this.previewsCadastro.push(URL.createObjectURL(f));
    });
    input.value = '';
  }

  removerFotoCadastro(index: number): void {
    URL.revokeObjectURL(this.previewsCadastro[index]);
    this.fotosCadastro.splice(index, 1);
    this.previewsCadastro.splice(index, 1);
  }

  getFotoQuadraUrl(quadra: QuadraResponse): string | null {
    if (!quadra.fotos?.length) return null;
    const url = quadra.fotos[0];
    return url.startsWith('http') ? url : `${this.backendUrl}${url}`;
  }

  fotoUrlCompleta(url: string): string {
    return url.startsWith('http') ? url : `${this.backendUrl}${url}`;
  }

  selecionarFotoEdicao(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;
    const arquivo = input.files[0];
    if (arquivo.size > 5 * 1024 * 1024) {
      this.alertService.erro('Máximo 5MB.');
      input.value = '';
      return;
    }
    this.previewFotoEdicao = URL.createObjectURL(arquivo);
    this.enviarFotoQuadra(arquivo, this.quadraEmEdicao!);
    input.value = '';
  }

  private enviarFotoQuadra(arquivo: File, quadra: QuadraResponse): void {
    this.salvandoFotoQuadraId = quadra.id;
    const formData = new FormData();
    formData.append('fotos', arquivo);
    this.http
      .post<QuadraResponse>(`${this.backendUrl}/quadras/${quadra.id}/fotos`, formData)
      .subscribe({
        next: (atualizada) => {
          this.quadras = this.quadras.map((q) => (q.id === atualizada.id ? atualizada : q));
          this.quadraEmEdicao = atualizada;
          if (this.quadraDetalhe?.id === atualizada.id) this.quadraDetalhe = atualizada;
          this.previewFotoEdicao = null;
          this.salvandoFotoQuadraId = null;
          this.alertService.sucesso('Foto adicionada!');
        },
        error: () => {
          this.previewFotoEdicao = null;
          this.salvandoFotoQuadraId = null;
          this.alertService.erro('Erro ao enviar a foto.');
        },
      });
  }

  removerFotoQuadra(quadra: QuadraResponse, fotoUrl: string): void {
    const fotoId = Number(fotoUrl.split('/').pop());
    if (!fotoId) return;
    this.removendoFotoId = fotoId;
    this.http.delete<void>(`${this.backendUrl}/quadras/${quadra.id}/fotos/${fotoId}`).subscribe({
      next: () => {
        if (quadra.fotos) quadra.fotos = quadra.fotos.filter((f) => f !== fotoUrl);
        this.quadras = this.quadras.map((q) => (q.id === quadra.id ? { ...quadra } : q));
        if (this.quadraDetalhe?.id === quadra.id) {
          this.quadraDetalhe = { ...quadra };
          if (this.carrosselIndex >= (this.quadraDetalhe.fotos?.length ?? 0))
            this.carrosselIndex = 0;
        }
        this.removendoFotoId = null;
        this.alertService.sucesso('Foto removida.');
      },
      error: () => {
        this.removendoFotoId = null;
        this.alertService.erro('Erro ao remover a foto.');
      },
    });
  }

  adicionarFotoQuadra(event: Event, quadra: QuadraResponse): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;
    const arquivo = input.files[0];
    if (arquivo.size > 5 * 1024 * 1024) {
      this.alertService.erro('Máximo 5MB.');
      input.value = '';
      return;
    }
    this.enviarFotoQuadra(arquivo, quadra);
    input.value = '';
  }

  abrirDetalhe(q: QuadraResponse): void {
    this.quadraDetalhe = q;
    this.carrosselIndex = 0;
    this.modalDetalheAberto = true;
  }

  fecharDetalhe(): void {
    this.modalDetalheAberto = false;
    this.quadraDetalhe = null;
    this.carrosselIndex = 0;
  }

  carrosselAnterior(): void {
    const total = this.quadraDetalhe?.fotos?.length ?? 0;
    if (total === 0) return;
    this.carrosselIndex = (this.carrosselIndex - 1 + total) % total;
  }

  carrosselProximo(): void {
    const total = this.quadraDetalhe?.fotos?.length ?? 0;
    if (total === 0) return;
    this.carrosselIndex = (this.carrosselIndex + 1) % total;
  }

  irParaSlide(i: number): void {
    this.carrosselIndex = i;
  }

  abrirModalEdicaoArena(arena: any): void {
    this.arenaEmEdicao = { ...arena, endereco: { ...arena.endereco } };
    this.modalArenaEdicaoAberto = true;
  }

  fecharModalEdicaoArena(): void {
    this.modalArenaEdicaoAberto = false;
    this.arenaEmEdicao = null;
    this.salvandoArena = false;
  }

  salvarArena(): void {
    const a = this.arenaEmEdicao;
    if (!a) return;
    if (!a.nome?.trim() || !a.descricao?.trim()) {
      this.alertService.aviso('Nome e descrição são obrigatórios.');
      return;
    }
    this.salvandoArena = true;
    const payload: ArenaCadastroPayload = {
      nome: a.nome,
      descricao: a.descricao,
      endereco: a.endereco,
    };
    this.arenaService.atualizar(a.id, payload).subscribe({
      next: (atualizada) => {
        this.arenas = this.arenas.map((x) => (x.id === atualizada.id ? atualizada : x));
        if (this.arenaModalSelecionada?.id === atualizada.id)
          this.arenaModalSelecionada = atualizada;
        this.salvandoArena = false;
        this.fecharModalEdicaoArena();
        this.alertService.sucesso('Arena atualizada com sucesso!');
      },
      error: (err) => {
        this.salvandoArena = false;
        this.alertService.erro(err?.error?.message || 'Erro ao atualizar arena.');
      },
    });
  }

  excluirArena(arena: any): void {
    this.alertService
      .aviso(`Deseja excluir a arena "${arena.nome}"? Esta ação não pode ser desfeita.`)
      .then((conf: any) => {
        if (!conf?.isConfirmed) return;

        this.http
          .get<any[]>(`${this.backendUrl}/arenas/${arena.id}/horarios`)
          .pipe(
            switchMap((horarios) => {
              if (!horarios.length) return of(null);
              const deletes = horarios.map((h) =>
                this.http.delete(`${this.backendUrl}/arenas/${arena.id}/horarios/${h.diaSemana}`),
              );
              return forkJoin(deletes);
            }),
            switchMap(() => this.arenaService.deletar(arena.id)),
          )
          .subscribe({
            next: () => {
              this.quadrasPorArena.delete(arena.id);
              this.arenas = this.arenas.filter((a) => a.id !== arena.id);
              if (this.arenaSelecionadaId === arena.id) {
                this.arenaSelecionadaId = this.arenas[0]?.id ?? null;
                if (this.arenaSelecionadaId) this.carregarQuadras();
                else this.quadras = [];
              }
              this.fecharModalEdicaoArena();
              this.alertService.sucesso('Arena excluída.');
            },
            error: (err) => this.alertService.erro(err?.error?.message || 'Erro ao excluir arena.'),
          });
      });
  }

  abrirModalHorarios(arena: any): void {
    this.arenaHorariosSelecionada = arena;
    this.modalHorariosAberto = true;
    this.carregarHorarios(arena.id);
  }

  fecharModalHorarios(): void {
    this.modalHorariosAberto = false;
    this.arenaHorariosSelecionada = null;
    this.horarios = [];
  }

  carregarHorarios(arenaId: number): void {
    this.carregandoHorarios = true;
    this.http
      .get<HorarioFuncionamento[]>(`${this.backendUrl}/arenas/${arenaId}/horarios`)
      .subscribe({
        next: (h) => {
          this.horarios = h;
          this.carregandoHorarios = false;
        },
        error: () => {
          this.carregandoHorarios = false;
        },
      });
  }

  abrirReservas(q: QuadraResponse): void {
    this.quadraReservasSelecionada = q;
    this.carregandoReservas = true;
    this.modalReservasAberto = true;
    this.quadraService.getReservasPorQuadra(q.id).subscribe({
      next: (r) => {
        this.reservas = r;
        this.carregandoReservas = false;
      },
      error: () => {
        this.carregandoReservas = false;
      },
    });
  }

  fecharModalReservas(): void {
    this.modalReservasAberto = false;
    this.reservas = [];
    this.quadraReservasSelecionada = null;
  }

  confirmarReserva(r: ReservaResponse): void {
    this.quadraService.confirmarReserva(r.id).subscribe({
      next: (atualizada) => {
        this.reservas = this.reservas.map((x) => (x.id === atualizada.id ? atualizada : x));
        this.alertService.sucesso('Reserva confirmada!');
      },
      error: (err) => this.alertService.erro(err?.error?.message || 'Erro ao confirmar.'),
    });
  }

  cancelarReserva(r: ReservaResponse): void {
    this.quadraService.cancelarReserva(r.id).subscribe({
      next: (atualizada) => {
        this.reservas = this.reservas.map((x) => (x.id === atualizada.id ? atualizada : x));
        this.alertService.sucesso('Reserva cancelada.');
      },
      error: (err) => this.alertService.erro(err?.error?.message || 'Erro ao cancelar.'),
    });
  }

  carregarAssinatura(): void {
    this.quadraService.getMinhaAssinatura().subscribe({
      next: (a) => (this.assinatura = a),
      error: () => { },
    });
  }

  fazerUpgrade(): void {
    this.quadraService.upgradePremium().subscribe({
      next: (a) => {
        this.assinatura = a;
        this.alertService.sucesso('Upgrade para Premium realizado!');
      },
      error: (err) => this.alertService.erro(err?.error?.message || 'Erro no upgrade.'),
    });
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  formatarValor(v: number): string {
    return Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  formatarData(dt: string): string {
    return new Date(dt).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
  }

  duracaoHoras(inicio: string, fim: string): string {
    const min = (new Date(fim).getTime() - new Date(inicio).getTime()) / 60000;
    const h = Math.floor(min / 60);
    const m = min % 60;
    return m > 0 ? `${h}h${m}min` : `${h}h`;
  }

  reservasPendentes(): ReservaResponse[] {
    return this.reservas.filter((r) => r.status === 'PENDENTE');
  }

  totalHoje(): number {
    const hoje = new Date().toDateString();
    return this.reservas
      .filter(
        (r) => r.status === 'CONFIRMADA' && new Date(r.dataHoraInicio).toDateString() === hoje,
      )
      .reduce((s, r) => s + Number(r.valorTotal), 0);
  }

  statusClass(s: string): string {
    return (
      { PENDENTE: 'badge-pendente', CONFIRMADA: 'badge-confirmada', CANCELADA: 'badge-cancelada' }[
      s
      ] ?? ''
    );
  }
}
