const emailRe = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i

export function validateEmail(value: string) {
  if (!value.trim()) {
    return 'Email обязателен'
  }
  if (!emailRe.test(value.trim())) {
    return 'Введите корректный email'
  }
  return ''
}

export function validateRequired(value: string, label: string) {
  return value.trim() ? '' : `${label} обязательно`
}

export function validateGitUrl(value: string) {
  if (!value.trim()) {
    return 'Git URL обязателен'
  }
  if (!value.startsWith('https://')) {
    return 'Ссылка должна начинаться с https://'
  }
  return ''
}
