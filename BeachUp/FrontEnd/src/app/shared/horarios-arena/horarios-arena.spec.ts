import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HorariosArena } from './horarios-arena';

describe('HorariosArena', () => {
  let component: HorariosArena;
  let fixture: ComponentFixture<HorariosArena>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HorariosArena]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HorariosArena);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
