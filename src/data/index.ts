import type { Company, ContactLink, Paper, Profile, Project, School } from './types'
import profileJson from './profile.json'
import experienceJson from './experience.json'
import educationJson from './education.json'
import projectsJson from './projects.json'
import papersJson from './papers.json'
import contactJson from './contact.json'

// JSON imports widen literal types (e.g. "2026-05" becomes string), so cast once here
// and let the interfaces in ./types document the expected shape.
export const profile = profileJson as Profile
export const experience = experienceJson as Company[]
export const education = educationJson as School[]
export const projects = projectsJson as Project[]
export const papers = papersJson as Paper[]
export const contact = contactJson as ContactLink[]
