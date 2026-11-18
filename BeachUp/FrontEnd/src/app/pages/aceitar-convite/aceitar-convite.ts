import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { AuthService } from '../../shared/services/auth.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { NavBar } from '../../shared/nav-bar/nav-bar';
import { TimesService } from '../../shared/services/times.service';
import { TimesResponse } from '../../shared/services/models/times.model';

@Component({
  selector: 'app-aceitar-convite',
  standalone: true,
  imports: [CommonModule, MenuLateral, NavBar],
  templateUrl: './aceitar-convite.html',
  styleUrl: './aceitar-convite.css',
})
export class AceitarConvite implements OnInit {
  token = '';
  time: TimesResponse | null = null;

  carregando = true;
  tokenInvalido = false;
  aceitando = false;
  aceito = false;

  constructor(
    private route: ActivatedRoute,
    private timesService: TimesService,
    private alertService: AlertService,
    public auth: AuthService,
    public navigation: NavigationService,
  ) {}

  ngOnInit(): void {
    this.token = this.route.snapshot.paramMap.get('token') ?? '';

    if (!this.auth.isLoggedIn()) {
      this.carregando = false;
      return;
    }

    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.tokenInvalido = false;

    this.timesService.listarTodos().subscribe({
      next: (times) => {
        this.time = times.find((t) => t.urlConvite === this.token) ?? null;
        this.tokenInvalido = !this.time;
        this.carregando = false;
      },
      error: (err) => {
        this.carregando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  aceitar(): void {
    this.aceitando = true;
    this.timesService.aceitarConvite(this.token).subscribe({
      next: (time) => {
        this.time = time;
        this.aceitando = false;
        this.aceito = true;
        this.alertService.sucesso(`Você agora faz parte do time "${time.nome}"!`);
      },
      error: (err) => {
        this.aceitando = false;
        this.alertService.erroHttp(err);
      },
    });
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }
}
