# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_26_210835) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "banners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "carrito_items", force: :cascade do |t|
    t.bigint "carrito_id", null: false
    t.integer "cantidad"
    t.integer "precio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id"
    t.string "tamano_selected"
    t.index ["carrito_id"], name: "index_carrito_items_on_carrito_id"
    t.index ["product_id"], name: "index_carrito_items_on_product_id"
  end

  create_table "carritos", force: :cascade do |t|
    t.string "numero_orden"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "coupon_id"
    t.index ["coupon_id"], name: "index_carritos_on_coupon_id"
  end

  create_table "combo_items", force: :cascade do |t|
    t.bigint "combo_id", null: false
    t.bigint "product_id", null: false
    t.integer "cantidad", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["combo_id", "product_id"], name: "index_combo_items_on_combo_id_and_product_id"
    t.index ["combo_id"], name: "index_combo_items_on_combo_id"
    t.index ["product_id"], name: "index_combo_items_on_product_id"
  end

  create_table "coupon_usages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "coupon_id", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_coupon_usages_on_coupon_id"
    t.index ["user_id", "coupon_id"], name: "index_unique_user_coupon_usages", unique: true
    t.index ["user_id"], name: "index_coupon_usages_on_user_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "codigo"
    t.string "tipo_descuento"
    t.decimal "valor"
    t.datetime "expira_en"
    t.boolean "activo", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "direccions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nombre"
    t.text "direccion_completa"
    t.string "barrio"
    t.string "ciudad"
    t.string "departamento"
    t.string "codigo_postal"
    t.decimal "latitud", precision: 10, scale: 6
    t.decimal "longitud", precision: 10, scale: 6
    t.boolean "principal", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "principal"], name: "index_direccions_on_user_id_and_principal"
    t.index ["user_id"], name: "index_direccions_on_user_id"
  end

  create_table "grupos", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "descripcion"
  end

  create_table "ingrediente_productos", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "ingrediente_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingrediente_id"], name: "index_ingrediente_productos_on_ingrediente_id"
    t.index ["product_id"], name: "index_ingrediente_productos_on_product_id"
  end

  create_table "ingredientes", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "code"
    t.bigint "user_id"
    t.integer "status"
    t.decimal "total"
    t.bigint "carrito_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "coupon_id"
    t.text "direccion"
    t.string "guest_nombre"
    t.string "guest_apellido"
    t.string "guest_telefono"
    t.string "guest_email"
    t.decimal "costo_domicilio", precision: 10, scale: 2, default: "0.0"
    t.bigint "sede_id", null: false
    t.index ["carrito_id"], name: "index_orders_on_carrito_id"
    t.index ["code"], name: "index_orders_on_code", unique: true
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["sede_id"], name: "index_orders_on_sede_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "transaction_id"
    t.integer "status", default: 0
    t.decimal "amount", precision: 10, scale: 2
    t.integer "payment_method", default: 0
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "installment"
    t.string "phone_number"
    t.integer "type_card"
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "nombre"
    t.float "precio"
    t.string "descripcion"
    t.boolean "disponible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "grupo_id", null: false
    t.decimal "calificacion", precision: 2, scale: 1
    t.string "type"
    t.string "tamanos_disponibles", default: [], array: true
    t.index ["grupo_id"], name: "index_products_on_grupo_id"
    t.index ["type"], name: "index_products_on_type"
  end

  create_table "sedes", force: :cascade do |t|
    t.string "nombre", null: false
    t.string "departamento", null: false
    t.string "municipio", null: false
    t.string "barrio"
    t.string "direccion", null: false
    t.decimal "latitud", precision: 10, scale: 6
    t.decimal "longitud", precision: 10, scale: 6
    t.string "telefono"
    t.boolean "activo", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activo"], name: "index_sedes_on_activo"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nombre"
    t.string "apellido"
    t.string "telefono"
    t.integer "rol", default: 0
    t.boolean "activo", default: true
    t.datetime "ultimo_acceso"
    t.date "fecha_registro", default: -> { "CURRENT_DATE" }
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "authentication_token"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "carrito_items", "carritos"
  add_foreign_key "carrito_items", "products"
  add_foreign_key "carritos", "coupons"
  add_foreign_key "combo_items", "products"
  add_foreign_key "combo_items", "products", column: "combo_id"
  add_foreign_key "coupon_usages", "coupons"
  add_foreign_key "coupon_usages", "users"
  add_foreign_key "direccions", "users"
  add_foreign_key "ingrediente_productos", "ingredientes"
  add_foreign_key "ingrediente_productos", "products"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "carritos"
  add_foreign_key "orders", "coupons"
  add_foreign_key "orders", "sedes"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "products", "grupos"
end
