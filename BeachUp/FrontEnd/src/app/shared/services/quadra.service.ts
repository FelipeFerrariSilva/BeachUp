import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';
import { AssinaturaResponse, QuadraPayload, QuadraResponse, ReservaResponse, } from './models/quadra.model';

@Injectable({ providedIn: 'root' })
export class QuadraService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  private base = 'http://localhost:8080';

  private headers(): HttpHeaders {
    return new HttpHeaders({ Authorization: `Bearer ${this.authService.getToken()}` });
  }

  getMinhasArenas(): Observable<any[]> {
    return this.http.get<any[]>(`${this.base}/arenas/minhas`, { headers: this.headers() });
  }

  criarQuadra(arenaId: number, payload: QuadraPayload): Observable<QuadraResponse> {
    return this.http.post<QuadraResponse>(`${this.base}/quadras/${arenaId}`, payload, {
      headers: this.headers(),
    });
  }

  getQuadrasPorArena(arenaId: number): Observable<QuadraResponse[]> {
    return this.http.get<QuadraResponse[]>(`${this.base}/quadras/arena/${arenaId}`, {
      headers: this.headers(),
    });
  }

  atualizarQuadra(id: number, payload: QuadraPayload): Observable<QuadraResponse> {
    return this.http.put<QuadraResponse>(`${this.base}/quadras/${id}`, payload, {
      headers: this.headers(),
    });
  }

  deletarQuadra(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/quadras/${id}`, { headers: this.headers() });
  }

  getReservasPorQuadra(quadraId: number): Observable<ReservaResponse[]> {
    return this.http.get<ReservaResponse[]>(`${this.base}/reservas/quadra/${quadraId}`, {
      headers: this.headers(),
    });
  }

  confirmarReserva(reservaId: number): Observable<ReservaResponse> {
    return this.http.patch<ReservaResponse>(
      `${this.base}/reservas/${reservaId}/confirmar`,
      {},
      { headers: this.headers() },
    );
  }

  cancelarReserva(reservaId: number): Observable<ReservaResponse> {
    return this.http.patch<ReservaResponse>(
      `${this.base}/reservas/${reservaId}/cancelar`,
      {},
      { headers: this.headers() },
    );
  }

  getMinhaAssinatura(): Observable<AssinaturaResponse> {
    return this.http.get<AssinaturaResponse>(`${this.base}/planos/minha-assinatura`, {
      headers: this.headers(),
    });
  }

  upgradePremium(): Observable<AssinaturaResponse> {
    return this.http.post<AssinaturaResponse>(
      `${this.base}/planos/upgrade`,
      {},
      { headers: this.headers() },
    );
  }
}
