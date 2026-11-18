import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';

@Component({
  selector: 'app-redefinir-senha',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MenuLateral],
  templateUrl: './redefinir-senha.html',
  styleUrls: ['./redefinir-senha.css'],
})
export class RedefinirSenha implements OnInit {
  private fb = inject(FormBuilder);
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private alertService = inject(AlertService);
  public navigation = inject(NavigationService);

  carregando = false;
  mostrarSenha = false;
  token = '';
  tokenInvalido = false;
  sucesso = false;

  form: FormGroup = this.fb.group({
    novaSenha: ['', [Validators.required, Validators.minLength(6)]],
    confirmarSenha: ['', [Validators.required]],
  });

  get f() {
    return this.form.controls;
  }

  private baseUrl = 'http://localhost:8080/auth';

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token') ?? '';
    if (!this.token) {
      this.tokenInvalido = true;
    }
  }

  toggleSenha(): void {
    this.mostrarSenha = !this.mostrarSenha;
  }

  redefinir(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const { novaSenha, confirmarSenha } = this.form.value;
    if (novaSenha !== confirmarSenha) {
      this.alertService.aviso('As senhas não coincidem.');
      return;
    }

    this.carregando = true;

    this.http.post(`${this.baseUrl}/redefinir-senha`, { token: this.token, novaSenha }).subscribe({
      next: () => {
        this.carregando = false;
        this.sucesso = true;

        this.alertService.senha().then((res) => {
        });
      },
      error: (err) => {
        this.carregando = false;
        const msg = err?.error?.mensagem || err?.error?.message || 'Token inválido ou expirado.';
        this.alertService.erro(msg);
        this.tokenInvalido = true;
      },
    });
  }
}
