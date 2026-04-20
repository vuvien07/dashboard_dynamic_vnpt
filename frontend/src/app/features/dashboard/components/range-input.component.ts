import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';

export interface RangeValue {
  from: any;
  to: any;
}

type RangeType = 'number' | 'date' | 'datetime-local' | 'time';

@Component({
  selector: 'app-range-input',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './range-input.component.html',
  styleUrl: './range-input.component.scss'
})
export class RangeInputComponent implements OnInit{
    @Input() dataType: string = '';
    @Output() valueChange = new EventEmitter<RangeValue>();

    form!: FormGroup;

  // Map PostgreSQL fieldType → input[type]
  get inputKind(): RangeType {
    const ft = (this.dataType ?? '').toLowerCase().trim();

    if (ft === 'date') return 'date';

    if (['timestamp', 'timestamp without time zone',
         'timestamp with time zone', 'timestamptz'].includes(ft))
      return 'datetime-local';

    if (['time', 'time without time zone',
         'time with time zone', 'timetz'].includes(ft))
      return 'time';

    return 'number';
  }

  constructor(private fb: FormBuilder) {}

  ngOnInit() {
    this.form = this.fb.group({ from: [null], to: [null] });

    this.form.valueChanges.subscribe(val => {
      this.valueChange.emit(val as RangeValue);
    });
  }
}
