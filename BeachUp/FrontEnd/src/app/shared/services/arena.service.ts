import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ArenaCadastroPayload, ArenaResponse } from './models/arena.model';

@Injectable({
  providedIn: 'root',
})
export class ArenaService {
  private http = inject(HttpClient);
  private baseUrl = 'http://localhost:8080/arenas';

  cadastrar(payload: ArenaCadastroPayload, foto?: File | null): Observable<ArenaResponse> {
    const formData = new FormData();
    formData.append('dados', new Blob([JSON.stringify(payload)], { type: 'application/json' }));
    if (foto) formData.append('foto', foto);
    return this.http.post<ArenaResponse>(this.baseUrl, formData);
  }

  getAll(): Observable<ArenaResponse[]> {
    return this.http.get<ArenaResponse[]>(this.baseUrl);
  }

  getMinhas(): Observable<ArenaResponse[]> {
    return this.http.get<ArenaResponse[]>(`${this.baseUrl}/minhas`);
  }

  getById(id: number): Observable<ArenaResponse> {
    return this.http.get<ArenaResponse>(`${this.baseUrl}/${id}`);
  }

  atualizar(
    id: number,
    payload: ArenaCadastroPayload,
    foto?: File | null,
  ): Observable<ArenaResponse> {
    const formData = new FormData();
    formData.append('dados', new Blob([JSON.stringify(payload)], { type: 'application/json' }));
    if (foto) formData.append('foto', foto);
    return this.http.put<ArenaResponse>(`${this.baseUrl}/${id}`, formData);
  }

  deletar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
