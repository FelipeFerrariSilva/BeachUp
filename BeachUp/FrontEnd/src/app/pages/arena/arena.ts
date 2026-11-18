import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators, } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { forkJoin, of } from 'rxjs';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';
import { ArenaService } from '../../shared/services/arena.service';
import { ArenaCadastroPayload } from '../../shared/services/models/arena.model';
import { AlertService } from '../../shared/services/sweetalert2.service';
import { NavigationService } from '../../shared/services/models/navigation';
import { NgxMaskDirective } from 'ngx-mask';
import { AuthService } from '../../shared/services/auth.service';
import { NavBar } from '../../shared/nav-bar/nav-bar';

interface HorarioLocal {
  diaSemana: string;
  label: string;
  ativo: boolean;
  horaAbertura: string;
  horaFechamento: string;
}

@Component({
  selector: 'app-arena',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, MenuLateral, NgxMaskDirective, NavBar],
  templateUrl: './arena.html',
  styleUrls: ['./arena.css'],
})
export class Arena {
  private fb = inject(FormBuilder);
  private http = inject(HttpClient);
  private arenaService = inject(ArenaService);
  private alertService = inject(AlertService);
  private authService = inject(AuthService);
  public navigation = inject(NavigationService);

  carregando = false;
  previewImage: string | null = null;
  loadingImage = false;
  arquivoSelecionado: File | null = null;

  obtendoLocalizacao = false;
  latitude: number | null = null;
  longitude: number | null = null;

