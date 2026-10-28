import type { ReactNode } from 'react'

interface SectionProps {
  id: string
  title: string
  children: ReactNode
}

/** Resume row: the heading sits in the left gutter on wide screens and stays pinned while you scroll. */
export default function Section({ id, title, children }: SectionProps) {
  return (
    <section
      id={id}
      aria-labelledby={`${id}-title`}
      className="grid gap-6 border-t border-rule py-12 md:grid-cols-[9rem_1fr] md:gap-10 md:py-14"
    >
      <h2 id={`${id}-title`} className="self-start text-[15px] font-semibold md:sticky md:top-24">
        {title}
      </h2>
      <div className="min-w-0">{children}</div>
    </section>
  )
}
