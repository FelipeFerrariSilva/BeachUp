import { Component, NgZone, OnInit, PLATFORM_ID, inject } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
  AbstractControl,
  ValidationErrors,
} from '@angular/forms';
import { NavigationService } from '../../shared/services/models/navigation';
import { AuthService } from '../../shared/services/auth.service';
import { NgxMaskDirective } from 'ngx-mask';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule, NgxMaskDirective, MenuLateral],
  templateUrl: './login.html',
  styleUrls: ['./login.css'],
})
export class Login implements OnInit {
  isEmpresa = false;
  isRegister = false;
  mostrarSenha = false;
  carregando = false;

  private fb = inject(FormBuilder);
  private route = inject(ActivatedRoute);
  private authService = inject(AuthService);
  private alertService = inject(AlertService);
  private ngZone = inject(NgZone);
  private platformId = inject(PLATFORM_ID);
  private intervalId?: ReturnType<typeof setInterval>;

  now = new Date();

  constructor(public navigation: NavigationService) {}

  loginForm!: FormGroup;
  registerForm!: FormGroup;
  empresaForm!: FormGroup;

  private redirecionarAposLogin() {
    const role = this.authService.getRole();

    sessionStorage.setItem('reloadAfterLogin', 'true');

    if (role === 'ROLE_EMPRESA') {
      this.navigation.irPara('dashboard-dono');
    } else {
      this.navigation.irPara('reservas');
    }
  }

  ngOnInit(): void {
    this.inicializarForms();

    this.route.url.subscribe((url) => {
      this.isRegister = url.some((segment) => segment.path === 'cadastrar');
    });

    if (isPlatformBrowser(this.platformId)) {
      this.ngZone.runOutsideAngular(() => {
        this.intervalId = setInterval(() => {
          this.ngZone.run(() => (this.now = new Date()));
        }, 60000);
      });
    }
  }

  ngOnDestroy(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  inicializarForms(): void {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      senha: ['', [Validators.required, Validators.minLength(6)]],
    });

    this.registerForm = this.fb.group(
      {
        nome: ['', [Validators.required, Validators.minLength(3)]],
        cpf: ['', [Validators.required, Validators.minLength(11)]],
        email: ['', [Validators.required, Validators.email]],
        senha: ['', [Validators.required, Validators.minLength(6)]],
        confirmarSenha: ['', [Validators.required]],
      },
      { validators: this.senhasIguaisValidator },
    );

    this.empresaForm = this.fb.group(
      {
        nome: ['', [Validators.required, Validators.minLength(3)]],
        cnpj: ['', [Validators.required, Validators.minLength(14)]],
        email: ['', [Validators.required, Validators.email]],
        senha: ['', [Validators.required, Validators.minLength(6)]],
        confirmarSenha: ['', [Validators.required]],
      },
      { validators: this.senhasIguaisValidator },
    );
  }

  senhasIguaisValidator(form: AbstractControl): ValidationErrors | null {
    const senha = form.get('senha')?.value;
    const confirmarSenha = form.get('confirmarSenha')?.value;
    if (!senha || !confirmarSenha) return null;
    return senha === confirmarSenha ? null : { senhasDiferentes: true };
  }

  toggle(): void {
    this.isRegister = !this.isRegister;
    this.loginForm.reset();
    this.registerForm.reset();
    this.empresaForm.reset();
    this.mostrarSenha = false;
  }

  toggleTipoCadastro(): void {
    this.isEmpresa = !this.isEmpresa;
    this.registerForm.reset();
    this.empresaForm.reset();
  }

  irPara(rota: string): void {
    this.navigation.irPara(rota);
  }

  VerSenha(): void {
    this.mostrarSenha = !this.mostrarSenha;
  }

  criarConta(): void {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      this.alertService.aviso('Preencha todos os campos corretamente!');
      return;
    }

    this.carregando = true;
    const { nome, cpf, email, senha, confirmarSenha } = this.registerForm.value;
    const cpfLimpo = cpf.replace(/\D/g, '');

    const payloadUsuario = { nome, cpf: cpfLimpo, email, senha, confirmarSenha };
    console.log('[criarConta] Payload enviado:', payloadUsuario);

    this.authService.criarConta(payloadUsuario).subscribe({
      next: (res) => {
        console.log('[criarConta] Resposta do servidor:', res);

        this.authService.login({ email, senha }).subscribe({
          next: () => {
            this.carregando = false;
            this.registerForm.reset();

            const role = this.authService.getRole();

            this.alertService.sucesso('Conta criada com sucesso!').then(() => {
              if (role === 'ROLE_EMPRESA') {
                this.navigation.irPara('dashboard-dono');
              } else {
                this.navigation.irPara('reservas');
              }
            });
          },
          error: () => {
            this.carregando = false;
            this.alertService.aviso('Conta criada com sucesso! Faça login para continuar.');
            this.toggle();
          },
        });
      },
    });
  }

  criarEmpresa(): void {
    if (this.empresaForm.invalid) {
      this.empresaForm.markAllAsTouched();
      this.alertService.aviso('Preencha todos os campos corretamente!');
      return;
    }

    this.carregando = true;
    const { nome, cnpj, email, senha, confirmarSenha } = this.empresaForm.value;
    const cnpjLimpo = cnpj.replace(/\D/g, '');

    const payloadEmpresa = { nome, cnpj: cnpjLimpo, email, senha, confirmarSenha };
    console.log('[criarEmpresa] Payload enviado:', payloadEmpresa);

    this.authService.criarEmpresa(payloadEmpresa).subscribe({
      next: (res) => {
        console.log('[criarEmpresa] Resposta do servidor:', res);

        this.authService.login({ email, senha }).subscribe({
          next: () => {
            this.carregando = false;
            this.empresaForm.reset();

            const role = this.authService.getRole();

            this.alertService.sucesso('Empresa criada com sucesso!').then(() => {
              if (role === 'ROLE_EMPRESA') {
                this.navigation.irPara('dashboard-dono');
              } else {
                this.navigation.irPara('reservas');
              }
            });
          },
          error: () => {
            this.carregando = false;
            this.alertService.aviso('Empresa criada com sucesso! Faça login para continuar.');
            this.toggle();
          },
        });
      },
    });
  }

  entrar(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      this.alertService.aviso('Preencha email e senha!');
      return;
    }

    this.carregando = true;
    const { email, senha } = this.loginForm.value;

    console.log('[entrar] Payload enviado:', { email, senha });

    this.authService.login({ email, senha }).subscribe({
      next: (res) => {
        console.log('[entrar] Resposta do servidor:', res);
        console.log('[entrar] Role detectada:', this.authService.getRole());
        this.carregando = false;

        const role = this.authService.getRole();

          this.redirecionarAposLogin();
      },
      error: (err) => {
        console.error('Erro no login:', err);
        const mensagem = err?.error?.message || err?.error || 'Email ou senha inválidos.';
        this.alertService.erro(mensagem);
        this.carregando = false;
      },
    });
  }

  get lf() {
    return this.loginForm.controls;
  }
  get rf() {
    return this.registerForm.controls;
  }
  get ef() {
    return this.empresaForm.controls;
  }
}
