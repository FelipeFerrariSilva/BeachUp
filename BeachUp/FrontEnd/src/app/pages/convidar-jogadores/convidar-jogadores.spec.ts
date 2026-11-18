import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ConvidarJogadores } from './convidar-jogadores';

describe('ConvidarJogadores', () => {
  let component: ConvidarJogadores;
  let fixture: ComponentFixture<ConvidarJogadores>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ConvidarJogadores]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ConvidarJogadores);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
