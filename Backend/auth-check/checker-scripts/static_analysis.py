#!/usr/bin/env python3
import sys, os, json, re

def analyze(code_path):
    source_files = []
    for root, dirs, files in os.walk(code_path):
        dirs[:] = [d for d in dirs if d not in ('build', '.gradle', '.idea', '__pycache__', 'node_modules', '.git')]
        for f in files:
            if f.endswith(('.kt', '.java', '.dart')):
                source_files.append(os.path.join(root, f))

    if not source_files:
        return {"status": "error", "score": None, "log": "Исходные файлы не найдены (.kt, .java, .dart)"}

    errors, warnings, details = 0, 0, []

    for filepath in source_files:
        filename = os.path.basename(filepath)
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            for i, line in enumerate(lines, 1):
                s = line.strip()
                if 'TODO' in s or 'FIXME' in s:
                    warnings += 1
                    details.append(f"[WARN] {filename}:{i} — TODO/FIXME")
                if any(s.startswith(p) for p in ('println(', 'print(', 'System.out', 'Log.d(')):
                    warnings += 1
                    details.append(f"[WARN] {filename}:{i} — print-statement (используйте Logger)")
                if len(line.rstrip()) > 200:
                    warnings += 1
                    details.append(f"[WARN] {filename}:{i} — строка >200 символов")
                if re.search(r'catch\s*\(.*\)\s*\{\s*\}', s):
                    errors += 1
                    details.append(f"[ERROR] {filename}:{i} — пустой catch-блок")
        except Exception as e:
            warnings += 1
            details.append(f"[WARN] Ошибка чтения {filename}: {e}")

    score = max(0.0, 100.0 - errors * 5.0 - warnings * 1.0)
    status = "passed" if score >= 50 else "failed"
    log_lines = [
        f"Проверено файлов: {len(source_files)}",
        f"Ошибки: {errors}, Предупреждения: {warnings}",
        f"Итоговый балл: {score:.1f}",
        "",
    ] + details[:60]
    return {"status": status, "score": score, "log": "\n".join(log_lines)}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
