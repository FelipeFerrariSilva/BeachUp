import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CampeonatosDono } from './campeonatos-dono';

describe('CampeonatosDono', () => {
  let component: CampeonatosDono;
  let fixture: ComponentFixture<CampeonatosDono>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CampeonatosDono]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CampeonatosDono);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
