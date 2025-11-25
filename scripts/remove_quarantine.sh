#!/bin/bash
# Скрипт для удаления quarantine атрибута с приложения

APP_PATH="/Applications/iNotch.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Приложение не найдено: $APP_PATH"
    echo "Сначала переместите iNotch.app в /Applications"
    exit 1
fi

echo "🔓 Удаление quarantine атрибута..."
xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Quarantine атрибут удален"
    echo "Теперь можно запустить приложение:"
    echo "  open $APP_PATH"
else
    echo "⚠️  Quarantine атрибут не найден (возможно, уже удален)"
fi
