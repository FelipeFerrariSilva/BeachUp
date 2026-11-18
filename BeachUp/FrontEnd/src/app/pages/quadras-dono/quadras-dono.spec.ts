import { ComponentFixture, TestBed } from '@angular/core/testing';

import { QuadrasDono } from './quadras-dono';

describe('QuadrasDono', () => {
  let component: QuadrasDono;
  let fixture: ComponentFixture<QuadrasDono>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [QuadrasDono]
    })
    .compileComponents();

    fixture = TestBed.createComponent(QuadrasDono);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
