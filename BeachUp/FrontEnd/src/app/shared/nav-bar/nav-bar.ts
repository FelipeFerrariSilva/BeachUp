import { Component, inject, NgZone, OnDestroy, OnInit, PLATFORM_ID } from '@angular/core';
import { AsyncPipe, CommonModule, DatePipe, isPlatformBrowser } from '@angular/common';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { FormBuilder } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { AlertService } from '../services/sweetalert2.service';
import { QuadraService } from '../services/quadra.service';
import { NavigationService } from '../services/models/navigation';
import { AuthService } from '../services/auth.service';
import { UsuarioService } from '../services/usuario.service';

@Component({
  selector: 'app-nav-bar',
  imports: [CommonModule, DatePipe, AsyncPipe, RouterLink, RouterLinkActive],
  templateUrl: './nav-bar.html',
  styleUrl: './nav-bar.css',
})

export class NavBar implements OnInit, OnDestroy {
  private fb = inject(FormBuilder);
  public navigation = inject(NavigationService);
  private ngZone = inject(NgZone);
  private platformId = inject(PLATFORM_ID);
  private http = inject(HttpClient);

  public auth = inject(AuthService);
  public usuarioService = inject(UsuarioService);

  now = new Date();
  private intervalId?: ReturnType<typeof setInterval>;

  isJogador = false;
  isEmpresa = false;

  temperatura: number | null = null;
  carregandoClima = false;

  ngOnInit(): void {
    this.isJogador = this.auth.isJogador();
    this.isEmpresa = this.auth.isEmpresa();
    this.usuarioService.carregarFoto(this.isJogador, this.isEmpresa, this.auth.getEmail());

    if (isPlatformBrowser(this.platformId)) {
      this.ngZone.runOutsideAngular(() => {
        this.intervalId = setInterval(() => {
          this.ngZone.run(() => {
            this.now = new Date();
          });
        }, 1000);
      });

      this.carregarClima();
    }
  }

  get climaClasse(): string {
    if (this.temperatura === null) return '';
    if (this.temperatura <= 18) return 'clima-frio';
    if (this.temperatura >= 28) return 'clima-quente';
    return 'clima-ameno';
  }

  private carregarClima(): void {
    if (!('geolocation' in navigator)) return;

    this.carregandoClima = true;

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m`;

        this.http.get<any>(url).subscribe({
          next: (res) => {
            this.ngZone.run(() => {
              this.temperatura = res?.current?.temperature_2m ?? null;
              this.carregandoClima = false;
            });
          },
          error: () => {
            this.ngZone.run(() => {
              this.carregandoClima = false;
            });
          },
        });
      },
      () => {
        this.carregandoClima = false;
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 600000 },
    );
  }

  ngOnDestroy(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  formatarData(dt: string): string {
    return new Date(dt).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
  }
}
