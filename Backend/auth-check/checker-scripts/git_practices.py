#!/usr/bin/env python3
import sys, os, json, subprocess

BAD_MESSAGES = {'fix', 'update', 'init', 'wip', 'test', 'commit', 'changes', 'work', 'done', 'misc'}

def run_git(args, cwd, timeout=30):
    try:
        r = subprocess.run(['git'] + args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip()
    except Exception:
        return ""

def analyze(code_path):
    if not os.path.exists(os.path.join(code_path, '.git')):
        return {"status": "failed", "score": 0.0,
                "log": ".git директория не найдена. Решение должно быть Git-репозиторием."}

    score, details = 0.0, []

    # Commit count and quality
    log_out = run_git(['log', '--oneline', '-30'], code_path)
    commits = [c for c in log_out.split('\n') if c.strip()]
    commit_count = len(commits)

    if commit_count >= 5:
        score += 30
        details.append(f"✓ История коммитов: {commit_count} коммитов — +30")
    elif commit_count >= 2:
        score += 15
        details.append(f"⚠ Мало коммитов: {commit_count} — +15")
    else:
        details.append(f"✗ Очень мало коммитов: {commit_count} — +0")

    # Message quality
    meaningful = sum(
        1 for c in commits
        if c.split(' ', 1)[-1].strip().lower() not in BAD_MESSAGES
        and len(c.split(' ', 1)[-1].strip()) > 10
    )
    if commit_count > 0 and meaningful / commit_count >= 0.7:
        score += 30
        details.append(f"✓ Качественные сообщения коммитов ({meaningful}/{commit_count}) — +30")
    elif commit_count > 0:
        score += 10
        details.append(f"⚠ Много шаблонных сообщений коммитов ({meaningful}/{commit_count}) — +10")

    # Branch count
    branches_out = run_git(['branch', '-a'], code_path)
    branches = [b.strip() for b in branches_out.split('\n') if b.strip()]
    if len(branches) > 1:
        score += 40
        details.append(f"✓ Несколько веток ({len(branches)}) — +40")
    else:
        score += 10
        details.append("⚠ Только одна ветка (main/master) — +10")

    score = min(100.0, score)
    status = "passed" if score >= 50 else "failed"
    log = f"Итог: {score:.1f}/100\n\n" + "\n".join(details)
    return {"status": status, "score": score, "log": log}

if __name__ == "__main__":
    result = analyze(sys.argv[1] if len(sys.argv) > 1 else "/code")
    print(json.dumps(result, ensure_ascii=False))
