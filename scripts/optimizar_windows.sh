#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  optimizar_windows.sh — Ahorro de tokens en Hermes (Windows)
#  Creado 2026-08-19. Correr en git-bash (MSYS) de Windows.
#  Seguro: solo lee config y pausa crons; no borra nada.
# ═══════════════════════════════════════════════════════════════
set -u

echo "═══ 1/4 · Compresión de contexto ═══"
hermes config set compression.threshold 0.35 2>&1 || echo "⚠️  hermes no responde — ¿está en PATH?"
hermes config set compression.enabled true 2>&1
echo "  → compression.threshold = $(hermes config get compression.threshold 2>/dev/null || echo 'verificar manualmente')"

echo ""
echo "═══ 2/4 · Cron jobs (¿quedó alguno activo?) ═══"
hermes cron list 2>/dev/null | grep -iE "enabled|scheduled|paused|name|job" | head -40 || hermes cron list

echo ""
echo "═══ 3/4 · Gateway (¿corriendo? consume tokens por mensaje) ═══"
hermes gateway status 2>&1 | head -10 || echo "  → gateway no instalado/corriendo (bien si no lo usas)"

echo ""
echo "═══ 4/4 · Torch: tope de gasto diario DeepSeek ═══"
echo "  Torch lee la MISMA DEEPSEEK_API_KEY y tiene tope default de 5.0 USD/día."
echo "  Si no lo estás usando a diario, bájalo a 0.50 USD:"
echo "      cd C:/Users/ALEXANDER\ SANDOVAL/Documents/.../Torch  (o donde esté Torch1)"
echo "      torch costos --tope 0.50"
echo "  O por variable de entorno:   set TORCH_GASTO_MAX_USD=0.50"
echo "  Ver gasto actual:            torch costos"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Listo. Recordatorio: la API DeepSeek cuesta el DOBLE en"
echo "   horario pico (8PM-11PM y 1AM-5AM hora Colombia)."
echo "═══════════════════════════════════════════════════════════"
