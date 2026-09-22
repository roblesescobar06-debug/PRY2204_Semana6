/* ============================================================
   PRY2204 - SEMANA 6
   Consultorio Médico Municipalidad Santa Gema
   CASO 1: Creación del modelo relacional normalizado
   ============================================================ */

/* ------------------------------------------------------------
   BORRADO DE OBJETOS
   Elimina las tablas si ya existen, para que el script pueda
   ejecutarse varias veces sin errores.
   ------------------------------------------------------------ */
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE table_name IN ('PAGO','DOSIS','RECETA','MEDICAMENTO',
                                   'DIGITADOR','MEDICO','PACIENTE','BANCO',
                                   'DIAGNOSTICO','TIPO_RECETA','VIA_ADMINISTRACION',
                                   'TIPO_MEDICAMENTO','ESPECIALIDAD','COMUNA',
                                   'CIUDAD','REGION')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/

/* ------------------------------------------------------------
   TABLAS DE UBICACIÓN: REGION -> CIUDAD -> COMUNA
   Normaliza la dirección del paciente (ciudad, comuna, región)
   ------------------------------------------------------------ */
CREATE TABLE region (
    id_region   NUMBER(2)    NOT NULL,
    nombre      VARCHAR2(30) NOT NULL
);
ALTER TABLE region ADD CONSTRAINT region_pk PRIMARY KEY (id_region);

CREATE TABLE ciudad (
    id_ciudad   NUMBER(5)    NOT NULL,
    nombre      VARCHAR2(30) NOT NULL,
    id_region   NUMBER(2)    NOT NULL
);
ALTER TABLE ciudad ADD CONSTRAINT ciudad_pk PRIMARY KEY (id_ciudad);
ALTER TABLE ciudad ADD CONSTRAINT ciudad_region_fk
    FOREIGN KEY (id_region) REFERENCES region (id_region);

-- Identificador autoincrementable que comienza en 1101 e incrementa en 1
CREATE TABLE comuna (
    id_comuna   NUMBER(5) GENERATED ALWAYS AS IDENTITY
                (START WITH 1101 INCREMENT BY 1),
    nombre      VARCHAR2(30) NOT NULL,
    id_ciudad   NUMBER(5)    NOT NULL
);
ALTER TABLE comuna ADD CONSTRAINT comuna_pk PRIMARY KEY (id_comuna);
ALTER TABLE comuna ADD CONSTRAINT comuna_ciudad_fk
    FOREIGN KEY (id_ciudad) REFERENCES ciudad (id_ciudad);

/* ------------------------------------------------------------
   TABLAS DE CATÁLOGO
   ------------------------------------------------------------ */
-- Identificador autoincrementable (identity)
CREATE TABLE especialidad (
    id_especialidad NUMBER(3) GENERATED ALWAYS AS IDENTITY,
    nombre          VARCHAR2(40) NOT NULL
);
ALTER TABLE especialidad ADD CONSTRAINT especialidad_pk PRIMARY KEY (id_especialidad);

-- Tipos de medicamento (ej. genérico, de marca)
CREATE TABLE tipo_medicamento (
    id_tipo_med NUMBER(3)    NOT NULL,
    nombre      VARCHAR2(30) NOT NULL
);
ALTER TABLE tipo_medicamento ADD CONSTRAINT tipo_medicamento_pk PRIMARY KEY (id_tipo_med);

-- Vía de administración (ej. oral, intramuscular)
CREATE TABLE via_administracion (
    id_via      NUMBER(3)    NOT NULL,
    nombre      VARCHAR2(30) NOT NULL
);
ALTER TABLE via_administracion ADD CONSTRAINT via_administracion_pk PRIMARY KEY (id_via);

-- Tipos de receta permitidos por regla de negocio
CREATE TABLE tipo_receta (
    id_tipo_receta NUMBER(3)    NOT NULL,
    nombre         VARCHAR2(15) NOT NULL
);
ALTER TABLE tipo_receta ADD CONSTRAINT tipo_receta_pk PRIMARY KEY (id_tipo_receta);
ALTER TABLE tipo_receta ADD CONSTRAINT tipo_receta_nombre_ck
    CHECK (nombre IN ('DIGITAL','MAGISTRAL','RETENIDA','GENERAL','VETERINARIA'));

CREATE TABLE diagnostico (
    cod_diagnostico NUMBER(3)    NOT NULL,
    nombre          VARCHAR2(50) NOT NULL
);
ALTER TABLE diagnostico ADD CONSTRAINT diagnostico_pk PRIMARY KEY (cod_diagnostico);

