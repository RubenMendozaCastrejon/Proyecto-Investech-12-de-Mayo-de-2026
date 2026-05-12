Actúa como un administrador de base de datos proyecto Investech (que es una plataforma digital de inversiones), que entidades se necesitan para su gestión.

Como administrador de base de datos de **Investech**, las entidades principales del sistema se pueden agrupar en varios dominios. Aquí tienes el modelo entidad-relación completo:Las 13 entidades se organizan en cuatro dominios funcionales:
<img width="1440" height="2368" alt="image" src="https://github.com/user-attachments/assets/905dc32b-2150-4672-8f6a-0d41e043cc43" />

**Identidad y acceso** — `USUARIO`, `SESION`, `DOCUMENTO`, `PERFIL_RIESGO`. Gestiona el ciclo de vida del cliente: registro KYC, autenticación, y evaluación de tolerancia al riesgo regulatoria.
**Cuentas y dinero** — `CUENTA`, `TRANSACCION`. Cada usuario puede tener múltiples cuentas (efectivo, margen, custodia). Las transacciones registran depósitos, retiros y movimientos internos con trazabilidad contable.
**Operativa de mercado** — `ORDEN`, `EJECUCION`. Una orden puede fraccionarse en múltiples ejecuciones (fills parciales). Se distingue el tipo (mercado/límite/stop), el lado (compra/venta) y el estado del ciclo de vida (pendiente → activa → ejecutada → cancelada).
**Instrumentos y mercados** — `INSTRUMENTO`, `MERCADO`, `PRECIO_HISTORICO`, `PORTAFOLIO`, `POSICION`. El catálogo de instrumentos (acciones, ETFs, bonos, cripto) se liga a mercados con zona horaria propia. Las posiciones en cada portafolio se valúan a precio de mercado en tiempo real.

Algunas consideraciones de diseño relevantes para esta base:
- `PRECIO_HISTORICO` crecerá muy rápido; conviene particionarla por `fecha` desde el inicio.
- `EJECUCION` y `TRANSACCION` son candidatas a almacenamiento append-only (sin updates) para mantener el audit trail.
- `PERFIL_RIESGO` debe versionar sus registros, no sobreescribirlos, por requisitos regulatorios.

¿Quieres profundizar en algún dominio, ver los índices recomendados, o revisar las reglas de negocio de alguna entidad en particular?
