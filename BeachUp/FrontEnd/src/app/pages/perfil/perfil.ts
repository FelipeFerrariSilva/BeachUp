import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  ReactiveFormsModule,
  FormBuilder,
  FormGroup,
  Validators,
  AbstractControl,
  ValidationErrors,
} from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { forkJoin, of } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import { NgxMaskDirective } from 'ngx-mask';
import { AuthService } from '../../shared/services/auth.service';
import { ArenaService } from '../../shared/services/arena.service';
import { QuadraService } from '../../shared/services/quadra.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { ArenaResponse } from '../../shared/services/models/arena.model';
import { ReservaResponse, AssinaturaResponse } from '../../shared/services/models/quadra.model';

interface UsuarioInfo {
  nome: string;
  email: string;
  role: string;
  fotoUrl?: string | null;
  dataCadastro?: string | null;
}

export interface EventoAtividade {
  icone: string;
  titulo: string;
  sub: string;
  tipo: 'reserva' | 'conquista' | 'conta' | 'cancelamento' | 'arena';
  badge: string;
  data?: string;
}

interface JogadorPerfil {
  id: number;
  cpf: string;
  usuario: UsuarioInfo;
}

interface EmpresaPerfil {
  id: number;
  cnpj: string;
  planoAtual: string;
  usuario: UsuarioInfo;
}

interface JogadorAtualizadoDTO {
  id: number;
  cpf: string;
  usuario: UsuarioInfo;
  accessToken: string | null;
  refreshToken: string | null;
}

interface EmpresaAtualizadaDTO {
  id: number;
  cnpj: string;
  planoAtual: string;
  usuario: UsuarioInfo;
  accessToken: string | null;
  refreshToken: string | null;
}

@Component({
  selector: 'app-perfil',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NgxMaskDirective, MenuLateral, NavBar],
  templateUrl: './perfil.html',
  styleUrl: './perfil.css',
})
export class Perfil implements OnInit {
  private http = inject(HttpClient);
  private fb = inject(FormBuilder);
  private arenaService = inject(ArenaService);
  private quadraService = inject(QuadraService);
  public auth = inject(AuthService);
  public navigation = inject(NavigationService);
  private alertService = inject(AlertService);

  private readonly API = 'http://localhost:8080';

  isJogador = false;
  isEmpresa = false;
  carregando = true;
  mostrarSenha = false;

  jogador: JogadorPerfil | null = null;
  empresa: EmpresaPerfil | null = null;

  totalReservasMes = 0;
  totalQuadrasAtivas = 0;
  taxaOcupacao = 0;
  assinatura: AssinaturaResponse | null = null;
  eventoAtividade: EventoAtividade[] = [];

  modalEdicaoAberto = false;
  salvando = false;
  arquivoFoto: File | null = null;
  previewFoto: string | null = null;

  modalAtividadeAberto = false;
  todasAtividades: EventoAtividade[] = [];

  editForm: FormGroup = this.fb.group(
    {
      nome: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      documento: ['', [Validators.required]],
      senha: [''],
      confirmarSenha: [''],
    },
    { validators: this.senhasIguaisValidator },
  );

  ngOnInit(): void {
    this.isJogador = this.auth.isJogador();
    this.isEmpresa = this.auth.isEmpresa();
    this.carregarPerfil();
  }

  carregarPerfil(): void {
    const email = this.auth.getEmail();
    if (!email) {
      this.carregando = false;
      return;
    }

    if (this.isJogador) {
      this.http.get<JogadorPerfil[]>(`${this.API}/jogador`).subscribe({
        next: (lista) => {
          this.jogador = lista.find((j) => j.usuario?.email === email) ?? null;
          this.carregando = false;
          this.carregarDadosJogador();
        },
        error: () => (this.carregando = false),
      });
    } else if (this.isEmpresa) {
      this.http.get<EmpresaPerfil[]>(`${this.API}/empresa`).subscribe({
        next: (lista) => {
          this.empresa = lista.find((e) => e.usuario?.email === email) ?? null;
          this.carregando = false;
          this.carregarDadosEmpresa();
        },
        error: () => (this.carregando = false),
      });
    } else {
      this.carregando = false;
    }
  }

