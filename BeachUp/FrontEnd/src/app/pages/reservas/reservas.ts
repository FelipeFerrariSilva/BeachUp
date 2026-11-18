import { Component, NgZone, OnInit, PLATFORM_ID, inject } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';

export type TipoCobertura = 'COBERTA' | 'DESCOBERTA';
export type StatusReserva = 'PENDENTE' | 'CONFIRMADA' | 'CANCELADA';

export interface EnderecoArena {
  logradouro: string;
  numero: string;
  bairro: string;
  cidade: string;
  estado: string;
  cep: string;
}

export interface HorarioFuncionamento {
  id: number;
  diaSemana: string;
  diaSemanaLabel: string;
  horaAbertura: string;
  horaFechamento: string;
}

export interface Arena {
  id: number;
  nome: string;
  descricao: string;
  endereco: EnderecoArena;
  fotoUrl?: string | null;
  quadrasPreview?: Quadra[];
  distanciaKm?: number;
}

export interface Quadra {
  id: number;
  nome: string;
  tipoCobertura: TipoCobertura;
  valorHora: number;
  fotos?: string[];
}

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

const DIA_JS: Record<string, number> = {
  SUNDAY: 0,
  MONDAY: 1,
  TUESDAY: 2,
  WEDNESDAY: 3,
  THURSDAY: 4,
  FRIDAY: 5,
  SATURDAY: 6,
};

const ORDEM_DIA_SEMANA: Record<string, number> = {
  MONDAY: 0,
  TUESDAY: 1,
  WEDNESDAY: 2,
  THURSDAY: 3,
  FRIDAY: 4,
  SATURDAY: 5,
  SUNDAY: 6,
};

@Component({
  selector: 'app-reservas',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, MenuLateral, NavBar],
  templateUrl: './reservas.html',
  styleUrl: './reservas.css',
})
export class Reservas implements OnInit {
  private readonly API = 'http://localhost:8080';

  private ngZone = inject(NgZone);
  private platformId = inject(PLATFORM_ID);
  private intervalId?: ReturnType<typeof setInterval>;

  now = new Date();

  isJogador = false;
  isEmpresa = false;
  modalAberto = false;
  fotoCarrosselIndex = 0;
  quadraSelecionada: Quadra | null = null;
  reservaForm: FormGroup;
  minDataHora = '';
  minData = '';
  salvando = false;

  arenas: Arena[] = [];
  arenasFiltradas: Arena[] = [];
  termoBusca = '';
  carregandoArenas = false;
  modalArenaAberto = false;
  arenaSelecionada: Arena | null = null;
  quadrasDaArena: Quadra[] = [];
  carregandoQuadrasDaArena = false;

  horariosArena: HorarioFuncionamento[] = [];
  carregandoHorarios = false;

  quadrasDono: Quadra[] = [];
  quadraSelecionadaDono: Quadra | null = null;
  reservasDaQuadra: Reserva[] = [];
  carregandoQuadrasDono = false;
  carregandoReservasDono = false;

  buscandoArenasPerto = false;
  arenasProximas: Arena[] = [];
  erroGeo = '';

  constructor(
    private http: HttpClient,
    private fb: FormBuilder,
    private alertService: AlertService,
    public navigation: NavigationService,
    public auth: AuthService,
  ) {
    this.reservaForm = this.fb.group(
      {
        dataReserva: ['', Validators.required],
        horaInicio: ['', Validators.required],
        horaFim: ['', Validators.required],
      },
      { validators: this.validarPeriodo },
    );

    const agora = new Date();
    agora.setMinutes(agora.getMinutes() + 60);
    this.minDataHora = agora.toISOString().slice(0, 16);
    this.minData = agora.toISOString().slice(0, 10);
  }

  readonly horasTodas = Array.from({ length: 24 }, (_, h) => h);

  get horasDisponiveis(): number[] {
    const data = this.reservaForm.get('dataReserva')?.value;
    if (!data || this.horariosArena.length === 0) return this.horasTodas;

    const diaSemana = new Date(data + 'T12:00:00').getDay();
    const javaKey = Object.keys(DIA_JS).find((k) => DIA_JS[k] === diaSemana);
    if (!javaKey) return this.horasTodas;

    const horario = this.horariosArena.find((h) => h.diaSemana === javaKey);
    if (!horario) return [];

    const abre = parseInt(horario.horaAbertura.split(':')[0], 10);
    const fecha = parseInt(horario.horaFechamento.split(':')[0], 10);
    return Array.from({ length: fecha - abre }, (_, i) => abre + i);
  }

