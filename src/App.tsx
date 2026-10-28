import { contact, education, experience, papers, profile, projects } from './data'
import Contact from './components/Contact'
import Education from './components/Education'
import Experience from './components/Experience'
import Header from './components/Header'
import Navbar from './components/Navbar'
import Papers from './components/Papers'
import Projects from './components/Projects'
import Section from './components/Section'

const NAV = [
  { id: 'experience', label: 'Experience' },
  { id: 'projects', label: 'Projects' },
  { id: 'papers', label: 'Papers' },
  { id: 'contact', label: 'Contact' },
]

export default function App() {
  return (
    <>
      <Navbar name={profile.name} items={NAV} />
      <main className="mx-auto max-w-5xl px-4 sm:px-6">
        <Header profile={profile} />
        <Section id="experience" title="Experience">
          <Experience companies={experience} />
        </Section>
        <Section id="education" title="Education">
          <Education schools={education} />
        </Section>
        <Section id="projects" title="Projects">
          <Projects projects={projects} />
        </Section>
        <Section id="papers" title="Papers">
          <Papers papers={papers} author={profile.name} />
        </Section>
        <Section id="contact" title="Contact">
          <Contact links={contact} />
        </Section>
      </main>
      <footer className="mx-auto max-w-5xl px-4 sm:px-6">
        <p className="border-t border-rule py-8 text-sm text-ink-3">
          © {new Date().getFullYear()} {profile.name}
        </p>
      </footer>
    </>
  )
}