  private carregarDadosEmpresa(): void {
    this.quadraService
      .getMinhaAssinatura()
      .pipe(catchError(() => of(null)))
      .subscribe((a) => (this.assinatura = a));

    this.arenaService
      .getMinhas()
      .pipe(
        catchError(() => of([] as ArenaResponse[])),
        switchMap((arenas: ArenaResponse[]) => {
          if (!arenas.length) return of({ arenas, quadrasPorArena: [] as any[] });

          const quadraRequests = arenas.map((a) =>
            this.quadraService.getQuadrasPorArena(a.id).pipe(
              map((quadras) => ({ arenaId: a.id, quadras })),
              catchError(() => of({ arenaId: a.id, quadras: [] })),
            ),
          );

          return forkJoin(quadraRequests).pipe(
            map((quadrasPorArena) => ({ arenas, quadrasPorArena })),
          );
        }),
        switchMap(({ quadrasPorArena }) => {
          this.totalQuadrasAtivas = quadrasPorArena.reduce(
            (sum: number, a: any) => sum + a.quadras.length,
            0,
          );

          const todasQuadras = quadrasPorArena.flatMap((a: any) => a.quadras);
          if (!todasQuadras.length) return of([]);

          const reservaRequests = todasQuadras.map((q: any) =>
            this.quadraService
              .getReservasPorQuadra(q.id)
              .pipe(catchError(() => of([] as ReservaResponse[]))),
          );

          return forkJoin(reservaRequests).pipe(
            map((listas: ReservaResponse[][]) => listas.flat()),
          );
        }),
        catchError(() => of([] as ReservaResponse[])),
      )
      .subscribe((reservas: ReservaResponse[]) => {
        this.calcularKpisEmpresa(reservas);
        this.gerarAtividadeEmpresa(reservas);
      });
  }

  private calcularKpisEmpresa(reservas: ReservaResponse[]): void {
    const agora = new Date();
    const mesAtu = agora.getMonth();
    const anoAtu = agora.getFullYear();

    this.totalReservasMes = reservas.filter((r) => {
      const d = new Date(r.dataHoraInicio);
      return d.getMonth() === mesAtu && d.getFullYear() === anoAtu && r.status === 'CONFIRMADA';
    }).length;

    const confirmadas = reservas.filter((r) => r.status === 'CONFIRMADA').length;
    this.taxaOcupacao = reservas.length ? Math.round((confirmadas / reservas.length) * 100) : 0;
  }

  private carregarDadosJogador(): void {
    this.http
      .get<ReservaResponse[]>(`${this.API}/reservas/minhas`)
      .pipe(catchError(() => of([] as ReservaResponse[])))
      .subscribe((reservas: ReservaResponse[]) => {
        const agora = new Date();
        const mesAtu = agora.getMonth();
        const anoAtu = agora.getFullYear();

        this.totalReservasMes = reservas.filter((r) => {
          const d = new Date(r.dataHoraInicio);
          return d.getMonth() === mesAtu && d.getFullYear() === anoAtu && r.status === 'CONFIRMADA';
        }).length;

        this.gerarAtividadeJogador(reservas);
      });
  }

