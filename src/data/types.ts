/** Months are written as "YYYY-MM". An omitted `end` means the role is ongoing. */
export type YearMonth = `${number}-${number}`

export interface Profile {
  name: string
  title: string
  location: string
  summary: string
  /** File name inside brand_assets/ */
  photo: string
}

export interface Role {
  title: string
  start: YearMonth
  end?: YearMonth
  location?: string
  description?: string
}

export interface Company {
  name: string
  /** File name inside brand_assets/. Falls back to a monogram tile when missing. */
  logo?: string
  /** Set for square, full-bleed logos that should fill the tile edge to edge. */
  logoFill?: boolean
  /** Most recent role first. */
  roles: Role[]
}

export interface School {
  name: string
  degree: string
  location: string
  end: YearMonth
  expected?: boolean
  logo?: string
  logoFill?: boolean
}

export interface Project {
  title: string
  description: string
  /** Path under public/, e.g. "/projects/flow.png". A placeholder is shown if it fails to load. */
  image?: string
  link?: string
  tags: string[]
}

export interface Paper {
  title: string
  authors: string[]
  venue: string
  year: number
  url?: string
}

export type ContactKind = 'email' | 'x' | 'linkedin'

export interface ContactLink {
  kind: ContactKind
  label: string
  /** Text shown for the link. Not needed for email, which shows the decoded address. */
  handle?: string
  url?: string
  /**
   * Base64-encoded address for email links, so it never appears in plain text in the
   * source or bundle. It's decoded in the browser into the visible text and mailto: link.
   * Generate with: printf '%s' 'you@example.com' | base64
   */
  encodedEmail?: string
}
