// Everything in brand_assets/ is bundled, so data files can refer to a logo by file name alone.
const files = import.meta.glob<string>('/brand_assets/*.{png,jpg,jpeg,svg,webp}', {
  eager: true,
  query: '?url',
  import: 'default',
})

export function brandAsset(name?: string) {
  return name ? files[`/brand_assets/${name}`] : undefined
}
