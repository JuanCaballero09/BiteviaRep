import "@hotwired/turbo-rails"
import "script"
import "chart"
import "bootstrap"


// ===========================================
// DASHBOARD CAROUSEL FUNCTIONALITY
// ===========================================

document.addEventListener('DOMContentLoaded', function() {
    initializeScrollAnimations();
    initializeButtonStates();
    initializeSmoothScroll();
    initializeNavbarEffects();
    initializeSearchEnhancements();
    initializeFlashAlerts();
});

// ===========================================
// SISTEMA DE ALERTAS FLASH MEJORADO
// ===========================================

function initializeFlashAlerts() {
    // Agregar soporte para múltiples alertas
    const alertContainer = document.getElementById('alert-container');
    if (!alertContainer) return;
    
    // Función para crear alertas programáticamente
    window.createFlashAlert = function(message, type = 'info', duration = 4000) {
        const alert = document.createElement('div');
        alert.className = `alert ${type}`;
        alert.dataset.alertType = type;
        
        // Crear el HTML de la alerta
        alert.innerHTML = `
            <span class="alert-icon"></span>
            <span class="alert-message">${message}</span>
            <button class="alert-close" onclick="closeFlashAlert(this.parentElement)">&times;</button>
            <div class="alert-progress"></div>
        `;
        
        // Agregar al contenedor
        const flashToast = document.getElementById('flash-toast') || alertContainer;
        flashToast.appendChild(alert);
        
        // Aplicar animación y auto-close
        setTimeout(() => {
            alert.style.animation = "alertSlideIn 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards";
        }, 100);
        
        // Auto-close
        if (duration > 0) {
            setTimeout(() => {
                closeFlashAlert(alert);
            }, duration);
        }
        
        return alert;
    };
    
    // Función para cerrar alertas
    window.closeFlashAlert = function(alertElement) {
        if (!alertElement || alertElement.classList.contains('removing')) return;
        
        alertElement.classList.add('removing');
        alertElement.style.animation = "alertSlideOut 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards";
        
        alertElement.addEventListener("animationend", () => {
            if (alertElement.parentNode) {
                alertElement.remove();
            }
        }, { once: true });
    };
    
    // Función para limpiar todas las alertas
    window.clearAllAlerts = function() {
        const alerts = document.querySelectorAll('.alert');
        alerts.forEach(alert => closeFlashAlert(alert));
    };
    
    // Atajos de teclado para cerrar alertas
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const alerts = document.querySelectorAll('.alert:not(.removing)');
            if (alerts.length > 0) {
                closeFlashAlert(alerts[alerts.length - 1]); // Cerrar la última alerta
            }
        }
    });
}

// ===========================================
// EFECTOS DEL NAVBAR Y HEADER
// ===========================================

function initializeNavbarEffects() {
    const navbar = document.querySelector('.navbar');
    
    if (!navbar) return;
    
    // Efecto de scroll en navbar
    let lastScrollTop = 0;
    
    window.addEventListener('scroll', () => {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        // Añadir/quitar clase para efecto de scroll
        if (scrollTop > 100) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        
        lastScrollTop = scrollTop;
    });
    
    // Añadir clases CSS para el efecto scrolled
    const style = document.createElement('style');
    style.textContent = `
        .navbar.scrolled {
            backdrop-filter: blur(15px);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
        }
    `;
    document.head.appendChild(style);
}

function initializeSearchEnhancements() {
    const searchInput = document.querySelector('.buscador input[type="search"]');
    const searchForm = document.querySelector('.buscador');
    
    if (!searchInput || !searchForm) return;
    
    // Efecto de focus mejorado
    searchInput.addEventListener('focus', () => {
        searchForm.classList.add('focused');
    });
    
    searchInput.addEventListener('blur', () => {
        searchForm.classList.remove('focused');
    });
    
    // Búsqueda con Enter
    searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            searchForm.submit();
        }
    });
    
    // Añadir estilos para el estado focused
    const style = document.createElement('style');
    style.textContent = `
        .buscador.focused {
            border-color: var(--base) !important;
            box-shadow: 0 12px 35px rgba(237, 88, 33, 0.2) !important;
            transform: translateY(-3px) !important;
        }
    `;
    document.head.appendChild(style);
}

// ===========================================
// FUNCIÓN PRINCIPAL DEL CAROUSEL
// ===========================================


// Función para anunciar cambios de slide (accesibilidad) - FUNCIÓN ELIMINADA (Ahora usa Bootstrap Carousel)

// ===========================================
// SMOOTH SCROLL PARA NAVEGACIÓN
// ===========================================

function initializeSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// ===========================================
// ANIMACIONES DE SCROLL
// ===========================================

function initializeScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in');
            }
        });
    }, observerOptions);
    
    // Observar elementos para animaciones
    document.querySelectorAll('.combo-card-premium, .contact-item, .section-header').forEach(el => {
        observer.observe(el);
    });
}

// ===========================================
// LOADING STATES PARA BOTONES
// ===========================================

function initializeButtonStates() {
    document.querySelectorAll('.combo-btn-premium, .hero-btn, .view-all-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            if (!this.disabled) {
                this.classList.add('loading');
                this.disabled = true;
                
                // Simular un tiempo de carga mínimo para mejor UX
                setTimeout(() => {
                    this.classList.remove('loading');
                    this.disabled = false;
                }, 1000);
            }
        });
    });
}

// ===========================================
// TURBO FRAME ENHANCEMENTS
// ===========================================

document.addEventListener('turbo:frame-load', function() {
    // Re-inicializar funcionalidades después de cargas turbo
    console.log('Turbo frame loaded, re-initializing components...');
    
    // Re-inicializar carousel si es necesario
    setTimeout(() => {
        initializeCarousel();
        initializeScrollAnimations();
        initializeButtonStates();
    }, 100);
});

// ===========================================
// RESPONSIVE HELPERS
// ===========================================

function handleResize() {
    // Ajustar carousel en dispositivos móviles
    const carousel = document.querySelector('.carousel-track');
    if (carousel && window.innerWidth <= 768) {
        // Ajustes específicos para móvil si es necesario
        console.log('Responsive adjustments for mobile');
    }
}

window.addEventListener('resize', handleResize);
handleResize(); // Ejecutar al cargar