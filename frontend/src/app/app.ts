import { DOCUMENT } from '@angular/common';
import { Component, ElementRef, HostListener, ViewChild, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  private readonly document = inject(DOCUMENT);

  @ViewChild('menuToggle') private menuToggle?: ElementRef<HTMLButtonElement>;
  @ViewChild('firstNavLink') private firstNavLink?: ElementRef<HTMLAnchorElement>;

  menuOpen = false;

  toggleMenu(): void {
    this.menuOpen = !this.menuOpen;
    this.syncBodyScroll();

    if (this.menuOpen) {
      this.focusFirstMenuLink();
      return;
    }

    this.focusMenuToggle();
  }

  closeMenu(): void {
    if (!this.menuOpen) {
      return;
    }

    this.menuOpen = false;
    this.syncBodyScroll();
    this.focusMenuToggle();
  }

  @HostListener('document:keydown.escape')
  onEscapeKey(): void {
    this.closeMenu();
  }

  private syncBodyScroll(): void {
    this.document.body.classList.toggle('menu-open', this.menuOpen);
  }

  private focusFirstMenuLink(): void {
    queueMicrotask(() => this.firstNavLink?.nativeElement.focus());
  }

  private focusMenuToggle(): void {
    queueMicrotask(() => this.menuToggle?.nativeElement.focus());
  }
}