  horarios: HorarioLocal[] = [
    {
      diaSemana: 'MONDAY',
      label: 'Segunda-feira',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'TUESDAY',
      label: 'Terça-feira',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'WEDNESDAY',
      label: 'Quarta-feira',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'THURSDAY',
      label: 'Quinta-feira',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'FRIDAY',
      label: 'Sexta-feira',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'SATURDAY',
      label: 'Sábado',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
    {
      diaSemana: 'SUNDAY',
      label: 'Domingo',
      ativo: false,
      horaAbertura: '08:00',
      horaFechamento: '22:00',
    },
  ];

  arenaForm: FormGroup = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    descricao: ['', [Validators.required, Validators.minLength(10)]],
    logradouro: ['', Validators.required],
    numero: ['', Validators.required],
    bairro: [''],
    cidade: ['', Validators.required],
    estado: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(2)]],
    cep: ['', [Validators.required, Validators.minLength(8)]],
  });

  get f() {
    return this.arenaForm.controls;
  }

  toggleDia(horario: HorarioLocal): void {
    horario.ativo = !horario.ativo;
  }

  selecionarTodosDias(): void {
    const algumAtivo = this.horarios.some((h) => h.ativo);
    this.horarios.forEach((h) => (h.ativo = !algumAtivo));
  }

  get diasSelecionados(): number {
    return this.horarios.filter((h) => h.ativo).length;
  }

  usarLocalizacaoAtual(): void {
    if (!('geolocation' in navigator)) {
      this.alertService.erro('Seu navegador não suporta geolocalização.');
      return;
    }

    this.obtendoLocalizacao = true;

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        this.latitude = pos.coords.latitude;
        this.longitude = pos.coords.longitude;
        this.preencherEnderecoPorCoordenadas(this.latitude, this.longitude);
      },
      (err) => {
        this.obtendoLocalizacao = false;
        let msg = 'Não foi possível obter sua localização.';
        if (err.code === err.PERMISSION_DENIED) {
          msg = 'Permissão de localização negada. Habilite nas configurações do navegador.';
        }
        this.alertService.erro(msg);
      },
      { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 },
    );
  }

  private preencherEnderecoPorCoordenadas(lat: number, lon: number): void {
    const params = new URLSearchParams({
      format: 'jsonv2',
      lat: lat.toString(),
      lon: lon.toString(),
      zoom: '18',
      addressdetails: '1',
      'accept-language': 'pt-BR',
    });
    const url = `https://nominatim.openstreetmap.org/reverse?${params.toString()}`;

    this.http.get<any>(url).subscribe({
      next: (res) => {
        const addr = res?.address ?? {};

        this.arenaForm.patchValue({
          logradouro: addr.road ?? addr.pedestrian ?? addr.street ?? this.f['logradouro'].value,
          numero: addr.house_number ?? this.f['numero'].value,
          bairro: addr.suburb ?? addr.neighbourhood ?? addr.quarter ?? this.f['bairro'].value,
          cidade:
            addr.city ?? addr.town ?? addr.municipality ?? addr.village ?? this.f['cidade'].value,
          estado: (addr['ISO3166-2-lvl4'] ?? '').split('-')[1] ?? this.f['estado'].value,
          cep: (addr.postcode ?? this.f['cep'].value)?.replace(/\D/g, ''),
        });

        this.obtendoLocalizacao = false;
        this.alertService.sucesso('Localização aplicada! Verifique os dados do endereço.');
      },
      error: () => {
        this.obtendoLocalizacao = false;
        this.alertService.aviso(
          'Localização obtida, mas não foi possível buscar o endereço automaticamente.',
        );
      },
    });
  }

  imagemSelecionada(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];

    if (!file.type.startsWith('image/')) {
      this.alertService.erro('Selecione um arquivo de imagem válido.');
      return;
    }

    this.loadingImage = true;
    this.arquivoSelecionado = file;
    this.previewImage = URL.createObjectURL(file);
    this.loadingImage = false;
  }

  cadastrarArena(): void {
    if (this.arenaForm.invalid) {
      this.arenaForm.markAllAsTouched();
      this.alertService.aviso('Preencha todos os campos obrigatórios!');
      return;
    }

    const v = this.arenaForm.value;
    const cepLimpo = v.cep.replace(/\D/g, '');

    const payload: ArenaCadastroPayload = {
      nome: v.nome,
      descricao: v.descricao,
      endereco: {
        logradouro: v.logradouro,
        numero: v.numero,
        bairro: v.bairro ?? '',
        cidade: v.cidade,
        estado: v.estado.toUpperCase(),
        cep: cepLimpo,
      },
    };

    if (this.latitude !== null && this.longitude !== null) {
      payload.latitude = this.latitude;
      payload.longitude = this.longitude;
    }

    this.carregando = true;

    this.arenaService.cadastrar(payload, this.arquivoSelecionado).subscribe({
      next: (arena) => {
        const horariosSelecionados = this.horarios.filter((h) => h.ativo);

        if (horariosSelecionados.length === 0) {
          this.carregando = false;
          this.alertService.sucesso('Arena cadastrada com sucesso!').then(() => {
            this.navigation.irPara('dashboard-dono');
          });
          return;
        }

        const token = this.authService.getToken();
        const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });

        const requisicoes = horariosSelecionados.map((h) =>
          this.http.post(
            `http://localhost:8080/arenas/${arena.id}/horarios`,
            {
              diaSemana: h.diaSemana,
              horaAbertura: h.horaAbertura,
              horaFechamento: h.horaFechamento,
            },
            { headers },
          ),
        );

        forkJoin(requisicoes).subscribe({
          next: () => {
            this.carregando = false;
            this.alertService.sucesso('Arena cadastrada com sucesso!').then(() => {
              this.navigation.irPara('dashboard-dono');
            });
          },
          error: () => {
            this.carregando = false;
            this.alertService
              .aviso('Arena criada! Alguns horários não foram salvos. Ajuste em "Quadras".')
              .then(() => {
                this.navigation.irPara('dashboard-dono');
              });
          },
        });
      },
      error: (err) => {
        const mensagem = err?.error?.message || err?.error?.error || 'Erro ao cadastrar arena.';
        this.alertService.erro(mensagem);
        this.carregando = false;
      },
    });
  }
}
