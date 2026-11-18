import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { NavigationService } from '../../shared/services/models/navigation';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { ArenaService } from '../../shared/services/arena.service';
import { ArenaCadastroPayload, ArenaResponse } from '../../shared/services/models/arena.model';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { HorariosArena } from '../../shared/horarios-arena/horarios-arena';
import { AuthService } from '../../shared/services/auth.service';

export interface QuadraItem {
  id: number;
  nome: string;
  tipoCobertura: 'COBERTA' | 'DESCOBERTA';
  valorHora: number;
  arenaNome?: string;
  arenaId?: number;
  fotos?: string[]; // backend retorna lista de URLs (strings puras)
}

@Component({
  selector: 'app-quadras-dono',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MenuLateral, NavBar, HorariosArena],
  templateUrl: './quadras-dono.html',
  styleUrl: './quadras-dono.css',
})
export class QuadrasDono implements OnInit {
  arenas: ArenaResponse[] = [];
  arenaSelecionadaId: number | null = null;
  quadras: QuadraItem[] = [];

  carregandoArenas = true;
  carregandoQuadras = false;
  salvando = false;

  erro = '';
  sucesso = '';

  modalAberto = false;
  modoEdicao = false;
  quadraEditandoId: number | null = null;

  confirmandoExclusaoId: number | null = null;

  quadraForm: FormGroup;

  arquivoFotoSelecionado: File | null = null;
  previewFotoArena: string | null = null;
  salvandoFoto = false;

  // Foto de quadra: preview por quadra antes de salvar
  previewFotoQuadra: { [quadraId: number]: string | null } = {};
  arquivoFotoQuadra: { [quadraId: number]: File | null } = {};

  private baseUrl = 'http://localhost:8080';

