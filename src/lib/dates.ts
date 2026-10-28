import type { YearMonth } from '../data/types'

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

function parse(value: YearMonth) {
  const [year, month] = value.split('-').map(Number)
  return { year, month }
}

function currentMonth(): YearMonth {
  const now = new Date()
  return `${now.getFullYear()}-${now.getMonth() + 1}`
}

export function formatMonth(value: YearMonth) {
  const { year, month } = parse(value)
  return `${MONTHS[month - 1]} ${year}`
}

export function formatRange(start: YearMonth, end?: YearMonth) {
  return `${formatMonth(start)} – ${end ? formatMonth(end) : 'Present'}`
}

/** Inclusive month count, the way LinkedIn counts it (Jun–Aug is 3 mos). */
export function monthsBetween(start: YearMonth, end: YearMonth = currentMonth()) {
  const a = parse(start)
  const b = parse(end)
  return (b.year - a.year) * 12 + (b.month - a.month) + 1
}

export function formatDuration(months: number) {
  const years = Math.floor(months / 12)
  const rest = months % 12
  const parts = []
  if (years) parts.push(`${years} ${years === 1 ? 'yr' : 'yrs'}`)
  if (rest) parts.push(`${rest} ${rest === 1 ? 'mo' : 'mos'}`)
  return parts.join(' ')
}

/** Total span of a set of roles: earliest start to latest end (or today if any role is ongoing). */
export function spanOf(roles: { start: YearMonth; end?: YearMonth }[]) {
  const toIndex = (v: YearMonth) => parse(v).year * 12 + parse(v).month
  const start = roles.reduce((min, r) => (toIndex(r.start) < toIndex(min) ? r.start : min), roles[0].start)
  const ongoing = roles.some((r) => !r.end)
  const end = ongoing
    ? undefined
    : roles.reduce((max, r) => (toIndex(r.end!) > toIndex(max) ? r.end! : max), roles[0].end!)
  return monthsBetween(start, end)
}
