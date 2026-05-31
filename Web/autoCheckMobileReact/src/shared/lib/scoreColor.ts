export function scoreTone(score: number | null | undefined) {
  if (score == null) {
    return 'text-[#a0aec0]'
  }
  if (score >= 80) {
    return 'text-[#00ff66]'
  }
  if (score >= 50) {
    return 'text-[#f5f7fb]'
  }
  return 'text-[#ff7a3d]'
}

export function progressTone(score: number | null | undefined) {
  if (score == null) {
    return 'bg-[#687386]'
  }
  if (score >= 80) {
    return 'bg-[#00ff66]'
  }
  if (score >= 50) {
    return 'bg-[#f5f7fb]'
  }
  return 'bg-[#ff5500]'
}
