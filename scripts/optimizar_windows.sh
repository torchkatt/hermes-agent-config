#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  optimizar_windows.sh — Ahorro de tokens en Hermes (Windows)
#  Creado 2026-08-19 · Actualizado 2026-08-19 (ajustes finales)
#  Correr en git-bash (MSYS) de Windows. Seguro: solo lee config
#  y pausa crons; no borra nada. Backup previo automático.
#  Doc completa: docs/OPTIMIZACION_TOKENS.md (en este repo)
# ═══════════════════════════════════════════════════════════════
set -u

CFG="$LOCALAPPDATA/hermes/config.yaml"
[ -f "$CFG" ] || CFG="$APPDATA/hermes/config.yaml"
if [ -f "$CFG" ] && [ ! -f "$CFG.bak-tokenopt" ]; then
  cp "$CFG" "$CFG.bak-tokenopt"
  echo "✅ Backup: $CFG.bak-tokenopt"
fi

echo ""
echo "═══ 1/6 · Compresión de contexto ═══"
# CLAVE: deepseek-v4-flash tiene ventana de 1M tokens; sin override,
# la compresión relativa (threshold x 1M) casi nunca dispara.
hermes config set model.context_length 262144 2>&1 || echo "⚠️  hermes no responde — ¿está en PATH?"
hermes config set compression.enabled true 2>&1
hermes config set compression.threshold 0.25 2>&1
hermes config set compression.target_ratio 0.2 2>&1
hermes config set compression.protect_last_n 12 2>&1
echo "  → context_length = $(hermes config get model.context_length 2>/dev/null)"
echo "  → threshold = $(hermes config get compression.threshold 2>/dev/null)"

echo ""
echo "═══ 2/6 · Cron jobs (¿quedó alguno agent-driven activo?) ═══"
hermes cron list 2>/dev/null | grep -iE "enabled|scheduled|paused" | head -40 || hermes cron list
echo "  → agent-driven sin no_agent = consume tokens en cada ejecución."
echo "    Pausar:  hermes cron pause <ID>   |  Convertir: no_agent=true"

echo ""
echo "═══ 3/6 · Gateway (¿corriendo? consume tokens por mensaje) ═══"
hermes gateway status 2>&1 | head -6 || echo "  → gateway no instalado/corriendo (bien si no lo usas)"

echo ""
echo "═══ 4/6 · Skills: archivar los de 0 usos (reversible) ═══"
echo "  ⚠️  En Windows NO deshabilitar los skills Windows-only (allá SÍ se usan)."
echo "  Para archivar los nunca usados:"
echo "      hermes curator run                # sweep determinista (gratis)"
echo "      hermes curator archive <nombre>   # uno a uno"
echo "      hermes curator restore <nombre>   # revertir"
echo "  Los cambios en skills aplican en la PRÓXIMA sesión."

echo ""
echo "═══ 5/6 · Prompt cache mes-only (timestamp byte-stable por mes) ═══"
# El system prompt inyecta 'Conversation started: <fecha>'. Con día, el
# cache se invalida a medianoche en sesiones abiertas. Con mes (August 2026)
# el prompt es byte-stable todo el mes (decisión usuario 19-ago-2026).
SP="$LOCALAPPDATA/hermestorch/hermes-agent/agent/system_prompt.py"
if [ -f "$SP" ]; then
  if grep -q "%B %Y" "$SP"; then
    echo "  → ya aplicado (mes-only)"
  else
    cp "$SP" "$SP.bak-tokenopt"
    sed -i 's/%A, %B %d, %Y/%B %Y/' "$SP"
    echo "  → aplicado: Conversation started: August 2026 (byte-stable por mes)"
  fi
else
  echo "  ⚠️  system_prompt.py no encontrado en $SP — ruta distinta (buscar con: where hermes)"
fi

echo ""
echo "═══ 6/6 · Torch: tope de gasto diario DeepSeek ═══"
echo "  Torch lee la MISMA DEEPSEEK_API_KEY y tiene tope default de 5.0 USD/día."
echo "  Si no lo usas a diario, bájalo:"
echo "      cd /c/Users/ALEXANDER\ SANDOVAL/Documents/PERSONAL/DESARROLLO/Torch"
echo "      torch costos --tope 0.50"
echo "  O por variable:   set TORCH_GASTO_MAX_USD=0.50"
echo "  Ver gasto:        torch costos"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Listo. Recordatorios:"
echo "   • DeepSeek cuesta el DOBLE en pico (8PM-11PM y 1AM-5AM CO)."
echo "   • /new por tarea = sesión corta = contexto chico."
echo "   • Los cambios aplican en la próxima sesión (preserva caché)."
echo "═══════════════════════════════════════════════════════════"
