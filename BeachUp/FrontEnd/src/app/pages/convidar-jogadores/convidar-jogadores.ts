import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { TimesService } from '../../shared/services/times.service';
import { TimesResponse } from '../../shared/services/models/times.model';

@Component({
  selector: 'app-convidar-jogadores',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MenuLateral, NavBar],
  templateUrl: './convidar-jogadores.html',
  styleUrl: './convidar-jogadores.css',
})
export class ConvidarJogadores implements OnInit {
  meuNome = '';
  meusTimes: TimesResponse[] = [];
  carregando = true;
  criando = false;
  regerandoId: number | null = null;

  modalNovoAberto = false;
  novoTimeForm: FormGroup;

  timeConvitId: number | null = null;
  convitForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private timesService: TimesService,
    private alertService: AlertService,
    public navigation: NavigationService,
  ) {
    this.novoTimeForm = this.fb.group({
      nome: ['', [Validators.required, Validators.maxLength(50)]],
      descricao: ['', Validators.maxLength(50)],
    });

    this.convitForm = this.fb.group({
      nomeAmigo: [''],
      telefone: [''],
      mensagem: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.timesService.meuJogador().subscribe({
      next: (jogador) => (this.meuNome = jogador?.usuario.nome ?? ''),
    });
    this.timesService.meusTimes().subscribe({
      next: (times) => {
        this.meusTimes = times;
        this.carregando = false;
      },
      error: (err) => {
        this.carregando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  // ---- criar time ----

  abrirModalNovo(): void {
    this.novoTimeForm.reset();
    this.modalNovoAberto = true;
  }

  fecharModalNovo(): void {
    this.modalNovoAberto = false;
  }

  criarTime(): void {
    if (this.novoTimeForm.invalid) {
      this.novoTimeForm.markAllAsTouched();
      return;
    }

    this.criando = true;
    const valores = this.novoTimeForm.value;
    this.timesService
      .criar({ nome: valores.nome, descricao: valores.descricao || undefined })
      .subscribe({
        next: (novo) => {
          this.meusTimes = [novo, ...this.meusTimes];
          this.criando = false;
          this.modalNovoAberto = false;
          this.alertService.sucesso(`Time "${novo.nome}" criado! Agora chame sua dupla.`);
          this.abrirPainelConvite(novo);
        },
        error: (err) => {
          this.criando = false;
          this.alertService.erroHttp(err);
        },
      });
  }

  // ---- convite ----

  timeCompleto(time: TimesResponse): boolean {
    return time.membros.filter((m) => m.status === 'ACEITO').length >= 2;
  }

  linkConvite(time: TimesResponse): string {
    if (!time.urlConvite) return '';
    return `${window.location.origin}/aceitar-convite/${time.urlConvite}`;
  }

  abrirPainelConvite(time: TimesResponse): void {
    if (this.timeConvitId === time.id) {
      this.timeConvitId = null;
      return;
    }
    this.timeConvitId = time.id;
    this.convitForm.reset({
      nomeAmigo: '',
      telefone: '',
      mensagem: this.mensagemPadrao(time, ''),
    });
  }

  fecharPainelConvite(): void {
    this.timeConvitId = null;
  }

  atualizarMensagemPadrao(time: TimesResponse): void {
    const nomeAmigo = this.convitForm.get('nomeAmigo')?.value || '';
    this.convitForm.patchValue({ mensagem: this.mensagemPadrao(time, nomeAmigo) });
  }

  private mensagemPadrao(time: TimesResponse, nomeAmigo: string): string {
    const saudacao = nomeAmigo.trim() ? `E aí, ${nomeAmigo.trim()}!` : 'E aí!';
    const quem = this.meuNome ? ` Aqui é o(a) ${this.meuNome}.` : '';
    const link = this.linkConvite(time);

    return [
      `${saudacao}${quem}`,
      ``,
      `Bora fechar uma dupla no beach tennis? 🎾🏐`,
      `Te convidei para o time *${time.nome}* no BeachUp!`,
      `É só clicar no link abaixo e confirmar:`,
      ``,
      link,
    ].join('\n');
  }

  enviarWhatsapp(time: TimesResponse): void {
    if (this.convitForm.invalid) {
      this.convitForm.markAllAsTouched();
      return;
    }

    const { telefone, mensagem } = this.convitForm.value;
    const numero = (telefone || '').replace(/\D/g, '');
    const url = `https://wa.me/${numero}?text=${encodeURIComponent(mensagem)}`;
    window.open(url, '_blank');
  }

  copiarLink(time: TimesResponse): void {
    const link = this.linkConvite(time);
    if (!link) return;
    navigator.clipboard
      .writeText(link)
      .then(() => this.alertService.sucesso('Link de convite copiado!'))
      .catch(() => this.alertService.erro('Não foi possível copiar o link.'));
  }

  regerarConvite(time: TimesResponse): void {
    this.alertService
      .confirmar('Gerar novo link?', 'O link de convite atual deixará de funcionar.')
      .then((result) => {
        if (!result.isConfirmed) return;

        this.regerandoId = time.id;
        this.timesService.regerarConvite(time.id).subscribe({
          next: (novoToken) => {
            this.meusTimes = this.meusTimes.map((t) =>
              t.id === time.id ? { ...t, urlConvite: novoToken } : t,
            );
            this.regerandoId = null;
            this.alertService.sucesso('Novo link de convite gerado!');
          },
          error: (err) => {
            this.regerandoId = null;
            this.alertService.erroHttp(err);
          },
        });
      });
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  trackById(_: number, item: TimesResponse) {
    return item.id;
  }
}
