# Optimización de Tokens — Hermes TorchKatt (Mac + Windows)

> Documento operativo. Aplica a las dos instancias de Hermes que comparten la
> misma `DEEPSEEK_API_KEY` (Mac `~/.hermes` y Windows `%LOCALAPPDATA%\hermes`).
> Fecha: 2026-08-19. Autoridad: esta guía + `config.yaml` del repo.

## Contexto: por qué se hizo

Factura DeepSeek de ~$54.68 USD en 30 días (7.86 mil millones de tokens,
31,676 requests). El caché funciona (99.2% de hits — sin él costaría ~$1,100),
pero el VOLUMEN era alto por tres fugas:

1. **Ventana de 1M tokens de deepseek-v4-flash** → la compresión relativa de
   Hermes (`threshold × context_length`) casi nunca disparaba: umbral efectivo
   ~350K con threshold 0.35, y las sesiones maratón llegaban a ~300K.
   Resultado: historial completo reenviado turno tras turno.
2. **Índice de skills = 66% del system prompt** (401 skills, ~9,315 tokens por
   llamada API) — 73 con cero usos y 8 Windows-only muertos.
3. **Horario pico DeepSeek ×2** (8PM-11PM y 1AM-5AM hora Colombia).

## Cambios aplicados (Mac — `~/.hermes/config.yaml`)

```yaml
model:
  context_length: 262144            # ← override de la ventana 1M (clave del fix)

compression:
  enabled: true
  threshold: 0.25                   # comprime al pasar ~92K de contexto
  target_ratio: 0.2                 # compacta a ~52K
  protect_last_n: 12                # últimos 12 mensajes intactos (calidad)
  # protect_first_n: 3 (default)    # inicio de sesión intacto

skills:
  platform_disabled:
    desktop: [hermes-windows-service, network-discovery-windows,
              windows-cmd-hide, windows-network-troubleshooting,
              windows-python-scripting]   # solo en Mac (allá no aplican)
```

### Archivado de skills (reversible — `hermes curator restore <nombre>`)

- **73 skills con 0 usos** archivados a `~/.hermes/skills/.archive/` (2026-08-19).
- **3 duplicados** consolidados: `computer-use`, `systematic-debugging`,
  `dogfood` (se conservó la versión adaptada local).
- Índice de skills: **401 → 320 entradas** (−21% del system prompt).
- Memoria consolidada: 6,000 → 5,306 chars (reglas S1-S12 + PIEDRA + TORCH
  fusionadas en una entrada; detalle completo en CLAUDE.md §0 del proyecto).

## Checklist para WINDOWS (adaptado — NO copiar a ciegas)

La instancia Windows (`C:\Users\ALEXANDER SANDOVAL\AppData\Local\hermes`)
debe aplicar lo mismo, ADAPTADO:

```bash
# 1. En git-bash (MSYS), desde %LOCALAPPDATA%\hermes
hermes config set model.context_length 262144
hermes config set compression.threshold 0.25
hermes config set compression.protect_last_n 12
hermes config set compression.enabled true
hermes config set compression.target_ratio 0.2

# 2. NUNCA deshabilitar skills Windows-only en Windows (allá SÍ se usan).
#    El archivado de skills de 0 usos SÍ aplica igual (curator).

# 3. Crons: verificar que sigan pausados o convertidos a no_agent
hermes cron list

# 4. Torch (misma clave DeepSeek, tope default $5/día — acotar si no se usa a diario)
cd /c/Users/ALEXANDER\ SANDOVAL/Documents/PERSONAL/DESARROLLO/Torch
torch costos --tope 0.50      # o: set TORCH_GASTO_MAX_USD=0.50

# 5. Verificar
hermes config get model.context_length   # → 262144
hermes config get compression.threshold  # → 0.25
```

### Diferencias Mac ↔ Windows (no copiar ciegas)

| Ajuste | Mac | Windows |
|---|---|---|
| `skills.platform_disabled.desktop` | Windows-only deshabilitados | **No tocar** (allá aplican) |
| `optimizar_windows.sh` | — | Correr en git-bash |
| Crons agent-driven | Pausados (2026-08-18) | Pausados (2026-08-18) |
| Torch tope | No aplica (Torch vive en Windows) | `torch costos --tope` |
| Backup config | `config.yaml.bak-20260819` | Antes de tocar: `copy config.yaml config.yaml.bak` |

## Recordatorios permanentes

- **Horario pico DeepSeek ×2**: evitar trabajo pesado 8PM-11PM y 1AM-5AM (CO).
- **`/new` por tarea**: sesión corta = contexto chico = menos tokens por turno.
- **Los cambios de config toman efecto en la sesión siguiente** (system prompt
  byte-stable por diseño para preservar caché).
- El caché es el mayor ahorro: NUNCA cambiar el system prompt a media sesión
  (invalida el caché → todo el historial se reenvía a precio de miss, 50× más).
- Torch (Windows) lee la MISMA `DEEPSEEK_API_KEY` — su gasto aparece en el
  mismo dashboard de DeepSeek sin desglose por app.

## Timestamp mes-only (19-ago-2026)

El system prompt termina con `Conversation started: <fecha>`. Con día exacto,
el caché se invalidaba a medianoche en toda sesión abierta (1 miss de todo el
contexto, 50× más caro). Ahora es **mes-only**: `Conversation started: August
2026` → prompt byte-stable TODO el mes, y las compresiones tampoco invalidan.

- Aplicado en Mac: `agent/system_prompt.py` (línea ~780). ⚠️ **Se pierde con
  `hermes update`** → reaplicar el sed (también en `optimizar_windows.sh` §5/6).
- El modelo puede consultar la hora exacta con tools (`date`) cuando lo necesites.
- Backup: `agent/system_prompt.py.bak-20260819`.
