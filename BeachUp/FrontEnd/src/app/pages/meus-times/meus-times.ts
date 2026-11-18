import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { TimesService } from '../../shared/services/times.service';
import { TimesResponse, MembroResponse } from '../../shared/services/models/times.model';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';

@Component({
  selector: 'app-meus-times',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule, MenuLateral, NavBar],
  templateUrl: './meus-times.html',
  styleUrls: ['./meus-times.css'],
})
export class MeusTimes implements OnInit {
  private timesService = inject(TimesService);
  private AlertService = inject(AlertService);
  private fb = inject(FormBuilder);
  public navigation = inject(NavigationService);

  times: TimesResponse[] = [];
  meuJogadorId: number | null = null;

  carregando = true;
  salvando = false;
  regerandoConviteId: number | null = null;

  modalAberto = false;
  timeSelecionado: TimesResponse | null = null;

  criarForm: FormGroup = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    descricao: [''],
  });

  get f() {
    return this.criarForm.controls;
  }

  ngOnInit(): void {
    this.timesService.meuJogador().subscribe({
      next: (jogador) => {
        this.meuJogadorId = jogador?.id ?? null;
        this.carregarTimes();
      },
      error: () => this.carregarTimes(),
    });
  }

  carregarTimes(): void {
    this.carregando = true;
    this.timesService.meusTimes().subscribe({
      next: (times) => {
        this.times = times;
        this.carregando = false;
      },
      error: () => {
        this.carregando = false;
        this.AlertService.erro('Erro ao carregar seus times.');
      },
    });
  }

  criarTime(): void {
    if (this.criarForm.invalid) {
      this.criarForm.markAllAsTouched();
      return;
    }

    this.salvando = true;
    const { nome, descricao } = this.criarForm.value;

    this.timesService.criar({ nome, descricao: descricao || undefined }).subscribe({
      next: (novoTime) => {
        this.times.unshift(novoTime);
        this.salvando = false;
        this.criarForm.reset();
        this.AlertService.sucesso(`Time "${novoTime.nome}" criado com sucesso!`);
      },
      error: () => {
        this.salvando = false;
        this.AlertService.erro('Erro ao criar o time. Tente novamente.');
      },
    });
  }

  abrirDetalhe(time: TimesResponse): void {
    this.timeSelecionado = time;
    this.modalAberto = true;
  }

  fecharModal(): void {
    this.modalAberto = false;
    this.timeSelecionado = null;
  }

  regerarConvite(time: TimesResponse): void {
    this.regerandoConviteId = time.id;
    this.timesService.regerarConvite(time.id).subscribe({
      next: (novaUrl) => {
        // Atualiza localmente
        const idx = this.times.findIndex((t) => t.id === time.id);
        if (idx >= 0) this.times[idx] = { ...this.times[idx], urlConvite: novaUrl };
        if (this.timeSelecionado?.id === time.id) {
          this.timeSelecionado = { ...this.timeSelecionado, urlConvite: novaUrl };
        }
        this.regerandoConviteId = null;
        this.AlertService.sucesso('Link de convite atualizado!');
      },
      error: () => {
        this.regerandoConviteId = null;
        this.AlertService.erro('Erro ao regerar o convite.');
      },
    });
  }

  copiarConvite(url: string): void {
    navigator.clipboard.writeText(url).then(() => {
      this.AlertService.sucesso('Link copiado!');
    });
  }

  isDono(time: TimesResponse): boolean {
    return time.idJogadorDono === this.meuJogadorId;
  }

  membrosAceitos(time: TimesResponse): MembroResponse[] {
    return time.membros.filter((m) => m.status === 'ACEITO');
  }

  membrosPendentes(time: TimesResponse): MembroResponse[] {
    return time.membros.filter((m) => m.status === 'PENDENTE');
  }

  linkCompleto(urlConvite: string): string {
    return `${window.location.origin}/times/entrar/${urlConvite}`;
  }
}
