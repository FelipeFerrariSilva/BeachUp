import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject } from 'rxjs';

interface UsuarioInfo {
  nome: string;
  email: string;
  role: string;
  fotoUrl?: string | null;
}

interface JogadorPerfil {
  id: number;
  cpf: string;
  usuario: UsuarioInfo;
}

interface EmpresaPerfil {
  id: number;
  cnpj: string;
  planoAtual: string;
  usuario: UsuarioInfo;
}

export interface PerfilResumido {
  nome: string;
  email: string;
  fotoUrl: string | null;
  iniciais: string;
}

@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private http = inject(HttpClient);

  private readonly API = 'http://localhost:8080';

  private fotoUrlSubject = new BehaviorSubject<string | null>(null);
  private perfilSubject = new BehaviorSubject<PerfilResumido | null>(null);

  fotoUrl$ = this.fotoUrlSubject.asObservable();
  /** Observable com nome, email, foto e iniciais do usuário logado */
  perfil$ = this.perfilSubject.asObservable();

  private carregado = false;

  carregarFoto(isJogador: boolean, isEmpresa: boolean, email: string | null): void {
    if (this.carregado || !email) return;
    this.carregado = true;

    if (isJogador) {
      this.http.get<JogadorPerfil[]>(`${this.API}/jogador`).subscribe({
        next: (lista) => {
          const jogador = lista.find((j) => j.usuario?.email === email);
          this.definirPerfil(jogador?.usuario);
        },
      });
    } else if (isEmpresa) {
      this.http.get<EmpresaPerfil[]>(`${this.API}/empresa`).subscribe({
        next: (lista) => {
          const empresa = lista.find((e) => e.usuario?.email === email);
          this.definirPerfil(empresa?.usuario);
        },
      });
    }
  }

  definirFotoUrl(url?: string | null): void {
    const normalizada = url ? (url.startsWith('http') ? url : `${this.API}${url}`) : null;
    this.fotoUrlSubject.next(normalizada);
    this.carregado = true;
  }

  private definirPerfil(usuario?: UsuarioInfo): void {
    if (!usuario) return;

    const fotoUrl = usuario.fotoUrl
      ? usuario.fotoUrl.startsWith('http')
        ? usuario.fotoUrl
        : `${this.API}${usuario.fotoUrl}`
      : null;

    this.fotoUrlSubject.next(fotoUrl);

    const iniciais = usuario.nome
      ? usuario.nome
          .split(' ')
          .slice(0, 2)
          .map((p) => p[0].toUpperCase())
          .join('')
      : '??';

    this.perfilSubject.next({ nome: usuario.nome, email: usuario.email, fotoUrl, iniciais });
  }

  limpar(): void {
    this.carregado = false;
    this.fotoUrlSubject.next(null);
    this.perfilSubject.next(null);
  }
}
