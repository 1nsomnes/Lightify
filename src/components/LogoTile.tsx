import { brandAsset } from '../lib/assets'

interface LogoTileProps {
  name: string
  logo?: string
  fill?: boolean
}

function monogram(name: string) {
  return name
    .split(/\s+/)
    .map((word) => word[0])
    .join('')
    .slice(0, 3)
    .toUpperCase()
}

export default function LogoTile({ name, logo, fill }: LogoTileProps) {
  const src = brandAsset(logo)

  return (
    <div className="lifted size-12 shrink-0">
      <div className="chamfer flex size-full items-center justify-center bg-paper">
        {src ? (
          <img
            src={src}
            alt={`${name} logo`}
            className={fill ? 'size-full object-cover' : 'size-full object-contain p-2'}
          />
        ) : (
          <span aria-hidden className="text-[13px] font-semibold tracking-tight text-ink-2">
            {monogram(name)}
          </span>
        )}
      </div>
    </div>
  )
}
