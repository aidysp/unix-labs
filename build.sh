#!/bin/sh



if [ -z "$1" ]; then
  echo "Ошибка: Не указан исходный файл." >&2
  echo "Использование: $0 <исходный_файл>" >&2
  exit 1
fi

SRC_FILE="$1"

if [ ! -f "$SRC_FILE" ]; then
  echo "Ошибка: Файл '$SRC_FILE' не найден." >&2
  exit 2
fi

TARGET_DIR=$(pwd)
SRC_BASENAME=${SRC_FILE##*/} 

OUT_NAME=$(grep -i -E '^([[:space:]]*([\/%#*])+)+.*[Oo]utput:' "$SRC_FILE" | sed -E 's/.*[Oo]utput:[[:space:]]*([^[:space:]]+).*/\1/' | head -n 1)


if [ -z "$OUT_NAME" ]; then
    echo "Ошибка: В файле не найден комментарий с ключевым словом 'Output:'." >&2
    exit 3
fi


TMP_DIR=$(mktemp -d)
if [ ! -d "$TMP_DIR" ]; then
    echo "Ошибка: Не удалось создать временный каталог." >&2
    exit 4
fi


cleanup() {
    rm -rf "$TMP_DIR"
}


cleanup_signal() {
    rm -rf "$TMP_DIR"
    exit 128
}
trap cleanup EXIT
trap cleanup_signal HUP INT QUIT PIPE TERM

SRC_ABS_PATH=$(cd "$(dirname "$SRC_FILE")" && pwd)/$SRC_BASENAME
cp "$SRC_ABS_PATH" "$TMP_DIR/$SRC_BASENAME"


cd "$TMP_DIR" || exit 5

case "$SRC_BASENAME" in
    *.c)
        gcc -Wall -Wextra -O2 -o "$OUT_NAME" "$SRC_BASENAME" || exit 7
        ;;
    *.cpp|*.cc)
        g++ -Wall -Wextra -O2 -o "$OUT_NAME" "$SRC_BASENAME" || exit 7
        ;;
    *.tex)
        # Для TeX документов (компилируем и переименовываем в целевое имя)
        pdflatex -interaction=nonstopmode "$SRC_BASENAME" || exit 7
        TEX_PDF="${SRC_BASENAME%.tex}.pdf"
        if [ -f "$TEX_PDF" ]; then
            mv "$TEX_PDF" "$OUT_NAME"
	      else
	          exit 7
        fi
        ;;
    *)
        echo "Ошибка: Неподдерживаемый тип файла для сборки." >&2
        exit 6
        ;;
esac

mv "$OUT_NAME" "$TARGET_DIR/$OUT_NAME"

echo "Сборка успешно завершена. Файл сохранен как: $TARGET_DIR/$OUT_NAME"
exit 0
