#!/usr/bin/env python3
import sys, os, json, re

def analyze(code_path):
    has_readme = os.path.exists(os.path.join(code_path, 'README.md'))
    score, details = 0.0, []

    if has_readme:
        size = os.path.getsize(os.path.join(code_path, 'README.md'))
        if size > 500:
            score += 30
            details.append(f"✓ README.md присутствует ({size} байт) — +30")
        else:
            score += 10
            details.append(f"⚠ README.md слишком короткий ({size} байт) — +10")
    else:
        details.append("✗ README.md отсутствует — +0")

    total_public, documented = 0, 0
    has_logging = False

    for root, dirs, files in os.walk(code_path):
        dirs[:] = [d for d in dirs if d not in ('build', '.gradle', '.idea', '.git')]
        for f in files:
            if not f.endswith(('.kt', '.java', '.dart')):
                continue
            try:
                content = open(os.path.join(root, f), encoding='utf-8', errors='ignore').read()
                # Count public declarations
                public_items = re.findall(r'\b(?:fun|class|object|interface|abstract class)\s+\w+', content)
                total_public += len(public_items)
                # Count KDoc/JavaDoc comments
                doc_comments = re.findall(r'/\*\*.*?\*/', content, re.DOTALL)
                documented += min(len(doc_comments), len(public_items))
                # Check for logging
                if 'LoggerFactory' in content or 'Logger' in content or 'log.' in content:
                    has_logging = True
            except Exception:
                pass

    if total_public > 0:
        ratio = documented / total_public
        doc_score = round(ratio * 50, 1)
        score += doc_score
        details.append(f"✓ Задокументировано {documented}/{total_public} публичных элементов — +{doc_score}")
    else:
        details.append("⚠ Публичные элементы не найдены — +0")

    if has_logging:
        score += 20
        details.append("✓ Логирование найдено — +20")
    else:
        details.append("✗ Логирование не найдено — +0")

    score = min(100.0, score)
    status = "passed" if score >= 30 else "failed"
    log = f"Итог: {score:.1f}/100\n\n" + "\n".join(details)
    return {"status": status, "score": score, "log": log}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