CREATE TABLE banco (
    cod_banco   NUMBER(3)    NOT NULL,
    nombre      VARCHAR2(30) NOT NULL
);
ALTER TABLE banco ADD CONSTRAINT banco_pk PRIMARY KEY (cod_banco);

/* ------------------------------------------------------------
   PERSONAS: PACIENTE, MEDICO, DIGITADOR
   ------------------------------------------------------------ */
CREATE TABLE paciente (
    rut_pac     NUMBER(8)    NOT NULL,
    dv_pac      CHAR(1)      NOT NULL,
    pnombre     VARCHAR2(25) NOT NULL,
    snombre     VARCHAR2(25),
    apaterno    VARCHAR2(25) NOT NULL,
    amaterno    VARCHAR2(25),
    edad        NUMBER(3)    NOT NULL,
    telefono    NUMBER(11)   NOT NULL,
    calle       VARCHAR2(50) NOT NULL,
    numeracion  NUMBER(5)    NOT NULL,
    id_comuna   NUMBER(5)    NOT NULL
);
ALTER TABLE paciente ADD CONSTRAINT paciente_pk PRIMARY KEY (rut_pac);
-- Dígito verificador solo admite 0 al 9 y K
ALTER TABLE paciente ADD CONSTRAINT paciente_dv_ck
    CHECK (dv_pac IN ('0','1','2','3','4','5','6','7','8','9','K'));
ALTER TABLE paciente ADD CONSTRAINT paciente_comuna_fk
    FOREIGN KEY (id_comuna) REFERENCES comuna (id_comuna);

CREATE TABLE medico (
    rut_med         NUMBER(8)    NOT NULL,
    dv_med          CHAR(1)      NOT NULL,
    pnombre         VARCHAR2(25) NOT NULL,
    snombre         VARCHAR2(25),
    apaterno        VARCHAR2(25) NOT NULL,
    amaterno        VARCHAR2(25),
    telefono        NUMBER(11)   NOT NULL,
    id_especialidad NUMBER(3)    NOT NULL
);
ALTER TABLE medico ADD CONSTRAINT medico_pk PRIMARY KEY (rut_med);
-- Dígito verificador solo admite 0 al 9 y K
ALTER TABLE medico ADD CONSTRAINT medico_dv_ck
    CHECK (dv_med IN ('0','1','2','3','4','5','6','7','8','9','K'));
-- Teléfono único: dos médicos no pueden compartir número
ALTER TABLE medico ADD CONSTRAINT medico_telefono_un UNIQUE (telefono);
ALTER TABLE medico ADD CONSTRAINT medico_especialidad_fk
    FOREIGN KEY (id_especialidad) REFERENCES especialidad (id_especialidad);

CREATE TABLE digitador (
    id_digitador NUMBER(6)    NOT NULL,
    rut_dig      NUMBER(8)    NOT NULL,
    dv_dig       CHAR(1)      NOT NULL,
    pnombre      VARCHAR2(25) NOT NULL,
    apaterno     VARCHAR2(25) NOT NULL
);
ALTER TABLE digitador ADD CONSTRAINT digitador_pk PRIMARY KEY (id_digitador);
ALTER TABLE digitador ADD CONSTRAINT digitador_rut_un UNIQUE (rut_dig);
-- Dígito verificador solo admite 0 al 9 y K
ALTER TABLE digitador ADD CONSTRAINT digitador_dv_ck
    CHECK (dv_dig IN ('0','1','2','3','4','5','6','7','8','9','K'));

/* ------------------------------------------------------------
   MEDICAMENTO
   Código alfanumérico según vista de usuario (ej. 1245F10)
   ------------------------------------------------------------ */
CREATE TABLE medicamento (
    cod_medicamento   VARCHAR2(10) NOT NULL,
    nombre            VARCHAR2(40) NOT NULL,
    dosis_recomendada VARCHAR2(50) NOT NULL,
    stock             NUMBER(6)    NOT NULL,
    id_tipo_med       NUMBER(3)    NOT NULL,
    id_via            NUMBER(3)    NOT NULL
);
ALTER TABLE medicamento ADD CONSTRAINT medicamento_pk PRIMARY KEY (cod_medicamento);
ALTER TABLE medicamento ADD CONSTRAINT medicamento_stock_ck CHECK (stock >= 0);
ALTER TABLE medicamento ADD CONSTRAINT medicamento_tipo_fk
    FOREIGN KEY (id_tipo_med) REFERENCES tipo_medicamento (id_tipo_med);
