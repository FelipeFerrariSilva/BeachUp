import { Component, ElementRef, ViewChild } from '@angular/core';
import { NavigationService } from '../../shared/services/models/navigation';
import { MenuLateral } from '../../shared/menu-lateral/menu-lateral';

@Component({
  selector: 'app-sobre',
  standalone: true,
  imports: [MenuLateral],
  templateUrl: './sobre.html',
  styleUrl: './sobre.css',
})
export class Sobre {
  isRegister = false;

  toggle() {
    this.isRegister = !this.isRegister;
  }

  constructor(public navigation: NavigationService) {}

  irPara(rota: string) {
    this.navigation.irPara(rota);
  }

  @ViewChild('devCarousel')
  devCarousel!: ElementRef<HTMLDivElement>;

  scrollDevs(direction: number) {
    const container = this.devCarousel.nativeElement;

    container.scrollBy({
      left: container.clientWidth * 0.9 * direction,
      behavior: 'smooth',
    });
  }
}
