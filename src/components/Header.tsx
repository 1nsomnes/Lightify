import type { Profile } from '../data/types'
import { brandAsset } from '../lib/assets'

export default function Header({ profile }: { profile: Profile }) {
  return (
    <div id="top" className="grid gap-6 pt-28 pb-12 md:grid-cols-[9rem_1fr] md:gap-10 md:pt-36 md:pb-14">
      <img
        src={brandAsset(profile.photo)}
        alt={profile.name}
        className="chamfer size-24 object-cover [--cut:18%] md:size-28"
      />
      <div className="self-end">
        <h1 className="text-[2.5rem] leading-[1.05] font-semibold tracking-[-0.025em] md:text-[3.25rem]">
          {profile.name}
        </h1>
        <p className="mt-2 text-lg text-ink-2">
          {profile.title}, {profile.location}
        </p>
        <p className="mt-5 max-w-[60ch] text-[15px] leading-relaxed text-ink-2">{profile.summary}</p>
      </div>
    </div>
  )
}
