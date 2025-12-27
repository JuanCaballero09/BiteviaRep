Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173", "http://localhost:3000", "http://192.168.1.27:5173", "http://192.168.1.27:3000", "http://127.0.0.1:5173", "http://127.0.0.1:3000", "https://mi-dominio-produccion.com"

    resource "*",
      headers: :any,
      methods: %i[get post patch put delete options],
      expose: [ "Authorization" ]
  end
end
