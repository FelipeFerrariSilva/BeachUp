import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';
import {
  CampeonatoCadastroPayload,
  CampeonatoResponse,
  PartidaResponse,
  ResultadoPartidaPayload,
} from './models/campeonato.model';

@Injectable({
  providedIn: 'root',
})
export class CampeonatoService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  private baseUrl = 'http://localhost:8080/campeonatos';

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  // Empresa cria um campeonato vinculado a uma de suas arenas
  criar(payload: CampeonatoCadastroPayload): Observable<CampeonatoResponse> {
    return this.http.post<CampeonatoResponse>(this.baseUrl, payload, {
      headers: this.getHeaders(),
    });
  }

  // Jogador inscreve seu time através do token de inscrição do campeonato
  inscreverTime(token: string, timeId: number): Observable<CampeonatoResponse> {
    return this.http.post<CampeonatoResponse>(
      `${this.baseUrl}/inscrever/${token}/time/${timeId}`,
      {},
      { headers: this.getHeaders() },
    );
  }

  // Empresa fecha as inscrições e gera o chaveamento (sorteio)
  iniciar(id: number): Observable<PartidaResponse[]> {
    return this.http.post<PartidaResponse[]>(
      `${this.baseUrl}/${id}/iniciar`,
      {},
      { headers: this.getHeaders() },
    );
  }

  // Empresa registra o placar de uma partida
  registrarResultado(
    partidaId: number,
    payload: ResultadoPartidaPayload,
  ): Observable<PartidaResponse> {
    return this.http.put<PartidaResponse>(
      `${this.baseUrl}/partidas/${partidaId}/resultado`,
      payload,
      { headers: this.getHeaders() },
    );
  }

  listarTodos(): Observable<CampeonatoResponse[]> {
    return this.http.get<CampeonatoResponse[]>(this.baseUrl, {
      headers: this.getHeaders(),
    });
  }

  buscarPorId(id: number): Observable<CampeonatoResponse> {
    return this.http.get<CampeonatoResponse>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders(),
    });
  }

  listarPartidas(id: number): Observable<PartidaResponse[]> {
    return this.http.get<PartidaResponse[]>(`${this.baseUrl}/${id}/partidas`, {
      headers: this.getHeaders(),
    });
  }
}
