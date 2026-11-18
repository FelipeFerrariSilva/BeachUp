import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, map, switchMap } from 'rxjs';
import { AuthService } from './auth.service';
import { TimesCadastroPayload, TimesResponse } from './models/times.model';

export interface JogadorResponse {
  id: number;
  cpf: string;
  usuario: { nome: string; email: string; role: string };
}

@Injectable({
  providedIn: 'root',
})
export class TimesService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  private baseUrl = 'http://localhost:8080/times';
  private jogadorUrl = 'http://localhost:8080/jogador';

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  criar(payload: TimesCadastroPayload): Observable<TimesResponse> {
    return this.http.post<TimesResponse>(this.baseUrl, payload, {
      headers: this.getHeaders(),
    });
  }

  regerarConvite(id: number): Observable<string> {
    return this.http.post(`${this.baseUrl}/${id}/convite/regenar`, null, {
      headers: this.getHeaders(),
      responseType: 'text',
    });
  }

  aceitarConvite(token: string): Observable<TimesResponse> {
    return this.http.post<TimesResponse>(
      `${this.baseUrl}/entrar/${token}`,
      {},
      { headers: this.getHeaders() },
    );
  }

  listarTodos(): Observable<TimesResponse[]> {
    return this.http.get<TimesResponse[]>(this.baseUrl, { headers: this.getHeaders() });
  }

  buscarPorId(id: number): Observable<TimesResponse> {
    return this.http.get<TimesResponse>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders(),
    });
  }

  meuJogador(): Observable<JogadorResponse | null> {
    const meuEmail = this.authService.getEmail();
    return this.http
      .get<JogadorResponse[]>(this.jogadorUrl, { headers: this.getHeaders() })
      .pipe(map((jogadores) => jogadores.find((j) => j.usuario.email === meuEmail) ?? null));
  }

  private meuJogadorId(): Observable<number | null> {
    return this.meuJogador().pipe(map((j) => j?.id ?? null));
  }

  meusTimes(): Observable<TimesResponse[]> {
    return this.meuJogadorId().pipe(
      switchMap((meuId) =>
        this.listarTodos().pipe(
          map((times) =>
            times.filter(
              (t) =>
                t.idJogadorDono === meuId ||
                t.membros.some((m) => m.idJogador === meuId && m.status === 'ACEITO'),
            ),
          ),
        ),
      ),
    );
  }
}
