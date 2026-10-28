import { useState } from 'react'
import type { Project } from '../data/types'

// Quiet tints for projects that don't have a screenshot yet; picked per title so they stay stable.
const TINTS = ['#e7edf5', '#ecefe5', '#f2eaea', '#ebeaf4', '#e6f0ee', '#f1eee6']

function tintFor(title: string) {
  let hash = 0
  for (const char of title) hash = (hash * 31 + char.charCodeAt(0)) >>> 0
  return TINTS[hash % TINTS.length]
}

function Thumbnail({ project }: { project: Project }) {
  const [failed, setFailed] = useState(false)

  if (project.image && !failed) {
    return (
      <img
        src={project.image}
        alt=""
        loading="lazy"
        onError={() => setFailed(true)}
        className="aspect-[16/10] w-full bg-surface object-cover object-top"
      />
    )
  }

  return (
    <div
      aria-hidden
      className="flex aspect-[16/10] w-full items-end p-4"
      style={{
        backgroundColor: tintFor(project.title),
        backgroundImage: 'radial-gradient(rgb(21 23 28 / 0.14) 1px, transparent 1px)',
        backgroundSize: '14px 14px',
      }}
    >
      <span className="text-[2.5rem] leading-none font-semibold tracking-[-0.03em] text-ink/25">
        {project.title
          .split(/\s+/)
          .map((w) => w[0])
          .join('')
          .slice(0, 2)}
      </span>
    </div>
  )
}

function ProjectCard({ project }: { project: Project }) {
  const body = (
    // Two stacked chamfered layers draw a 1px border that follows the cut corners.
    <div className="chamfer h-full bg-rule p-px transition-colors [--cut:14px] group-hover:bg-ink-3">
      <div className="chamfer flex h-full flex-col bg-paper [--cut:13.6px]">
        <Thumbnail project={project} />
        <div className="flex flex-1 flex-col border-t border-rule p-4">
          <div className="flex items-start justify-between gap-3">
            <h3 className="font-semibold">{project.title}</h3>
            {project.link && (
              <svg
                viewBox="0 0 16 16"
                aria-hidden
                className="mt-1 size-3.5 shrink-0 text-ink-3 transition-colors group-hover:text-ink"
              >
                <path d="M5 3h8v8M13 3 3 13" fill="none" stroke="currentColor" strokeWidth="1.5" />
              </svg>
            )}
          </div>
          <p className="mt-1 text-sm leading-relaxed text-ink-2">{project.description}</p>
          <ul className="mt-auto flex flex-wrap gap-1.5 pt-4" aria-label="Built with">
            {project.tags.map((tag) => (
              <li key={tag} className="rounded-sm bg-surface px-1.5 py-0.5 text-xs text-ink-2">
                {tag}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )

  return project.link ? (
    <a href={project.link} target="_blank" rel="noopener noreferrer" className="group block h-full">
      {body}
    </a>
  ) : (
    <div className="h-full">{body}</div>
  )
}

export default function Projects({ projects }: { projects: Project[] }) {
  return (
    <ul className="grid gap-4 sm:grid-cols-2">
      {projects.map((project) => (
        <li key={project.title}>
          <ProjectCard project={project} />
        </li>
      ))}
    </ul>
  )
}
