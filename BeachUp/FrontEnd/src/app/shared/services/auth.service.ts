import { Injectable, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { AuthResponse, LoginPayload, UsuarioCreate, EmpresaCreate } from './models/auth.model';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  private get isBrowser(): boolean {
    return isPlatformBrowser(this.platformId);
  }

  private authUrl = 'http://localhost:8080/auth';
  private jogadorUrl = 'http://localhost:8080/jogador';
  private empresaUrl = 'http://localhost:8080/empresa';

  criarConta(payload: UsuarioCreate): Observable<any> {
    return this.http.post<any>(`${this.jogadorUrl}/cadastro`, payload);
  }

  criarEmpresa(payload: EmpresaCreate): Observable<any> {
    return this.http.post<any>(`${this.empresaUrl}/cadastro`, payload);
  }

  login(payload: LoginPayload): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.authUrl}/login`, payload).pipe(
      tap((res) => {
        if (this.isBrowser) {
          localStorage.setItem('accessToken', res.accessToken);
          localStorage.setItem('refreshToken', res.refreshToken);
        }
      }),
    );
  }

  logout(): void {
    if (this.isBrowser) {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
    }
  }

  atualizarToken(accessToken: string, refreshToken?: string | null): void {
    if (!this.isBrowser) return;
    localStorage.setItem('accessToken', accessToken);
    if (refreshToken) localStorage.setItem('refreshToken', refreshToken);
  }

  getToken(): string | null {
    return this.isBrowser ? localStorage.getItem('accessToken') : null;
  }

  private decodePayload(token: string): any | null {
    try {
      return JSON.parse(atob(token.split('.')[1]));
    } catch {
      return null;
    }
  }

  getRole(): string | null {
    const token = this.getToken();
    if (!token) return null;
    return this.decodePayload(token)?.role ?? null;
  }

  getEmail(): string | null {
    const token = this.getToken();
    if (!token) return null;
    return this.decodePayload(token)?.sub ?? null;
  }

  isLoggedIn(): boolean {
    const token = this.getToken();
    if (!token) return false;

    const payload = this.decodePayload(token);
    if (!payload?.exp) return false;

    if (payload.exp * 1000 < Date.now()) {
      this.logout();
      return false;
    }

    return true;
  }

  getIssuedAt(): string | null {
    const token = this.getToken();
    if (!token) return null;
    const payload = this.decodePayload(token);
    if (!payload?.iat) return null;
    return new Date(payload.iat * 1000).toLocaleDateString('pt-BR', {
      month: 'short',
      year: 'numeric',
    });
  }

  isEmpresa(): boolean {
    return this.isLoggedIn() && this.getRole() === 'ROLE_EMPRESA';
  }

  isJogador(): boolean {
    return this.isLoggedIn() && this.getRole() === 'ROLE_JOGADOR';
  }

  refresh(): Observable<AuthResponse> {
    const refreshToken = this.isBrowser ? localStorage.getItem('refreshToken') : null;
    return this.http.post<AuthResponse>(`${this.authUrl}/refresh`, { refreshToken }).pipe(
      tap((res) => {
        if (this.isBrowser) {
          localStorage.setItem('accessToken', res.accessToken);
          localStorage.setItem('refreshToken', res.refreshToken);
        }
      }),
    );
  }
}
