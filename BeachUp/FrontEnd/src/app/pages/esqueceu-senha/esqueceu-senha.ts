import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { NavigationService } from '../../shared/services/models/navigation';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MenuLateral],
  templateUrl: './esqueceu-senha.html',
  styleUrls: ['./esqueceu-senha.css'],
})
export class EsqueciSenha {
  private fb = inject(FormBuilder);
  private http = inject(HttpClient);
  private alertService = inject(AlertService);
  public navigation = inject(NavigationService);

  carregando = false;
  emailEnviado = '';
  etapa: 'email' | 'enviado' = 'email';

  emailForm: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
  });

  get ef() {
    return this.emailForm.controls;
  }

  private baseUrl = 'http://localhost:8080/auth';

  enviarLink(): void {
    if (this.emailForm.invalid) {
      this.emailForm.markAllAsTouched();
      return;
    }

    this.carregando = true;
    const { email } = this.emailForm.value;

    this.http.post(`${this.baseUrl}/esqueceu-senha`, { email }).subscribe({
      next: () => {
        this.emailEnviado = email;
        this.carregando = false;
        this.etapa = 'enviado';
      },
      error: (err) => {
        this.carregando = false;
        const msg =
          err?.error?.mensagem || err?.error?.message || 'Não foi possível enviar o e-mail.';
        this.alertService.erro(msg);
      },
    });
  }

  reenviar(): void {
    this.etapa = 'email';
    this.emailForm.reset();
  }

  voltarParaLogin(): void {
    this.navigation.irPara('login');
  }
}
