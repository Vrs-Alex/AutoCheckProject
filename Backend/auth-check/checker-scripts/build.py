#!/usr/bin/env python3
import sys, os, json, subprocess

def analyze(code_path):
    if os.path.exists(os.path.join(code_path, 'pubspec.yaml')):
        cmd, build_system = ['flutter', 'build', 'apk', '--debug'], 'Flutter'
    elif os.path.exists(os.path.join(code_path, 'build.gradle.kts')) or \
         os.path.exists(os.path.join(code_path, 'build.gradle')):
        cmd, build_system = ['./gradlew', 'build', '-x', 'test', '--no-daemon'], 'Gradle'
    elif os.path.exists(os.path.join(code_path, 'pom.xml')):
        cmd, build_system = ['mvn', 'package', '-DskipTests', '-q'], 'Maven'
    else:
        return {"status": "error", "score": None,
                "log": "Система сборки не определена. Ожидается Gradle, Flutter или Maven."}

    try:
        result = subprocess.run(cmd, cwd=code_path, capture_output=True, text=True, timeout=170)
        output = (result.stdout + result.stderr)[:3000]
        score = 100.0 if result.returncode == 0 else 0.0
        status = "passed" if result.returncode == 0 else "failed"
        log = f"Система сборки: {build_system}\nКод завершения: {result.returncode}\n\n{output}"
        return {"status": status, "score": score, "log": log}
    except subprocess.TimeoutExpired:
        return {"status": "error", "score": None, "log": "Превышено время сборки (170с)"}
    except FileNotFoundError as e:
        return {"status": "error", "score": None, "log": f"Инструмент сборки не найден: {e}"}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
