import type { Company, Role } from '../data/types'
import { formatDuration, formatRange, monthsBetween, spanOf } from '../lib/dates'
import LogoTile from './LogoTile'

function RoleDetails({ role }: { role: Role }) {
  return (
    <>
      <p className="text-sm text-ink-3 tabular-nums">
        {formatRange(role.start, role.end)} · {formatDuration(monthsBetween(role.start, role.end))}
      </p>
      {role.location && <p className="text-sm text-ink-3">{role.location}</p>}
      {role.description && <p className="mt-2 text-[15px] leading-relaxed text-ink-2">{role.description}</p>}
    </>
  )
}

function SingleRole({ company }: { company: Company }) {
  const role = company.roles[0]
  return (
    <div className="flex gap-4">
      <LogoTile name={company.name} logo={company.logo} fill={company.logoFill} />
      <div className="min-w-0">
        <h3 className="font-semibold">{role.title}</h3>
        <p className="text-[15px]">{company.name}</p>
        <RoleDetails role={role} />
      </div>
    </div>
  )
}

/** LinkedIn-style grouping: one company header, then roles joined by a timeline under the logo. */
function MultiRole({ company }: { company: Company }) {
  return (
    <div>
      <div className="flex items-center gap-4">
        <LogoTile name={company.name} logo={company.logo} fill={company.logoFill} />
        <div>
          <h3 className="font-semibold">{company.name}</h3>
          <p className="text-sm text-ink-3 tabular-nums">{formatDuration(spanOf(company.roles))}</p>
        </div>
      </div>
      <ol className="mt-4">
        {company.roles.map((role, i) => (
          <li key={`${role.title}-${role.start}`} className="grid grid-cols-[3rem_1fr] gap-x-4 pb-5 last:pb-0">
            <div className="relative" aria-hidden>
              <span className="absolute top-[7px] left-1/2 z-[1] size-2 -translate-x-1/2 rounded-full bg-ink-3" />
              {i < company.roles.length - 1 && (
                <span className="absolute top-[11px] -bottom-[11px] left-1/2 w-px -translate-x-1/2 bg-rule" />
              )}
            </div>
            <div className="min-w-0">
              <h4 className="font-semibold">{role.title}</h4>
              <RoleDetails role={role} />
            </div>
          </li>
        ))}
      </ol>
    </div>
  )
}

export default function Experience({ companies }: { companies: Company[] }) {
  return (
    <ul className="divide-y divide-rule">
      {companies.map((company) => (
        <li key={company.name} className="py-7 first:pt-0 last:pb-0">
          {company.roles.length > 1 ? <MultiRole company={company} /> : <SingleRole company={company} />}
        </li>
      ))}
    </ul>
  )
}
