import { Component, inject, OnInit } from '@angular/core';
import { CommonModule, AsyncPipe } from '@angular/common';
import { MatIcon } from '@angular/material/icon';
import { NavigationService } from '../services/models/navigation';
import { AuthService } from '../services/auth.service';
import { UsuarioService, PerfilResumido } from '../services/usuario.service';

@Component({
  selector: 'app-menu-lateral',
  standalone: true,
  imports: [CommonModule,MatIcon],
  templateUrl: './menu-lateral.html',
  styleUrl: './menu-lateral.css',
})
export class MenuLateral implements OnInit {
  public navigation = inject(NavigationService);
  public auth = inject(AuthService);
  public usuarioService = inject(UsuarioService);

  perfil: PerfilResumido | null = null;

  ngOnInit(): void {
    const isJogador = this.auth.isJogador();
    const isEmpresa = this.auth.isEmpresa();
    const email = this.auth.getEmail();

    this.usuarioService.carregarFoto(isJogador, isEmpresa, email);

    this.usuarioService.perfil$.subscribe((p) => (this.perfil = p));
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  logout(): void {
    this.usuarioService.limpar();
    this.auth.logout();
    this.navigation.irPara('home');
  }
}
