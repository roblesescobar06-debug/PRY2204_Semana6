# PRY2204 - Semana 6: Implementando un modelo relacional con sentencias SQL

Consultorio Médico Municipalidad Santa Gema — Modelamiento de Bases de Datos, Duoc UC.

## Contenido

`PRY2204_S6_Santa_Gema.sql` — script DDL ejecutable secuencialmente en Oracle con el usuario `PRY2204_S6`.

- **Borrado de objetos** al inicio para permitir reejecución sin errores.
- **Caso 1:** creación de 16 tablas normalizadas con constraints PK, FK, UN, CK y NN.
  - `ESPECIALIDAD` con identificador `IDENTITY`.
  - `COMUNA` con identificador `IDENTITY` que inicia en 1101.
  - Teléfono único por médico.
  - Dígito verificador (0-9, K) en paciente, médico y digitador.
- **Caso 2:** modificaciones con `ALTER TABLE`.
  - Precio unitario del medicamento entre $1.000 y $2.000.000.
  - Métodos de pago: EFECTIVO, TARJETA, TRANSFERENCIA.
  - Reemplazo de `edad` por `fecha_nacimiento` en paciente.
