import { AfterViewInit, Component, ViewChild, ElementRef, inject, PLATFORM_ID, } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIcon } from '@angular/material/icon';
import { NavigationService } from '../../shared/services/models/navigation';
import { AuthService } from '../../shared/services/auth.service';
import { RouterLink } from '@angular/router';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, MatIcon, RouterLink, MatButtonModule, MenuLateral],
  templateUrl: './home.html',
  styleUrl: './home.css',
})
export class Home implements AfterViewInit {
  public auth = inject(AuthService);
  private platformId = inject(PLATFORM_ID);

  constructor(public navigation: NavigationService) { }

  irPara(rota: string) {
    this.navigation.irPara(rota);
  }

  @ViewChild('heroVideo') heroVideo!: ElementRef<HTMLVideoElement>;

  ngAfterViewInit() {
    if (!isPlatformBrowser(this.platformId)) {
      return;
    }

    if (this.heroVideo && this.heroVideo.nativeElement) {
      const hero = this.heroVideo.nativeElement;
      hero.muted = true;
      hero.play().catch((err) => {
        console.log('Hero video autoplay blocked by browser:', err);
      });
    }
  }
}