ALTER TABLE medicamento ADD CONSTRAINT medicamento_via_fk
    FOREIGN KEY (id_via) REFERENCES via_administracion (id_via);

/* ------------------------------------------------------------
   RECETA
   Un diagnóstico por receta; ingresada por un digitador
   ------------------------------------------------------------ */
CREATE TABLE receta (
    cod_receta        NUMBER(7)     NOT NULL,
    fecha_emision     DATE          NOT NULL,
    fecha_vencimiento DATE,
    observaciones     VARCHAR2(500),
    rut_pac           NUMBER(8)     NOT NULL,
    rut_med           NUMBER(8)     NOT NULL,
    id_digitador      NUMBER(6)     NOT NULL,
    cod_diagnostico   NUMBER(3)     NOT NULL,
    id_tipo_receta    NUMBER(3)     NOT NULL
);
ALTER TABLE receta ADD CONSTRAINT receta_pk PRIMARY KEY (cod_receta);
ALTER TABLE receta ADD CONSTRAINT receta_paciente_fk
    FOREIGN KEY (rut_pac) REFERENCES paciente (rut_pac);
ALTER TABLE receta ADD CONSTRAINT receta_medico_fk
    FOREIGN KEY (rut_med) REFERENCES medico (rut_med);
ALTER TABLE receta ADD CONSTRAINT receta_digitador_fk
    FOREIGN KEY (id_digitador) REFERENCES digitador (id_digitador);
ALTER TABLE receta ADD CONSTRAINT receta_diagnostico_fk
    FOREIGN KEY (cod_diagnostico) REFERENCES diagnostico (cod_diagnostico);
ALTER TABLE receta ADD CONSTRAINT receta_tipo_receta_fk
    FOREIGN KEY (id_tipo_receta) REFERENCES tipo_receta (id_tipo_receta);

/* ------------------------------------------------------------
   DOSIS
   Detalle de medicamentos de cada receta (uno o más)
   ------------------------------------------------------------ */
CREATE TABLE dosis (
    cod_receta        NUMBER(7)    NOT NULL,
    cod_medicamento   VARCHAR2(10) NOT NULL,
    unidades          NUMBER(3)    NOT NULL,
    descripcion_dosis VARCHAR2(50) NOT NULL,
    dias_tratamiento  NUMBER(3)    NOT NULL
);
ALTER TABLE dosis ADD CONSTRAINT dosis_pk PRIMARY KEY (cod_receta, cod_medicamento);
ALTER TABLE dosis ADD CONSTRAINT dosis_receta_fk
    FOREIGN KEY (cod_receta) REFERENCES receta (cod_receta);
ALTER TABLE dosis ADD CONSTRAINT dosis_medicamento_fk
    FOREIGN KEY (cod_medicamento) REFERENCES medicamento (cod_medicamento);

/* ------------------------------------------------------------
   PAGO
   Una receta puede tener uno o más pagos
   ------------------------------------------------------------ */
CREATE TABLE pago (
    cod_boleta  NUMBER(6)    NOT NULL,
    cod_receta  NUMBER(7)    NOT NULL,
    fecha_pago  DATE         NOT NULL,
    monto_total NUMBER(8)    NOT NULL,
    metodo_pago VARCHAR2(15) NOT NULL,
    cod_banco   NUMBER(3)
);
ALTER TABLE pago ADD CONSTRAINT pago_pk PRIMARY KEY (cod_boleta);
ALTER TABLE pago ADD CONSTRAINT pago_receta_fk
    FOREIGN KEY (cod_receta) REFERENCES receta (cod_receta);
ALTER TABLE pago ADD CONSTRAINT pago_banco_fk
    FOREIGN KEY (cod_banco) REFERENCES banco (cod_banco);
    
    /* ============================================================
   CASO 2: Modificaciones posteriores con ALTER TABLE
   ============================================================ */

-- Agrega el precio unitario de cada medicamento
ALTER TABLE medicamento ADD (precio_unitario NUMBER(7) NOT NULL);

-- El precio debe estar entre $1.000 y $2.000.000
ALTER TABLE medicamento ADD CONSTRAINT medicamento_precio_ck
    CHECK (precio_unitario BETWEEN 1000 AND 2000000);

-- Métodos de pago permitidos
ALTER TABLE pago ADD CONSTRAINT pago_metodo_ck
    CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA'));

-- Reemplaza la edad del paciente por su fecha de nacimiento
ALTER TABLE paciente DROP COLUMN edad;
ALTER TABLE paciente ADD (fecha_nacimiento DATE NOT NULL);