#!/usr/bin/env python3
import sys, os, json, subprocess, re

def analyze(code_path):
    test_files = []
    for root, dirs, files in os.walk(code_path):
        dirs[:] = [d for d in dirs if d not in ('build', '.gradle', '.idea', '.git')]
        for f in files:
            if 'Test' in f or 'Spec' in f or f.endswith('_test.dart'):
                test_files.append(os.path.join(root, f))

    if not test_files:
        return {"status": "failed", "score": 0.0,
                "log": "Тестовые файлы не найдены (*Test.kt, *Spec.kt, *_test.dart)"}

    if os.path.exists(os.path.join(code_path, 'pubspec.yaml')):
        cmd = ['flutter', 'test']
    elif os.path.exists(os.path.join(code_path, 'build.gradle.kts')) or \
         os.path.exists(os.path.join(code_path, 'build.gradle')):
        cmd = ['./gradlew', 'test', '--no-daemon']
    else:
        return {"status": "error", "score": None, "log": "Система сборки не определена для запуска тестов"}

    try:
        result = subprocess.run(cmd, cwd=code_path, capture_output=True, text=True, timeout=170)
        output = (result.stdout + result.stderr)[:3000]

        total_m = re.search(r'(\d+) tests?', output)
        failed_m = re.search(r'(\d+) failed', output)
        total = int(total_m.group(1)) if total_m else 0
        failed = int(failed_m.group(1)) if failed_m else 0
        passed = total - failed

        score = round((passed / total * 100), 2) if total > 0 else 0.0
        score = max(0.0, min(100.0, score))
        status = "passed" if result.returncode == 0 and score >= 50 else "failed"

        log = f"Тестовых файлов: {len(test_files)}\nПройдено: {passed}/{total}\nБалл: {score:.1f}\n\n{output}"
        return {"status": status, "score": score, "log": log}
    except subprocess.TimeoutExpired:
        return {"status": "error", "score": None, "log": "Превышено время выполнения тестов (170с)"}
    except FileNotFoundError as e:
        return {"status": "error", "score": None, "log": f"Инструмент тестирования не найден: {e}"}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
