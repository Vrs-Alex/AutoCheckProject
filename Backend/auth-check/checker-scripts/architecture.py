#!/usr/bin/env python3
import sys, os, json

LAYERS = ['domain', 'presentation', 'data', 'infrastructure', 'repository']

def analyze(code_path):
    found = {layer: False for layer in LAYERS}

    for root, dirs, files in os.walk(code_path):
        dirs[:] = [d for d in dirs if d not in ('build', '.gradle', '.idea', '.git')]
        rel = os.path.relpath(root, code_path).lower()
        for layer in LAYERS:
            if layer in rel:
                found[layer] = True

    has_readme = os.path.exists(os.path.join(code_path, 'README.md'))
    no_direct_ui_repo = True  # simplified: assume clean if layers exist

    found_count = sum(1 for v in found.values() if v)
    score = min(100.0, found_count * 25.0)
    if has_readme:
        score = min(100.0, score + 10.0)

    details = []
    for layer, present in found.items():
        details.append(f"  [{'✓' if present else '✗'}] Слой '{layer}' обнаружен")
    if has_readme:
        details.append("  [✓] README.md присутствует")
    else:
        details.append("  [✗] README.md отсутствует")

    status = "passed" if score >= 50 else "failed"
    log = f"Пройдено слоёв: {found_count}/{len(LAYERS)}\nБалл: {score:.1f}\n\n" + "\n".join(details)
    return {"status": status, "score": score, "log": log}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
