
// ========================================
// 💵 Ajuste valor segun porcentaje o fijo
// ========================================

document.addEventListener("turbo:load", function(){
  const rows = document.querySelectorAll("tr[id^='coupon-row-']");
  
  if (!rows) return;

  rows.forEach((row) => {
    const tipo = row.querySelector(".coupon-tipo");
    const valor = row.querySelector(".coupon-valor");

    const val = valor.textContent.trim();

    if (tipo.textContent.trim() === "porcentaje"){ 
      valor.textContent = parseInt(val,10) + "%";
    } else if ( tipo.textContent.trim() === "fijo"){
      valor.textContent = "COP $ " + Number(val).toLocaleString("es-CO", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    };
  });
});

// ===========================================
// IMAGE LOADING HANDLERS
// ===========================================
window.imageLoaded = function(img) {
  const wrapper = img.parentElement;
  img.style.display = "none";
  wrapper.classList.remove("shimmer"); // quitar efecto shimmer
  wrapper.querySelector(".img-loader").style.display = "none";
  img.style.display = "block";
  wrapper.style.height = "100%";
}

window.imageError = function(img) {
  const wrapper = img.parentElement;
  wrapper.querySelector(".img-loader").style.display = "none";
  img.style.display = "block";
  img.src = "/images/LogoLogoText2.svg"; // fallback
}

// Verificar imágenes ya cargadas al refrescar la página
document.addEventListener("turbo:load", function() {
  const images = document.querySelectorAll('img[onload*="imageLoaded"]');
  images.forEach((img) => {
    // Si la imagen ya está cargada (desde caché), ejecutar imageLoaded
    if (img.complete && img.naturalHeight !== 0) {
      window.imageLoaded(img);
    }
  });
});

// ========================================
// 💵 Ajuste valor segun porcentaje o fijo (show)
// ========================================

document.addEventListener("turbo:load", function(){

  const tipo = document.getElementById("coupon-tipo");
  const valor = document.getElementById("coupon-valor");

  if (!tipo || !valor) return;

  const val = valor.textContent.trim();
  console.log(val);

  if (tipo.textContent.trim() === "porcentaje"){ 
    valor.textContent = parseInt(val,10) + "%";
  } else if ( tipo.textContent.trim() === "fijo"){
    valor.textContent = "COP $ " + Number(val).toLocaleString("es-CO", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

});

// ========================================
// 💵 Ajuste de cupon
// ========================================

document.addEventListener("turbo:load", function() {
  const tipoDescuento = document.getElementById("tipo_descuento");

  if (!tipoDescuento) return;

  const valorInput = document.getElementById("valor");
  const errorMsg = document.getElementById("valor-error");
  const form = document.getElementById("coupon-form");

  valorInput.step = 0;

  function validarValor() {
    let tipo = tipoDescuento.value;
    let valor = parseFloat(valorInput.value);
    errorMsg.style.display = "none";
    if (tipo === "porcentaje") {
      valorInput.setAttribute("max", "101");
      valorInput.setAttribute("min", "0");
      valorInput.step = 1;
      if (valor > 100) {
        valorInput.value = 100;
        errorMsg.textContent = "El porcentaje no puede ser mayor a 100%.";
        errorMsg.style.display = "block";
        return false;
      }
      if (valor < 1 && valorInput.value !== "") {
        valorInput.value = 1;
        errorMsg.textContent = "El porcentaje debe ser al menos 1%.";
        errorMsg.style.display = "block";
        return false;
      }
    } else {
      valorInput.removeAttribute("max");
      valorInput.setAttribute("min", "0");
      valorInput.step = 100;
    }
    return true;
  }

  tipoDescuento.addEventListener("change", function() {
    valorInput.value = "";
    errorMsg.style.display = "none";
    validarValor();
  });

  valorInput.addEventListener("input", validarValor);

  form.addEventListener("submit", function(e) {
    if (!validarValor()) {
      e.preventDefault();
    }
  });
});

// ========================================
// 💵 Converción COP a USD
// ========================================
 document.addEventListener("turbo:load", () => {
  const cambioDinero = 4000;

  function formatear(precio, locale, currency) {
    let formateado;
    
    if (currency === "USD") {
      formateado = new Intl.NumberFormat('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(precio);
      
      formateado = `${formateado} USD`;
    } else {
      const partes = precio.toFixed(2).split('.');
      const miles = partes[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".");
      const decimales = partes[1];
    
      formateado = `${miles},${decimales} COP`;
    }

    return formateado;
  }

  // precio unitario
  document.querySelectorAll(".precio-unitario").forEach(el => {
    const precio = parseFloat(el.dataset.precio);
    const locale = el.dataset.locale;
    let precioFinal, currency;

    if (locale === "en") {
      precioFinal = precio / cambioDinero;
      currency = "USD";
    } else {
      precioFinal = precio;
      currency = "COP";
    }

    el.innerText = formatear(precioFinal, locale, currency);
  });

  // Función para formatear todos los precios
  function formatearTodosLosPrecios() {
    // precio total de un producto
    document.querySelectorAll(".precio-total").forEach(el => {
      const precio = parseFloat(el.dataset.precio);
      const cantidad = parseInt(el.dataset.cantidad, 10) || 1;
      const locale = el.dataset.locale;
      let subtotal = precio * cantidad;
      let currency;

      if (locale === "en") {
        subtotal = subtotal / cambioDinero;
        currency = "USD";
      } else {
        currency = "COP";
      }

      el.innerText = formatear(subtotal, locale, currency);
    });
  }

  // Formatear precios al cargar
  formatearTodosLosPrecios();

  // Escuchar evento personalizado para reformatear
  document.addEventListener('formatear-precios', formatearTodosLosPrecios);

  // precio total del carrito
  const totalCarrito = document.getElementById("precio-total");
  if (!totalCarrito) return; 

  const locale = totalCarrito.dataset.locale || "es";
  
  function formatearMoneda(valor, idioma) {
    if (locale === "en") {
      return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        minimumFractionDigits: 2
      }).format(valor / cambioDinero);
    } else {
      return new Intl.NumberFormat("es-CO", {
        style: "currency",
        currency: "COP",
        minimumFractionDigits: 2
      }).format(valor);
    }
  }

  const precioCarrito = parseFloat(totalCarrito.dataset.precio);
  totalCarrito.textContent = formatearMoneda(precioCarrito, locale);

}); 



// ========================================
// 💵 Función verificar status de la compra
// ========================================

document.addEventListener("turbo:load", () => {
  const statusAnimation = document.getElementById("status-animation");
  if (!statusAnimation) return;

  const statusUrl = statusAnimation.dataset.statusUrl;
  
  // Elementos de los mensajes
  const loadingMessage = document.getElementById("loading-message");
  const successMessage = document.getElementById("success-message");
  const errorMessage = document.getElementById("error-message");

  let interval = setInterval(checkStatus, 2000);

  function checkStatus() {
    fetch(statusUrl)
      .then(res => res.json())
      .then(data => {
        console.log("Estado recibido:", data);
        
        if (data.status === "approved") {
          // Cambiar animación a success
          statusAnimation.className = "status-animation success";
          
          // Cambiar mensajes
          loadingMessage.classList.remove("active");
          successMessage.classList.add("active");
          
          clearInterval(interval);
          
        } else if (data.status === "declined" || data.status === "cancelled") {
          // Cambiar animación a error
          statusAnimation.className = "status-animation error";
          
          // Cambiar mensajes
          loadingMessage.classList.remove("active");
          errorMessage.classList.add("active");
          
          clearInterval(interval);
        }
      })
      .catch(error => {
        console.error("Error checking payment status:", error);
        // En caso de error, mostrar mensaje de error después de un tiempo
        setTimeout(() => {
          statusAnimation.className = "status-animation error";
          loadingMessage.classList.remove("active");
          errorMessage.classList.add("active");
          clearInterval(interval);
        }, 10000); // 10 segundos de timeout
      });
  }

  // Mostrar botón de reintentar después de 8 segundos si sigue en loading
  setTimeout(() => {
    if (statusAnimation.classList.contains("loading")) {
      const retryButton = errorMessage.querySelector(".status-btn.primary");
      if (retryButton) {
        loadingMessage.classList.remove("active");
        errorMessage.classList.add("active");
        statusAnimation.className = "status-animation error";
        clearInterval(interval);
      }
    }
  }, 8000);
});

// ==============================
// 🎞️ Función para mover el slider
// ==============================
document.addEventListener("turbo:load", function () {
  const slider = document.getElementById("productosIndex");
  if (slider) {
    window.moverSlider = function (id, direccion) {
      const slider = document.getElementById(id);
      const carta = slider.querySelector(".carta");
      if (!carta) return;

      const cartaStyle = getComputedStyle(slider);
      const gap = parseInt(cartaStyle.gap || "20", 10);
      const cartaWidth = carta.offsetWidth + gap;

      const nuevoScroll = slider.scrollLeft + direccion * cartaWidth;
      slider.scrollTo({ left: nuevoScroll, behavior: "smooth" });
    };
  }
});

// ==========================================
// 🔐 LÓGICA DE LOGIN: validación de campos
// ==========================================

document.addEventListener("turbo:load", function () {
  const loginForm = document.querySelector("form[action='/users/sign_in']");
  if (!loginForm) return;

  const email = document.querySelector("#user_email");
  const password = document.querySelector("#user_password");
  const flashAlert = document.querySelector(".alert-danger");

  if ((email?.value.trim() === "" || password?.value.trim() === "") && flashAlert) {
    flashAlert.style.display = "none";
  }

  loginForm.addEventListener("submit", function (e) {
    const emailVacio = email?.value.trim() === "";
    const passwordVacio = password?.value.trim() === "";

    if (emailVacio || passwordVacio) {
      e.preventDefault();
      if (flashAlert) flashAlert.style.display = "none";
      alert("Por favor completa ambos campos antes de iniciar sesión.");
    }
  });
});

// ===============================================
// 🛒 LÓGICA DE CARRITO: evitar redirección en POST
// ===============================================

document.addEventListener("turbo:load", function () {
  const carritoForms = document.querySelectorAll(".form-agregar-carrito");
  if (carritoForms) {
    carritoForms.forEach(form => {
      form.addEventListener("submit", function (event) {
        event.preventDefault();

        const formData = new FormData(form);

        fetch(form.action, {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
          },
          body: formData
        })
        .then(response => response.json())
        .then(data => {
          console.log("Producto agregado al carrito", data);

          // Actualizar todos los contadores de carrito
          if (data.total_productos !== undefined) {
            document.querySelectorAll('.contador-carrito').forEach(contador => {
              contador.textContent = data.total_productos;
            });
            document.querySelectorAll('.sidebar-badge').forEach(badge => {
              if (data.total_productos > 0) {
                badge.textContent = data.total_productos;
                badge.style.display = '';
              } else {
                badge.style.display = 'none';
              }
            });
          }
        })
        .catch(error => {
          console.error("Error al agregar al carrito", error);
        });
      });
    });
  }
});

// ==============================
// 🎞️ Función para el banner
// ==============================

document.addEventListener("turbo:load", function () {

  const track = document.getElementById('carouselTrack');
  const slide = document.querySelectorAll('.carousel-image');
  let index = 0;

  if (!track || slide.length === 0) return;

  function movecarousel () {
    index++;
    if (index >= slide.length){
      index = 0;
    }

    const offset = index * slide[0].clientWidth;
    track.style.transform = `translateX(-${offset}px)`;  
  }
  setInterval(movecarousel, 3500);

});

// =====================================================
// 💳 Fuciones para verificar parametros de las tarjetas
// =====================================================


document.addEventListener("turbo:load", function() {
  const form = document.getElementById("payment-form");
  const payBtn = document.getElementById("pay-btn");

  if (!form ) return;

  const cardInput = form.querySelector("[name='payment[card_number]']");
  const expMonthInput = form.querySelector("[name='payment[exp_month]']");
  const expYearInput = form.querySelector("[name='payment[exp_year]']");
  const cvvInput = form.querySelector("[name='payment[cvc]']");
  const emailInput = form.querySelector("[name='payment[email]']");
  const holderInput = form.querySelector("[name='payment[card_holder]']");
  const termsCheck = document.getElementById("payment_accept_terms");
  const dataCheck = document.getElementById("payment_accept_data");

  const errorCard = document.getElementById("error-card");
  const errorMonth = document.getElementById("error-month");
  const errorYear = document.getElementById("error-year");
  const errorCvv = document.getElementById("error-cvc");
  const errorEmail = document.getElementById("error-email");
  const errorHolder = document.getElementById("error-holder");

  let interacted = {
    card: false,
    month: false,
    year: false,
    cvv: false,
    holder: false,
    email: false
  };

  // Algoritmo Luhn para validar tarjeta
  function luhnCheck(card) {
    let sum = 0;
    let shouldDouble = false;
    for (let i = card.length - 1; i >= 0; i--) {
      let digit = parseInt(card.charAt(i));
      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      shouldDouble = !shouldDouble;
    }
    return sum % 10 === 0;
  }

  // Detecta tipo de tarjeta
  function cardType(card) {
    if (/^4/.test(card)) return "Visa";
    if (/^5[1-5]/.test(card)) return "MasterCard";
    if (/^3[47]/.test(card)) return "Amex";
    if (/^6(?:011|5)/.test(card)) return "Discover";
    return "Desconocida";
  }

  function validateField(input, isValid, errorElem, errorMsg, key) {
    input.classList.remove("input-error", "input-success");
    if (!interacted[key]) {
      errorElem.textContent = "";
      return;
    }
    if (isValid) {
      input.classList.add("input-success");
      errorElem.textContent = "";
    } else {
      input.classList.add("input-error");
      errorElem.textContent = errorMsg;
    }
  }

  function validateForm() {
    const cardValue = cardInput.value.replace(/\s+/g, "");
    const cardValidLength = /^\d{15,16}$/.test(cardValue);
    const cardValidLuhn = luhnCheck(cardValue);
    const type = cardType(cardValue);

    let cardValid = cardValidLength && cardValidLuhn && type !== "Desconocida";
    let cardErrorMsg = "";
    if (!cardValidLength) cardErrorMsg = "La tarjeta debe tener 15 o 16 dígitos";
    else if (!cardValidLuhn) cardErrorMsg = "Número de tarjeta no válido";
    else if (type === "Desconocida") cardErrorMsg = "Tipo de tarjeta no soportado";

    validateField(cardInput, cardValid, errorCard, cardErrorMsg, "card");

    // Fecha de expiración
    const monthValid = expMonthInput.value !== "";
    const yearValid = expYearInput.value !== "";
    let dateValid = false;
    let dateErrorMsg = "";
    if (monthValid && yearValid) {
      const expDate = new Date(expYearInput.value, expMonthInput.value - 1, 1);
      const now = new Date();
      expDate.setMonth(expDate.getMonth() + 1);
      dateValid = expDate > now;
      if (!dateValid) dateErrorMsg = "La tarjeta está vencida";
    }
    validateField(expMonthInput, monthValid, errorMonth, "Seleccione el mes de expiración", "month");
    validateField(expYearInput, yearValid, errorYear, "Seleccione el año de expiración", "year");
    if (monthValid && yearValid && !dateValid) {
      expMonthInput.classList.add("input-error");
      expYearInput.classList.add("input-error");
      errorMonth.textContent = dateErrorMsg;
      errorYear.textContent = dateErrorMsg;
    }

    // CVV según tipo de tarjeta
    let cvvPattern = type === "Amex" ? /^\d{4}$/ : /^\d{3}$/;
    let cvvValid = cvvPattern.test(cvvInput.value.trim());
    let cvvErrorMsg = type === "Amex" ? "CVC debe tener 4 dígitos" : "CVC debe tener 3 dígitos";
    validateField(cvvInput, cvvValid, errorCvv, cvvErrorMsg, "cvv");

    // Titular
    let holderValid = holderInput.value.trim().length > 2;
    validateField(holderInput, holderValid, errorHolder, "Ingrese el nombre del titular", "holder");

    // Email
    const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailInput.value.trim());
    validateField(emailInput, emailValid, errorEmail, "Correo electrónico no válido", "email");

    // Terminos y condiciones 
    const termsAccepted = termsCheck.checked

    // Tratamientod de datos
    const dataAccepted = dataCheck.checked


    if (cardValid && monthValid && yearValid && dateValid && cvvValid && emailValid && holderValid && termsAccepted && dataAccepted) {
      payBtn.disabled = false;
    } else {
      payBtn.disabled = true;
    }
  }

  // Marca el campo como interactuado al cambiar
  cardInput.addEventListener("input", function() { interacted.card = true; validateForm(); });
  expMonthInput.addEventListener("change", function() { interacted.month = true; validateForm(); });
  expYearInput.addEventListener("change", function() { interacted.year = true; validateForm(); });
  cvvInput.addEventListener("input", function() { interacted.cvv = true; validateForm(); });
  emailInput.addEventListener("input", function() { interacted.email = true; validateForm(); });
  holderInput.addEventListener("input", function() { interacted.holder = true; validateForm(); });
  termsCheck.addEventListener("change", validateForm);
  dataCheck.addEventListener("change", validateForm);

  // Validación inicial solo para estilos, sin mostrar errores
  validateForm();
});