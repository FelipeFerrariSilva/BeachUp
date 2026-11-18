import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';

export interface AssinaturaResponse {
  id: number;
  tipoPlano: 'GRATUITO' | 'BASICO' | 'GOLD';
  nomePlano: string;
  limiteQuadras: number | null;
  valorMensal: number;
  taxaReserva: number;
  dataInicio: string;
  dataFim: string | null;
  status: 'ATIVA' | 'EXPIRADA';
  premiumAtivo: boolean;
  podeCriarCampeonato: boolean;
}

export interface CheckoutProResponse {
  preferenceId: string;
  initPoint: string;
  sandboxInitPoint: string;
}

@Component({
  selector: 'app-planos',
  standalone: true,
  imports: [CommonModule, MenuLateral, NavBar],
  templateUrl: './planos.html',
  styleUrl: './planos.css',
})
export class Planos implements OnInit {
  private http = inject(HttpClient);
  private alertService = inject(AlertService);
  private auth = inject(AuthService);

  private readonly API = 'http://localhost:8080';

  assinatura: AssinaturaResponse | null = null;
  carregando = true;
  processando: 'BASICO' | 'GOLD' | null = null;
  mpConectado = false;
  conectandoMP = false;

  ngOnInit(): void {
    this.carregarAssinatura();
  }

  carregarAssinatura(): void {
    this.carregando = true;
    this.http.get<AssinaturaResponse>(`${this.API}/planos/minha-assinatura`).subscribe({
      next: (assinatura) => {
        this.assinatura = assinatura;
        this.carregando = false;
        this.verificarContaMP();
      },
      error: () => {
        this.alertService.erro('Não foi possível carregar os dados da assinatura.');
        this.carregando = false;
      },
    });
  }

  assinarPlano(tipo: 'BASICO' | 'GOLD'): void {
    this.processando = tipo;

    this.http
      .post<CheckoutProResponse>(`${this.API}/pagamentos/plano/iniciar?tipoPlano=${tipo}`, {})
      .subscribe({
        next: (checkout) => {
          this.processando = null;
          window.location.href = checkout.initPoint;
        },
        error: (err) => {
          this.processando = null;
          this.alertService.erro(
            err?.error?.message || 'Erro ao iniciar pagamento. Tente novamente.',
          );
        },
      });
  }

  verificarContaMP(): void {
    this.http.get<{ conectado: boolean }>(`${this.API}/empresa/mp-status`).subscribe({
      next: (res) => (this.mpConectado = res.conectado),
      error: () => (this.mpConectado = false), // fallback conservador
    });
  }

  conectarMercadoPago(): void {
    this.conectandoMP = true;
    this.http.get(`${this.API}/pagamentos/oauth/conectar`, { responseType: 'text' }).subscribe({
      next: (url) => {
        this.conectandoMP = false;
        window.location.href = url;
      },
      error: () => {
        this.conectandoMP = false;
        this.alertService.erro('Erro ao gerar link de conexão com o Mercado Pago.');
      },
    });
  }

  diasRestantes(): number {
    if (!this.assinatura?.dataFim) return 0;
    const diff = new Date(this.assinatura.dataFim).getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
  }

  formatarData(dt: string): string {
    return new Date(dt).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    });
  }

  badgePlano(tipo: string): string {
    const map: Record<string, string> = {
      GRATUITO: 'badge-gratuito',
      BASICO: 'badge-basico',
      GOLD: 'badge-gold',
    };
    return map[tipo] ?? '';
  }
}
