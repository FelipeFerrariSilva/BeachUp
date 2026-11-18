import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { NavigationService } from '../../shared/services/models/navigation';

type StatusConexao = 'verificando' | 'conectado' | 'desconectado';

@Component({
  selector: 'app-pagamentos',
  standalone: true,
  imports: [CommonModule, MenuLateral, NavBar],
  templateUrl: './pagamentos.html',
  styleUrl: './pagamentos.css',
})

export class Pagamentos implements OnInit {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private alertService = inject(AlertService);
  private navigation = inject(NavigationService);

  private readonly API = 'http://localhost:8080';

  status: StatusConexao = 'verificando';
  conectando = false;

  ngOnInit(): void {
    this.tratarRetornoOAuth();
    this.verificarStatus();
  }

  private tratarRetornoOAuth(): void {
    const resultado = this.route.snapshot.queryParamMap.get('status');

    if (resultado === 'sucesso') {
      this.alertService.sucesso('Conta do Mercado Pago conectada com sucesso!');
      this.status = 'conectado';
    } else if (resultado === 'falha') {
      this.alertService.erro(
        'Não foi possível conectar sua conta do Mercado Pago. Tente novamente.',
      );
    }
  }

  verificarStatus(): void {
    this.status = 'verificando';
    this.http.get<{ conectado: boolean }>(`${this.API}/empresa/mp-status`).subscribe({
      next: (res) => (this.status = res.conectado ? 'conectado' : 'desconectado'),
      error: () => (this.status = 'desconectado'),
    });
  }

  conectarMercadoPago(): void {
    this.conectando = true;
    this.http.get(`${this.API}/pagamentos/oauth/conectar`, { responseType: 'text' }).subscribe({
      next: (url) => {
        window.location.href = url;
      },
      error: () => {
        this.conectando = false;
        this.alertService.erro(
          'Erro ao gerar o link de conexão com o Mercado Pago. Tente novamente.',
        );
      },
    });
  }

  voltar(): void {
    this.navigation.irPara('dashboard-dono');
  }
}
