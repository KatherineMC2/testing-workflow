#!/bin/sh

# Define el patrón esperado para el mensaje de commit
PATTERN="^(feat|fix|docs|style|refactor|qa|test|setup|data|release): [A-Z][a-zA-Z0-9 ]{1,48}$"

# Ruta al archivo de verbos imperativos
VERBS_FILE=".hooks/imperative-verbs.txt"

# Verifica que el archivo de verbos existe
if [ ! -f "$VERBS_FILE" ]; then
    echo "Error: imperative-verbs.txt file not found at $VERBS_FILE"
    echo "Please create this file with a list of valid imperative verbs."
    exit 1
fi

# Detecta y corrige finales de línea tipo Windows (CRLF)
if file "$VERBS_FILE" | grep -q "CRLF"; then
  echo "🛠 Fixing Windows-style line endings in $VERBS_FILE..."
  sed -i 's/\r$//' "$VERBS_FILE"
fi

# Verifica que el archivo tenga al menos una línea válida (no vacía ni comentario)
VALID_VERB_LINE=$(grep -vE '^\s*#|^\s*$' "$VERBS_FILE" | head -n 1)

if [ -z "$VALID_VERB_LINE" ]; then
  echo "Error: No imperative verbs found in $VERBS_FILE"
  exit 1
fi

# Lee el mensaje de commit desde el archivo proporcionado por Git
MESSAGE=$(cat "$1")

# Verifica si el mensaje cumple con el patrón general
if ! echo "$MESSAGE" | grep -qE "$PATTERN"; then
    echo "❌ Error: The commit message does not match the required format."
    echo "📋 Expected format: <type>: <Subject> (max 50 characters, starts with capital)"
    echo "📝 Your message: '$MESSAGE'"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, qa, test, setup, data, release"
    echo "Example: 'feat: Add user authentication'"
    exit 1
fi

# Extrae el subject (después de los dos puntos y espacios)
SUBJECT=$(echo "$MESSAGE" | sed 's/^[^:]*: *//')

# Extrae la primera palabra del subject
FIRST_WORD=$(echo "$SUBJECT" | cut -d' ' -f1)

# Convierte la primera palabra a minúsculas para la comparación
FIRST_WORD_LOWER=$(echo "$FIRST_WORD" | tr '[:upper:]' '[:lower:]')

# Verifica si la primera palabra comienza con mayúscula
if ! echo "$FIRST_WORD" | grep -qE "^[A-Z][a-zA-Z]*$"; then
    echo "❌ Error: The first word must start with a capital letter and contain only letters."
    echo "📝 Your first word: '$FIRST_WORD'"
    exit 1
fi

# Verifica si la primera palabra (en minúsculas) está en la lista de verbos imperativos
if ! grep -i -Fxq "$FIRST_WORD_LOWER" "$VERBS_FILE"; then
    echo "❌ Error: The first word must be an imperative verb in English."
    echo "📝 Your first word: '$FIRST_WORD' (not found in imperative verbs list)"
    echo "💡 Example: 'feat: Add new feature' instead of 'feat: Added new feature'"
    echo "📄 Check $VERBS_FILE for valid verbs."
    exit 1
fi

# Verifica que el texto esté en inglés (no contenga caracteres del español)
if echo "$SUBJECT" | grep -qE "[ñáéíóúüÑÁÉÍÓÚÜ]"; then
    echo "❌ Error: The commit message must be written in English."
    echo "📝 Your message contains Spanish characters: '$SUBJECT'"
    echo "💡 Example: 'feat: Add new feature' instead of 'feat: Añadir nueva funcionalidad'"
    exit 1
fi

# Si llegamos aquí, el mensaje es válido
echo "✅ Commit message format is valid!"
exit 0