  get horasDispFim(): number[] {
    const inicio = this.reservaForm.get('horaInicio')?.value;
    if (inicio === '' || inicio === null) return this.horasDisponiveis;
    return this.horasDisponiveis.filter((h) => h > Number(inicio));
  }

  get horarioDoDiaSelecionado(): HorarioFuncionamento | null {
    const data = this.reservaForm.get('dataReserva')?.value;
    if (!data || this.horariosArena.length === 0) return null;

    const diaSemana = new Date(data + 'T12:00:00').getDay();
    const javaKey = Object.keys(DIA_JS).find((k) => DIA_JS[k] === diaSemana);
    if (!javaKey) return null;
    return this.horariosArena.find((h) => h.diaSemana === javaKey) ?? null;
  }

  ngOnInit(): void {
    this.isJogador = this.auth.isJogador();
    this.isEmpresa = this.auth.isEmpresa();

    if (isPlatformBrowser(this.platformId)) {
      const precisaReload = sessionStorage.getItem('reloadAfterLogin');
      if (precisaReload === 'true') {
        sessionStorage.removeItem('reloadAfterLogin');
        window.location.reload();
        return;
      }

      this.ngZone.runOutsideAngular(() => {
        this.intervalId = setInterval(() => {
          this.ngZone.run(() => (this.now = new Date()));
        }, 60000);
      });
    }

    if (this.isJogador) {
      this.carregarArenas();
    } else if (this.isEmpresa) {
      this.carregarQuadrasDono();
    }
  }

  ngOnDestroy(): void {
    if (this.intervalId) clearInterval(this.intervalId);
  }

  filtrarArenas(): void {
    const termo = this.termoBusca.toLowerCase().trim();
    if (!termo) {
      this.arenasFiltradas = [...this.arenas];
      return;
    }
    this.arenasFiltradas = this.arenas.filter((a) => {
      const nome = a.nome?.toLowerCase() ?? '';
      const bairro = a.endereco?.bairro?.toLowerCase() ?? '';
      const cidade = a.endereco?.cidade?.toLowerCase() ?? '';
      const logradouro = a.endereco?.logradouro?.toLowerCase() ?? '';
      return (
        nome.includes(termo) ||
        bairro.includes(termo) ||
        cidade.includes(termo) ||
        logradouro.includes(termo)
      );
    });
  }

  limparBusca(): void {
    this.termoBusca = '';
    this.arenasFiltradas = [...this.arenas];
  }