  private gerarAtividadeJogador(reservas: ReservaResponse[]): void {
    const eventos: EventoAtividade[] = [];

    const confirmadas = [...reservas]
      .filter((r) => r.status === 'CONFIRMADA')
      .sort((a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime());

    confirmadas.forEach((r) => {
      eventos.push({
        icone: 'bi-calendar-check-fill',
        titulo: `Reserva confirmada — ${r.nomeQuadra}`,
        sub: this.formatarDataCurta(r.dataHoraInicio),
        tipo: 'reserva',
        badge: 'Reserva',
        data: r.dataHoraInicio,
      });
    });

    const canceladas = [...reservas]
      .filter((r) => r.status === 'CANCELADA')
      .sort((a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime());

    canceladas.forEach((r) => {
      eventos.push({
        icone: 'bi-calendar-x-fill',
        titulo: `Reserva cancelada — ${r.nomeQuadra}`,
        sub: this.formatarDataCurta(r.dataHoraInicio),
        tipo: 'cancelamento',
        badge: 'Cancelamento',
        data: r.dataHoraInicio,
      });
    });

    if (confirmadas.length >= 100) {
      eventos.push({
        icone: 'bi-trophy-fill',
        titulo: 'Você completou 100 reservas!',
        sub: 'Conquista desbloqueada',
        tipo: 'conquista',
        badge: 'Conquista',
      });
    }

    if (confirmadas.length >= 10) {
      eventos.push({
        icone: 'bi-award-fill',
        titulo: 'Você completou 10 reservas!',
        sub: 'Conquista desbloqueada',
        tipo: 'conquista',
        badge: 'Conquista',
      });
    }

    if (confirmadas.length >= 1) {
      eventos.push({
        icone: 'bi-star-fill',
        titulo: 'Primeira reserva realizada!',
        sub: 'Bem-vindo ao BeachUp',
        tipo: 'conquista',
        badge: 'Conquista',
        data: confirmadas[confirmadas.length - 1]?.dataHoraInicio,
      });
    }

    const dataConta = this.jogador?.usuario?.dataCadastro;
    eventos.push({
      icone: 'bi-shield-check-fill',
      titulo: 'Conta criada no BeachUp',
      sub: dataConta ? this.formatarDataCurta(dataConta) : 'Bem-vindo!',
      tipo: 'conta',
      badge: 'Conta',
      data: dataConta ?? undefined,
    });

    eventos.sort((a, b) => {
      if (!a.data && !b.data) return 0;
      if (!a.data) return 1;
      if (!b.data) return -1;
      return new Date(b.data).getTime() - new Date(a.data).getTime();
    });

    this.todasAtividades = eventos;
    this.eventoAtividade = eventos.slice(0, 5);
  }

  private gerarAtividadeEmpresa(reservas: ReservaResponse[]): void {
    const eventos: EventoAtividade[] = [];

    const confirmadas = [...reservas]
      .filter((r) => r.status === 'CONFIRMADA')
      .sort((a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime());

    confirmadas.forEach((r) => {
      eventos.push({
        icone: 'bi-calendar-check-fill',
        titulo: `Reserva confirmada — ${r.nomeQuadra}`,
        sub: `${r.nomeJogador} · ${this.formatarDataCurta(r.dataHoraInicio)}`,
        tipo: 'reserva',
        badge: 'Reserva',
        data: r.dataHoraInicio,
      });
    });

    const canceladas = [...reservas]
      .filter((r) => r.status === 'CANCELADA')
      .sort((a, b) => new Date(b.dataHoraInicio).getTime() - new Date(a.dataHoraInicio).getTime());

    canceladas.forEach((r) => {
      eventos.push({
        icone: 'bi-calendar-x-fill',
        titulo: `Reserva cancelada — ${r.nomeQuadra}`,
        sub: `${r.nomeJogador} · ${this.formatarDataCurta(r.dataHoraInicio)}`,
        tipo: 'cancelamento',
        badge: 'Cancelamento',
        data: r.dataHoraInicio,
      });
    });

    if (this.assinatura) {
      eventos.push({
        icone: 'bi-shield-check-fill',
        titulo: `Plano ${this.assinatura.nome} ativado`,
        sub: `Desde ${this.formatarDataCurta(this.assinatura.dataInicio)}`,
        tipo: 'conta',
        badge: 'Conta',
        data: this.assinatura.dataInicio,
      });
    }

    if (this.totalQuadrasAtivas > 0) {
      eventos.push({
        icone: 'bi-geo-alt-fill',
        titulo: `${this.totalQuadrasAtivas} quadra${this.totalQuadrasAtivas > 1 ? 's' : ''} ativa${this.totalQuadrasAtivas > 1 ? 's' : ''}`,
        sub: 'Todas operando normalmente',
        tipo: 'arena',
        badge: 'Arena',
      });
    }

    const dataConta = this.empresa?.usuario?.dataCadastro;
    if (dataConta) {
      eventos.push({
        icone: 'bi-building-check',
        titulo: 'Empresa cadastrada no BeachUp',
        sub: this.formatarDataCurta(dataConta),
        tipo: 'conta',
        badge: 'Conta',
        data: dataConta,
      });
    }

    eventos.sort((a, b) => {
      if (!a.data && !b.data) return 0;
      if (!a.data) return 1;
      if (!b.data) return -1;
      return new Date(b.data).getTime() - new Date(a.data).getTime();
    });

    this.todasAtividades = eventos;
    this.eventoAtividade = eventos.slice(0, 5);
  }

  get nomeExibido(): string {
    return this.jogador?.usuario?.nome ?? this.empresa?.usuario?.nome ?? '—';
  }

  get emailExibido(): string {
    return this.jogador?.usuario?.email ?? this.empresa?.usuario?.email ?? '—';
  }

  get fotoUrlBruta(): string | null {
    return this.jogador?.usuario?.fotoUrl ?? this.empresa?.usuario?.fotoUrl ?? null;
  }

  get fotoExibida(): string | null {
    const url = this.fotoUrlBruta;
    if (!url) return null;
    return url.startsWith('http') ? url : `${this.API}${url}`;
  }

  get documentoBruto(): string {
    return this.jogador?.cpf ?? this.empresa?.cnpj ?? '';
  }

  get documentoExibido(): string {
    if (this.jogador?.cpf) return this.mascaraCpf(this.jogador.cpf);
    if (this.empresa?.cnpj) return this.mascaraCnpj(this.empresa.cnpj);
    return '—';
  }

  get labelDocumento(): string {
    return this.isJogador ? 'CPF' : 'CNPJ';
  }
  get mascaraDocumento(): string {
    return this.isJogador ? '000.000.000-00' : '00.000.000/0000-00';
  }
  get roleLabel(): string {
    return this.isJogador ? 'Jogador' : 'Empresa';
  }
  get planoBadge(): string {
    return this.empresa?.planoAtual ?? '';
  }

  get membroDesde(): string {
    return this.auth.getIssuedAt() ?? '—';
  }

  abrirEdicao(): void {
    this.editForm.reset();
    this.editForm.patchValue({
      nome: this.nomeExibido,
      email: this.emailExibido,
      documento: this.documentoBruto,
    });
    this.mostrarSenha = false;
    this.arquivoFoto = null;
    this.previewFoto = null;
    this.modalEdicaoAberto = true;
  }

  fecharEdicao(): void {
    this.modalEdicaoAberto = false;
    this.arquivoFoto = null;
    this.previewFoto = null;
  }

  selecionarFoto(event: Event): void {
    const input = event.target as HTMLInputElement;
    const arquivo = input.files?.[0];
    if (!arquivo) return;

    if (!arquivo.type.startsWith('image/')) {
      this.alertService.aviso('Selecione um arquivo de imagem válido.');
      input.value = '';
      return;
    }
    if (arquivo.size > 5 * 1024 * 1024) {
      this.alertService.aviso('A imagem deve ter no máximo 5MB.');
      input.value = '';
      return;
    }

    this.arquivoFoto = arquivo;
    const leitor = new FileReader();
    leitor.onload = () => (this.previewFoto = leitor.result as string);
    leitor.readAsDataURL(arquivo);
  }

  VerSenha(): void {
    this.mostrarSenha = !this.mostrarSenha;
  }

  salvarEdicao(): void {
    if (this.editForm.invalid) {
      this.editForm.markAllAsTouched();
      if (this.editForm.hasError('senhasDiferentes')) {
        this.alertService.aviso('As senhas não coincidem.');
      }
      return;
    }

    const { nome, email, documento, senha, confirmarSenha } = this.editForm.value;
    const documentoLimpo = (documento ?? '').replace(/\D/g, '');
    const payload: any = { nome, email };

    if (this.isJogador) payload.cpf = documentoLimpo;
    if (this.isEmpresa) payload.cnpj = documentoLimpo;
    if (senha) {
      payload.senha = senha;
      payload.confirmarSenha = confirmarSenha;
    }

    const id = this.jogador?.id ?? this.empresa?.id;
    if (!id) {
      this.alertService.erro('Não foi possível identificar seu cadastro.');
      return;
    }

    const formData = new FormData();
    formData.append('dados', new Blob([JSON.stringify(payload)], { type: 'application/json' }));
    if (this.arquivoFoto) formData.append('foto', this.arquivoFoto);

    this.salvando = true;
    const url = this.isJogador ? `${this.API}/jogador/${id}` : `${this.API}/empresa/${id}`;

    if (this.isJogador) {
      this.http.put<JogadorAtualizadoDTO>(url, formData).subscribe({
        next: (res) => {
          this.salvando = false;

          if (res.accessToken) {
            this.auth.atualizarToken(res.accessToken, res.refreshToken);
          }

          if (this.jogador) {
            this.jogador = {
              ...this.jogador,
              cpf: res.cpf,
              usuario: { ...this.jogador.usuario, ...res.usuario },
            };
          }

          this.fecharEdicao();
          this.alertService.sucesso('Perfil atualizado com sucesso!').then(() => {
            window.location.reload();
          });
        },
        error: (err) => {
          this.salvando = false;
          const msg =
            err?.error?.message ?? err?.error ?? 'Erro ao salvar alterações. Tente novamente.';
          this.alertService.erro(msg);
        },
      });
    } else {
      this.http.put<EmpresaAtualizadaDTO>(url, formData).subscribe({
        next: (res) => {
          this.salvando = false;

          if (res.accessToken) {
            this.auth.atualizarToken(res.accessToken, res.refreshToken);
          }

          if (this.empresa) {
            this.empresa = {
              ...this.empresa,
              cnpj: res.cnpj,
              planoAtual: res.planoAtual ?? this.empresa.planoAtual,
              usuario: { ...this.empresa.usuario, ...res.usuario },
            };
          }

          this.fecharEdicao();
          this.alertService.sucesso('Perfil atualizado com sucesso!').then(() => {
            window.location.reload();
          });
        },
        error: (err) => {
          this.salvando = false;
          const msg =
            err?.error?.message ?? err?.error ?? 'Erro ao salvar alterações. Tente novamente.';
          this.alertService.erro(msg);
        },
      });
    }
  }

  confirmarSair(): void {
    this.alertService.Sair().then((res) => {
      if (res.isConfirmed) {
        this.auth.logout();
        this.navigation.irPara('home');
      }
    });
  }

  campoInvalido(campo: string): boolean {
    const c = this.editForm.get(campo);
    return !!(c?.invalid && c.touched);
  }

  senhasIguaisValidator(form: AbstractControl): ValidationErrors | null {
    const senha = form.get('senha')?.value;
    const confirmarSenha = form.get('confirmarSenha')?.value;
    if (!senha && !confirmarSenha) return null;
    return senha === confirmarSenha ? null : { senhasDiferentes: true };
  }

  private mascaraCpf(cpf: string): string {
    const n = cpf.replace(/\D/g, '');
    return n.length === 11
      ? `${n.slice(0, 3)}.${n.slice(3, 6)}.${n.slice(6, 9)}-${n.slice(9)}`
      : cpf;
  }

  private mascaraCnpj(cnpj: string): string {
    const n = cnpj.replace(/\D/g, '');
    return n.length === 14
      ? `${n.slice(0, 2)}.${n.slice(2, 5)}.${n.slice(5, 8)}/${n.slice(8, 12)}-${n.slice(12)}`
      : cnpj;
  }

  private formatarDataCurta(dt: string): string {
    return new Date(dt).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  }

  formatarDataMembro(dt?: string | null): string {
    if (!dt) return '—';
    return new Date(dt).toLocaleDateString('pt-BR', { month: 'short', year: 'numeric' });
  }

  abrirModalAtividade(): void {
    this.modalAtividadeAberto = true;
  }

  fecharModalAtividade(): void {
    this.modalAtividadeAberto = false;
  }

  badgeClass(tipo: string): string {
    const map: Record<string, string> = {
      reserva: 'badge-reserva',
      conquista: 'badge-conquista',
      conta: 'badge-conta',
      cancelamento: 'badge-cancelamento',
      arena: 'badge-arena',
    };
    return map[tipo] ?? 'badge-conta';
  }

  iconClass(tipo: string): string {
    const map: Record<string, string> = {
      reserva: 'pf-ativ-icon--reserva',
      conquista: 'pf-ativ-icon--conquista',
      conta: 'pf-ativ-icon--conta',
      cancelamento: 'pf-ativ-icon--cancelamento',
      arena: 'pf-ativ-icon--arena',
    };
    return map[tipo] ?? 'pf-ativ-icon--conta';
  }
}