  constructor(
    private http: HttpClient,
    private fb: FormBuilder,
    private arenaService: ArenaService,
    private swall: AlertService,
    public navigation: NavigationService,
    public authService: AuthService,
  ) {
    this.quadraForm = this.fb.group({
      nome: ['', Validators.required],
      tipoCobertura: ['COBERTA', Validators.required],
      valorHora: [null, [Validators.required, Validators.min(0.01)]],
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
        if (arenas.length > 0) {
          this.selecionarArena(arenas[0].id);
        }
      },
      error: () => {
        this.erro = 'Não foi possível carregar as arenas.';
        this.carregandoArenas = false;
      },
    });
  }

  selecionarArena(arenaId: number): void {
    this.arenaSelecionadaId = arenaId;
    this.cancelarFoto();
    this.carregarQuadras();
  }

  carregarQuadras(): void {
    this.carregandoQuadras = true;
    this.quadras = [];
    this.http
      .get<QuadraItem[]>(`${this.baseUrl}/quadras/arena/${this.arenaSelecionadaId}`)
      .subscribe({
        next: (quadras) => {
          this.quadras = quadras;
          this.carregandoQuadras = false;
        },
        error: () => {
          this.carregandoQuadras = false;
        },
      });
  }

  arenaSelecionada(): ArenaResponse | undefined {
    return this.arenas.find((a) => a.id === this.arenaSelecionadaId);
  }

  fotoUrlCompleta(fotoUrl: string | null | undefined): string | null {
    if (!fotoUrl) return null;
    return fotoUrl.startsWith('http') ? fotoUrl : `${this.baseUrl}${fotoUrl}`;
  }

  selecionarFoto(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];

    if (!file.type.startsWith('image/')) {
      this.erro = 'Selecione um arquivo de imagem válido.';
      input.value = '';
      return;
    }

    this.erro = '';
    this.arquivoFotoSelecionado = file;
    this.previewFotoArena = URL.createObjectURL(file);
    input.value = '';
  }

  cancelarFoto(): void {
    if (this.previewFotoArena) {
      URL.revokeObjectURL(this.previewFotoArena);
    }
    this.arquivoFotoSelecionado = null;
    this.previewFotoArena = null;
  }

  salvarFotoArena(): void {
    const arena = this.arenaSelecionada();
    if (!arena || !this.arquivoFotoSelecionado) return;

    this.salvandoFoto = true;
    this.erro = '';

    const payload: ArenaCadastroPayload = {
      nome: arena.nome,
      descricao: arena.descricao,
      endereco: arena.endereco,
    };

    this.arenaService.atualizar(arena.id, payload, this.arquivoFotoSelecionado).subscribe({
      next: (atualizada) => {
        this.arenas = this.arenas.map((a) => (a.id === atualizada.id ? atualizada : a));
        this.sucesso = arena.fotoUrl ? 'Foto da arena atualizada!' : 'Foto da arena adicionada!';
        this.salvandoFoto = false;
        this.cancelarFoto();
        setTimeout(() => (this.sucesso = ''), 3000);
      },
      error: (err) => {
        this.erro = err?.error?.message || 'Erro ao salvar a foto da arena.';
        this.salvandoFoto = false;
      },
    });
  }

  abrirModalNova(): void {
    this.modoEdicao = false;
    this.quadraEditandoId = null;
    this.quadraForm.reset({ tipoCobertura: 'COBERTA' });
    this.erro = '';
    this.sucesso = '';
    this.modalAberto = true;
  }

  abrirModalEdicao(quadra: QuadraItem): void {
    this.modoEdicao = true;
    this.quadraEditandoId = quadra.id;
    this.quadraForm.setValue({
      nome: quadra.nome,
      tipoCobertura: quadra.tipoCobertura,
      valorHora: quadra.valorHora,
    });
    this.erro = '';
    this.sucesso = '';
    this.modalAberto = true;
  }

  fecharModal(): void {
    this.modalAberto = false;
    this.quadraEditandoId = null;
    this.modoEdicao = false;
  }

  salvar(): void {
    if (this.quadraForm.invalid) {
      this.quadraForm.markAllAsTouched();
      return;
    }
    if (this.modoEdicao) {
      this.atualizarQuadra();
    } else {
      this.criarQuadra();
    }
  }

  criarQuadra(): void {
    if (!this.arenaSelecionadaId) return;
    this.salvando = true;
    this.erro = '';

    this.http
      .post<QuadraItem>(`${this.baseUrl}/quadras/${this.arenaSelecionadaId}`, this.quadraForm.value)
      .subscribe({
        next: (nova) => {
          this.quadras = [...this.quadras, nova];
          this.sucesso = `Quadra "${nova.nome}" cadastrada com sucesso!`;
          this.salvando = false;
          this.fecharModal();
          setTimeout(() => (this.sucesso = ''), 3000);
        },
        error: (err) => {
          this.erro = err?.error?.message || 'Erro ao cadastrar quadra.';
          this.salvando = false;
        },
      });
  }

  atualizarQuadra(): void {
    if (!this.quadraEditandoId) return;
    this.salvando = true;
    this.erro = '';

    this.http
      .put<QuadraItem>(`${this.baseUrl}/quadras/${this.quadraEditandoId}`, this.quadraForm.value)
      .subscribe({
        next: (atualizada) => {
          this.quadras = this.quadras.map((q) => (q.id === atualizada.id ? atualizada : q));
          this.sucesso = `Quadra "${atualizada.nome}" atualizada!`;
          this.salvando = false;
          this.fecharModal();
          setTimeout(() => (this.sucesso = ''), 3000);
        },
        error: (err) => {
          this.erro = err?.error?.message || 'Erro ao atualizar quadra.';
          this.salvando = false;
        },
      });
  }

  pedirConfirmacaoExclusao(id: number): void {
    this.confirmandoExclusaoId = id;
  }

  cancelarExclusao(): void {
    this.confirmandoExclusaoId = null;
  }

  confirmarExclusao(): void {
    if (!this.confirmandoExclusaoId) return;
    const id = this.confirmandoExclusaoId;

    this.http.delete(`${this.baseUrl}/quadras/${id}`).subscribe({
      next: () => {
        this.quadras = this.quadras.filter((q) => q.id !== id);
        this.confirmandoExclusaoId = null;
        this.sucesso = 'Quadra removida.';
        setTimeout(() => (this.sucesso = ''), 3000);
      },
      error: (err) => {
        this.erro = err?.error?.message || 'Erro ao excluir quadra.';
        this.confirmandoExclusaoId = null;
      },
    });
  }

  formatarValor(valor: number): string {
    return `R$ ${Number(valor).toFixed(2).replace('.', ',')}`;
  }

  campoInvalido(campo: string): boolean {
    const c = this.quadraForm.get(campo);
    return !!(c && c.invalid && c.touched);
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  selecionarFotoQuadra(event: Event, quadraId: number): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;

    const arquivo = input.files[0];

    if (!arquivo.type.startsWith('image/')) {
      this.swall.erro('Selecione um arquivo de imagem válido.');
      input.value = '';
      return;
    }

    if (arquivo.size > 5 * 1024 * 1024) {
      this.swall.erro('A imagem deve ter no máximo 5MB.');
      input.value = '';
      return;
    }

    if (this.previewFotoQuadra[quadraId]) {
      URL.revokeObjectURL(this.previewFotoQuadra[quadraId]!);
    }

    this.arquivoFotoQuadra[quadraId] = arquivo;
    this.previewFotoQuadra[quadraId] = URL.createObjectURL(arquivo);
    input.value = '';
  }

  salvarFotoQuadra(quadraId: number): void {
    const arquivo = this.arquivoFotoQuadra[quadraId];
    if (!arquivo) return;

    const formData = new FormData();
    formData.append('fotos', arquivo); // backend espera "fotos" (lista)

    const token = this.authService.getToken();
    const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });

    this.http
      .post<QuadraItem>(`${this.baseUrl}/quadras/${quadraId}/fotos`, formData, { headers })
      .subscribe({
        next: (quadraAtualizada) => {
          const index = this.quadras.findIndex((q) => q.id === quadraId);
          if (index !== -1) this.quadras[index] = quadraAtualizada;
          this.cancelarFotoQuadra(quadraId);
          this.swall.sucesso('Foto adicionada com sucesso!');
        },
        error: () => this.swall.erro('Erro ao enviar a foto. Tente novamente.'),
      });
  }

  cancelarFotoQuadra(quadraId: number): void {
    if (this.previewFotoQuadra[quadraId]) {
      URL.revokeObjectURL(this.previewFotoQuadra[quadraId]!);
    }
    this.previewFotoQuadra[quadraId] = null;
    this.arquivoFotoQuadra[quadraId] = null;
  }
}
