-- Script de creación de base de datos Investech
-- Nombre sugerido: bdinvestech.sql

-- 1. EXTENSIONES (Para soporte de UUID)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUMS (Tipos de datos personalizados)
CREATE TYPE estado_usuario AS ENUM ('activo', 'suspendido', 'cerrado');
CREATE TYPE tipo_documento AS ENUM ('ine', 'pasaporte', 'comprobante', 'otro');
CREATE TYPE estado_documento AS ENUM ('pendiente', 'aprobado', 'rechazado');
CREATE TYPE nivel_riesgo AS ENUM ('conservador', 'moderado', 'agresivo');
CREATE TYPE tipo_cuenta AS ENUM ('efectivo', 'margen', 'custodia');
CREATE TYPE estado_cuenta AS ENUM ('activa', 'suspendida', 'cerrada');
CREATE TYPE tipo_transaccion AS ENUM ('deposito', 'retiro', 'compra', 'venta', 'comision');
CREATE TYPE estado_transaccion AS ENUM ('pendiente', 'completada', 'revertida');
CREATE TYPE tipo_orden AS ENUM ('mercado', 'limite', 'stop', 'stop_limit');
CREATE TYPE lado_orden AS ENUM ('compra', 'venta');
CREATE TYPE vigencia_orden AS ENUM ('dia', 'gtc', 'ioc', 'fok');
CREATE TYPE estado_orden AS ENUM ('pendiente', 'activa', 'ejecutada', 'cancelada');
CREATE TYPE tipo_instrumento AS ENUM ('accion', 'etf', 'bono', 'cete', 'cripto', 'fondo');

-- 3. TABLAS: DOMINIO IDENTIDAD Y ACCESO
CREATE TABLE USUARIO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(180) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    pais CHAR(2) NOT NULL,
    estado estado_usuario NOT NULL,
    verificado_en TIMESTAMPTZ,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE SESION (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES USUARIO(id),
    token VARCHAR(512) UNIQUE NOT NULL,
    ip INET,
    dispositivo VARCHAR(200),
    inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiracion TIMESTAMPTZ NOT NULL,
    revocada BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE DOCUMENTO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES USUARIO(id),
    tipo tipo_documento NOT NULL,
    url TEXT NOT NULL,
    estado estado_documento NOT NULL,
    revisado_por UUID, -- Referencia a un posible agente/admin
    subido_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE PERFIL_RIESGO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES USUARIO(id),
    nivel nivel_riesgo NOT NULL,
    puntaje SMALLINT NOT NULL CHECK (puntaje BETWEEN 0 AND 100),
    respuestas JSONB,
    vigente BOOLEAN NOT NULL DEFAULT TRUE,
    evaluado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. TABLAS: DOMINIO CUENTAS Y DINERO
CREATE TABLE CUENTA (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES USUARIO(id),
    numero VARCHAR(20) UNIQUE NOT NULL,
    tipo tipo_cuenta NOT NULL,
    moneda CHAR(3) NOT NULL,
    saldo NUMERIC(18,6) NOT NULL DEFAULT 0,
    saldo_bloqueado NUMERIC(18,6) NOT NULL DEFAULT 0,
    estado estado_cuenta NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. TABLAS: DOMINIO INSTRUMENTOS Y MERCADOS
CREATE TABLE MERCADO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo VARCHAR(10) UNIQUE NOT NULL, -- MIC
    nombre VARCHAR(100) NOT NULL,
    pais CHAR(2) NOT NULL,
    zona_horaria VARCHAR(50) NOT NULL,
    moneda_base CHAR(3) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE INSTRUMENTO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mercado_id UUID NOT NULL REFERENCES MERCADO(id),
    ticker VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo tipo_instrumento NOT NULL,
    moneda CHAR(3) NOT NULL,
    isin CHAR(12) UNIQUE,
    lote_minimo NUMERIC(18,8) NOT NULL DEFAULT 1,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE PRECIO_HISTORICO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instrumento_id UUID NOT NULL REFERENCES INSTRUMENTO(id),
    fecha DATE NOT NULL,
    apertura NUMERIC(18,6) NOT NULL,
    maximo NUMERIC(18,6) NOT NULL,
    minimo NUMERIC(18,6) NOT NULL,
    cierre NUMERIC(18,6) NOT NULL,
    cierre_ajustado NUMERIC(18,6),
    volumen BIGINT NOT NULL
);

-- 6. TABLAS: OPERATIVA DE MERCADO Y PORTAFOLIOS
CREATE TABLE ORDEN (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id UUID NOT NULL REFERENCES CUENTA(id),
    instrumento_id UUID NOT NULL REFERENCES INSTRUMENTO(id),
    tipo tipo_orden NOT NULL,
    lado lado_orden NOT NULL,
    cantidad NUMERIC(18,8) NOT NULL,
    precio_limite NUMERIC(18,6),
    precio_stop NUMERIC(18,6),
    vigencia vigencia_orden NOT NULL,
    estado estado_orden NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE EJECUCION (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES ORDEN(id),
    cantidad NUMERIC(18,8) NOT NULL,
    precio NUMERIC(18,6) NOT NULL,
    comision NUMERIC(18,6) NOT NULL,
    contraparte VARCHAR(50),
    ejecutado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE TRANSACCION (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id UUID NOT NULL REFERENCES CUENTA(id),
    orden_id UUID REFERENCES ORDEN(id),
    tipo tipo_transaccion NOT NULL,
    monto NUMERIC(18,6) NOT NULL,
    moneda CHAR(3) NOT NULL,
    referencia VARCHAR(100),
    estado estado_transaccion NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE PORTAFOLIO (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id UUID NOT NULL REFERENCES CUENTA(id),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    valor_total NUMERIC(18,6) NOT NULL DEFAULT 0,
    rendimiento_pct NUMERIC(10,4),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE POSICION (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portafolio_id UUID NOT NULL REFERENCES PORTAFOLIO(id),
    instrumento_id UUID NOT NULL REFERENCES INSTRUMENTO(id),
    cantidad NUMERIC(18,8) NOT NULL,
    precio_promedio NUMERIC(18,6) NOT NULL,
    valor_mercado NUMERIC(18,6) NOT NULL,
    ganancia_perdida NUMERIC(18,6),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);