import type { ContactKind, ContactLink } from '../data/types'

const ICONS: Record<ContactKind, string> = {
  email: 'M2 4h20v16H2zM2 4l10 8 10-8',
  x: 'M4 4l16 16M20 4 4 20',
  linkedin: 'M3 3h18v18H3zM8 10v7M8 7v.01M12 17v-7M12 13a3 3 0 0 1 6 0v4',
}

export default function Contact({ links }: { links: ContactLink[] }) {
  return (
    <ul className="divide-y divide-rule border-y border-rule">
      {links.map((link) => {
        const email = link.encodedEmail ? atob(link.encodedEmail) : undefined
        return (
          <li key={link.kind}>
            <a
              href={email ? `mailto:${email}` : link.url}
              {...(!email && { target: '_blank', rel: 'noopener noreferrer' })}
              className="group grid grid-cols-[1.25rem_6rem_1fr] items-center gap-3 py-3.5"
            >
              <svg viewBox="0 0 24 24" aria-hidden className="size-4 text-ink-3 transition-colors group-hover:text-ink">
        <path
          d={ICONS[link.kind]}
          fill="none"
          stroke="currentColor"
          strokeWidth="1.75"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
              <span className="text-sm text-ink-3">{link.label}</span>
              <span className="truncate text-[15px] underline decoration-transparent underline-offset-4 transition-colors group-hover:decoration-ink">
                {email ?? link.handle}
              </span>
            </a>
          </li>
        )
      })}
    </ul>
  )
}
