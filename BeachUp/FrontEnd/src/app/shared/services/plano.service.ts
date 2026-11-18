import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AssinaturaResponse } from './models/quadra.model';
import { CheckoutProResponse } from '../../pages/planos/planos';

@Injectable({ providedIn: 'root' })
export class PlanoService {
  private http = inject(HttpClient);
  private readonly API = 'http://localhost:8080';

  getMinhaAssinatura(): Observable<AssinaturaResponse> {
    return this.http.get<AssinaturaResponse>(`${this.API}/planos/minha-assinatura`);
  }

  iniciarPagamento(tipoPlano: 'BASICO' | 'GOLD'): Observable<CheckoutProResponse> {
    return this.http.post<CheckoutProResponse>(
      `${this.API}/pagamentos/plano/iniciar?tipoPlano=${tipoPlano}`,
      {},
    );
  }

  getUrlOAuthMP(): Observable<string> {
    return this.http.get(`${this.API}/pagamentos/oauth/conectar`, { responseType: 'text' });
  }
}
