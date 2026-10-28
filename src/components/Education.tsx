import type { School } from '../data/types'
import { formatMonth } from '../lib/dates'
import LogoTile from './LogoTile'

export default function Education({ schools }: { schools: School[] }) {
  return (
    <ul className="divide-y divide-rule">
      {schools.map((school) => (
        <li key={school.name} className="flex gap-4 py-7 first:pt-0 last:pb-0">
          <LogoTile name={school.name} logo={school.logo} fill={school.logoFill} />
          <div className="min-w-0">
            <h3 className="font-semibold">{school.name}</h3>
            <p className="text-[15px]">{school.degree}</p>
            <p className="text-sm text-ink-3 tabular-nums">
              {school.expected ? 'Expected ' : ''}
              {formatMonth(school.end)}
            </p>
            <p className="text-sm text-ink-3">{school.location}</p>
          </div>
        </li>
      ))}
    </ul>
  )
}
