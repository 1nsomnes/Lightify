import { useEffect, useState } from 'react'

export interface NavItem {
  id: string
  label: string
}

/** The id of the last section whose top has scrolled under the navbar. */
function useActiveSection(ids: string[]) {
  const [active, setActive] = useState<string | null>(null)

  useEffect(() => {
    let frame = 0
    const update = () => {
      frame = 0
      const atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
      if (atBottom) {
        setActive(ids[ids.length - 1])
        return
      }
      let current: string | null = null
      for (const id of ids) {
        const el = document.getElementById(id)
        if (el && el.getBoundingClientRect().top <= 120) current = id
      }
      setActive(current)
    }
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(update)
    }
    update()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [ids])

  return active
}

export default function Navbar({ name, items }: { name: string; items: NavItem[] }) {
  const [ids] = useState(() => items.map((item) => item.id))
  const active = useActiveSection(ids)

  return (
    <header className="fixed inset-x-0 top-0 z-10 border-b border-rule bg-paper">
      <nav
        aria-label="Sections"
        className="mx-auto flex h-14 max-w-5xl items-stretch justify-between px-4 sm:px-6"
      >
        <a href="#top" className="flex items-center gap-2.5 text-[15px] font-semibold">
          <svg viewBox="12 12 76 76" aria-hidden className="size-[18px]">
            <path fill="currentColor" d="M88 12H32L12 32V68L32 88H88V69H38L32 63V37L38 31H88Z" />
          </svg>
          <span className="max-sm:sr-only">{name}</span>
        </a>
        <ul className="flex items-stretch gap-4 sm:gap-7">
          {items.map((item) => {
            const isActive = active === item.id
            return (
              <li key={item.id} className="flex">
                <a
                  href={`#${item.id}`}
                  aria-current={isActive ? 'location' : undefined}
                  className={`relative flex items-center text-sm transition-colors after:absolute after:inset-x-0 after:-bottom-px after:h-0.5 after:transition-colors ${
                    isActive ? 'text-ink after:bg-ink' : 'text-ink-3 after:bg-transparent hover:text-ink'
                  }`}
                >
                  {item.label}
                </a>
              </li>
            )
          })}
        </ul>
      </nav>
    </header>
  )
}