  carregarArenas(): void {
    this.carregandoArenas = true;
    this.http.get<Arena[]>(`${this.API}/arenas`).subscribe({
      next: (arenas) => {
        this.arenas = arenas;
        this.arenasFiltradas = [...arenas];
        this.carregandoArenas = false;
      },
      error: (err) => {
        this.carregandoArenas = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  getFotoUrl(arena: Arena): string | null {
    if (!arena?.fotoUrl) return null;
    return arena.fotoUrl.startsWith('http') ? arena.fotoUrl : `${this.API}${arena.fotoUrl}`;
  }

  getFotoQuadraUrl(quadra: Quadra): string | null {
    if (!quadra?.fotos || quadra.fotos.length === 0) return null;
    const primeira = quadra.fotos[0];
    return primeira.startsWith('http') ? primeira : `${this.API}${primeira}`;
  }

  abrirModalArena(arena: Arena): void {
    this.arenaSelecionada = arena;
    this.modalArenaAberto = true;
    this.carregarQuadrasDaArena(arena.id);
    this.carregarHorariosArena(arena.id);
  }

  fecharModalArena(): void {
    this.modalArenaAberto = false;
    this.arenaSelecionada = null;
    this.quadrasDaArena = [];
    this.horariosArena = [];
  }

  carregarQuadrasDaArena(arenaId: number): void {
    this.carregandoQuadrasDaArena = true;
    this.quadrasDaArena = [];
    this.http.get<Quadra[]>(`${this.API}/quadras/arena/${arenaId}`).subscribe({
      next: (quadras) => {
        this.quadrasDaArena = quadras;
        this.carregandoQuadrasDaArena = false;
      },
      error: (err) => {
        this.carregandoQuadrasDaArena = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  carregarHorariosArena(arenaId: number): void {
    this.carregandoHorarios = true;
    this.horariosArena = [];
    this.http.get<HorarioFuncionamento[]>(`${this.API}/arenas/${arenaId}/horarios`).subscribe({
      next: (horarios) => {
        this.horariosArena = [...horarios].sort(
          (a, b) => ORDEM_DIA_SEMANA[a.diaSemana] - ORDEM_DIA_SEMANA[b.diaSemana],
        );
        this.carregandoHorarios = false;
      },
      error: () => {
        this.carregandoHorarios = false;
      },
    });
  }

  abrirModal(quadra: Quadra): void {
    this.quadraSelecionada = quadra;
    this.fotoCarrosselIndex = 0;
    this.reservaForm.reset();
    this.reservaForm.patchValue({ dataReserva: this.minData });
    this.modalArenaAberto = false;
    this.modalAberto = true;
  }

  fecharModal(): void {
    this.modalAberto = false;
    this.quadraSelecionada = null;
    this.fotoCarrosselIndex = 0;
    if (this.arenaSelecionada) {
      this.modalArenaAberto = true;
    }
  }

  get fotosCarrosselUrls(): string[] {
    const fotos = this.quadraSelecionada?.fotos ?? [];
    return fotos.map((f) => (f.startsWith('http') ? f : `${this.API}${f}`));
  }

  fotoAnterior(): void {
    const total = this.fotosCarrosselUrls.length;
    if (total === 0) return;
    this.fotoCarrosselIndex = (this.fotoCarrosselIndex - 1 + total) % total;
  }

  proximaFoto(): void {
    const total = this.fotosCarrosselUrls.length;
    if (total === 0) return;
    this.fotoCarrosselIndex = (this.fotoCarrosselIndex + 1) % total;
  }

  irParaFoto(index: number): void {
    this.fotoCarrosselIndex = index;
  }

  reservar(): void {
    if (this.reservaForm.invalid) {
      this.reservaForm.markAllAsTouched();
      this.alertService.avisoCamposObrigatorios();
      return;
    }

    this.salvando = true;
    const { dataReserva, horaInicio, horaFim } = this.reservaForm.value;

    const inicio = this.montarDataHora(dataReserva, horaInicio);
    const fim = this.montarDataHora(dataReserva, horaFim);

    const payload = {
      quadraId: this.quadraSelecionada!.id,
      dataHoraInicio: this.toLocalIso(inicio),
      dataHoraFim: this.toLocalIso(fim),
    };

    this.http.post<Reserva>(`${this.API}/reservas`, payload).subscribe({
      next: (nova) => {
        this.fecharModal();
        this.fecharModalArena();
        this.iniciarPagamentoReserva(nova.id);
      },
      error: (err) => {
        this.salvando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  private iniciarPagamentoReserva(reservaId: number): void {
    this.http
      .post<{
        preferenceId: string;
        initPoint: string;
        sandboxInitPoint: string;
      }>(`${this.API}/pagamentos/reserva/${reservaId}/iniciar`, {})
      .subscribe({
        next: (checkout) => {
          this.salvando = false;
          window.location.href = checkout.initPoint;
        },
        error: (err) => {
          this.salvando = false;
          this.alertService.erroHttp(err);
          this.alertService.aviso(
            'A reserva foi criada, mas não foi possível abrir o pagamento. Acesse "Minhas Reservas" para tentar pagar novamente.',
          );
        },
      });
  }

  carregarQuadrasDono(): void {
    this.carregandoQuadrasDono = true;
    this.http.get<Quadra[]>(`${this.API}/quadras`).subscribe({
      next: (quadras) => {
        this.quadrasDono = quadras;
        this.carregandoQuadrasDono = false;
        if (quadras.length > 0) this.selecionarQuadraDono(quadras[0]);
      },
      error: (err) => {
        this.carregandoQuadrasDono = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  selecionarQuadraDono(quadra: Quadra): void {
    this.quadraSelecionadaDono = quadra;
    this.carregarReservasDaQuadra(quadra.id);
  }

  carregarReservasDaQuadra(quadraId: number): void {
    this.carregandoReservasDono = true;
    this.reservasDaQuadra = [];
    this.http.get<Reserva[]>(`${this.API}/reservas/quadra/${quadraId}`).subscribe({
      next: (reservas) => {
        this.reservasDaQuadra = reservas.sort(
          (a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime(),
        );
        this.carregandoReservasDono = false;
      },
      error: (err) => {
        this.carregandoReservasDono = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  confirmarReservaDono(reserva: Reserva): void {
    this.http.patch<Reserva>(`${this.API}/reservas/${reserva.id}/confirmar`, {}).subscribe({
      next: (atualizada) => {
        this.reservasDaQuadra = this.reservasDaQuadra.map((r) =>
          r.id === atualizada.id ? atualizada : r,
        );
        this.alertService.sucesso('Reserva confirmada!');
      },
      error: (err) => this.alertService.erroHttp(err),
    });
  }

  cancelarReservaDono(reserva: Reserva): void {
    this.alertService.confirmarExclusao(`a reserva de ${reserva.nomeJogador}`).then((result) => {
      if (!result.isConfirmed) return;
      this.http.patch<Reserva>(`${this.API}/reservas/${reserva.id}/cancelar`, {}).subscribe({
        next: (atualizada) => {
          this.reservasDaQuadra = this.reservasDaQuadra.map((r) =>
            r.id === atualizada.id ? atualizada : r,
          );
          this.alertService.sucesso('Reserva cancelada.');
        },
        error: (err) => this.alertService.erroHttp(err),
      });
    });
  }

  buscarArenasPerto(): void {
    if (!('geolocation' in navigator)) {
      this.alertService.aviso('Seu navegador não suporta geolocalização.');
      return;
    }

    this.buscandoArenasPerto = true;
    this.erroGeo = '';

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;

        this.http
          .post<Arena[]>(`${this.API}/arenas/proximidade`, {
            latitude: lat,
            longitude: lng,
            raioKm: 10,
          })
          .subscribe({
            next: (arenas) => {
              this.buscandoArenasPerto = false;
              this.arenasProximas = arenas;
              if (arenas.length === 0) {
                this.alertService.aviso('Nenhuma arena encontrada num raio de 10 km.');
              }
            },
            error: () => {
              this.buscandoArenasPerto = false;
              this.erroGeo = 'Erro ao buscar arenas próximas.';
            },
          });
      },
      (err) => {
        this.buscandoArenasPerto = false;
        if (err.code === err.PERMISSION_DENIED) {
          this.alertService.aviso(
            'Permissão de localização negada. Ative nas configurações do navegador.',
          );
        } else {
          this.alertService.erro('Não foi possível obter sua localização.');
        }
      },
      { timeout: 10000, enableHighAccuracy: true },
    );
  }

  get reservasPendentes(): number {
    return this.reservasDaQuadra.filter((r) => r.status === 'PENDENTE').length;
  }

  get duracaoHoras(): number {
    const { horaInicio, horaFim } = this.reservaForm.value;
    if (horaInicio === '' || horaInicio === null || horaFim === '' || horaFim === null) return 0;
    const diff = Number(horaFim) - Number(horaInicio);
    return Math.max(0, diff);
  }

  get valorEstimado(): number {
    if (!this.quadraSelecionada) return 0;
    return this.duracaoHoras * this.quadraSelecionada.valorHora;
  }

  private montarDataHora(data: string, hora: number | string): Date {
    const [ano, mes, dia] = data.split('-').map(Number);
    return new Date(ano, mes - 1, dia, Number(hora), 0, 0);
  }

  private toLocalIso(d: Date): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
  }

  validarPeriodo(form: any) {
    const data = form.get('dataReserva')?.value;
    const horaInicio = form.get('horaInicio')?.value;
    const horaFim = form.get('horaFim')?.value;
    if (!data || horaInicio === '' || horaInicio === null || horaFim === '' || horaFim === null) {
      return null;
    }
    return Number(horaFim) > Number(horaInicio) ? null : { periodoInvalido: true };
  }

  podeCancelar(reserva: Reserva): boolean {
    if (reserva.status === 'CANCELADA') return false;
    const inicio = new Date(reserva.dataHoraInicio).getTime();
    return inicio - Date.now() > 24 * 3_600_000;
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

  labelCobertura(tipo: TipoCobertura): string {
    return tipo === 'COBERTA' ? 'Coberta' : 'Descoberta';
  }

  campoInvalido(campo: string): boolean {
    const c = this.reservaForm.get(campo);
    return !!(c && c.invalid && c.touched);
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: { id: number }) {
    return item.id;
  }
}
