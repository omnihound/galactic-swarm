# Procedurally generates the player ship and enemy sprites at boot
# time as small mirrored pixel-art textures (DragonRuby pixel
# arrays) -- no image files needed. Each enemy kind gets a handful
# of random variants baked once and cached as GPU textures; every
# spawned enemy picks one variant at spawn time and keeps it for its
# whole lifetime (never re-rolled per frame).
#
# The look: a row-by-row silhouette ("how wide is this row, and how
# likely is each cell in it to be filled") is mirrored left/right
# around a true center column, then edge pixels (any filled pixel
# touching an empty one) get a darker outline shade so the shape
# reads clearly at small sizes. A few "accent" pixels (cockpit, eyes,
# cannons, engine glow) are stamped on top for character.
#
# Variety is intentionally layered, not unlimited: the row silhouette
# ENVELOPE (half_width/density per row) is fixed per kind, so a boss
# always reads as a boss. Only the fill noise inside that envelope,
# the body/edge color (jittered within a family, not re-hued), and
# the accent color+position (jittered slightly) vary per variant.
# That's what keeps 7 random-looking siblings per kind from ever
# being mistaken for a different kind mid-dodge.
module SpriteGen
  VARIANTS_PER_KIND = 7
  COLOR_JITTER = 28   # max +/- per RGB channel on the base body color
  ACCENT_JITTER = 22  # max +/- per RGB channel on accent colors
  ACCENT_DRIFT = 1    # max +/- cells an accent can drift from its anchor

  def self.setup(args)
    return if args.state.sprites_ready
    args.state.sprites_ready = true

    args.state.player_sprite = build_player(args, :spr_player)

    bee_variants = []
    VARIANTS_PER_KIND.times { |i| bee_variants << build_bee(args, :"spr_bee_#{i}") }

    butterfly_variants = []
    VARIANTS_PER_KIND.times { |i| butterfly_variants << build_butterfly(args, :"spr_butterfly_#{i}") }

    boss_variants = []
    VARIANTS_PER_KIND.times { |i| boss_variants << build_boss(args, :"spr_boss_#{i}") }

    args.state.enemy_sprite_variants = {
      bee: bee_variants,
      butterfly: butterfly_variants,
      boss: boss_variants,
    }
  end

  # -- color -------------------------------------------------------------

  # Pixel arrays use ABGR hex (alpha in the top byte, red in the
  # bottom byte) -- see docs/api/pixel_arrays.md.
  def self.abgr(r, g, b, a = 255)
    (a << 24) | (b << 16) | (g << 8) | r
  end

  def self.jitter_channel(v, amount)
    return v if amount <= 0
    (v + rand(amount * 2 + 1) - amount).clamp(0, 255)
  end

  # Nudges a base color within a family -- variants of the same kind
  # look like siblings (different shades), never identical, never a
  # different hue entirely.
  def self.jitter_color(r, g, b, amount)
    [jitter_channel(r, amount), jitter_channel(g, amount), jitter_channel(b, amount)]
  end

  def self.darken(r, g, b, factor)
    [(r * factor).to_i, (g * factor).to_i, (b * factor).to_i]
  end

  # accent_specs: array of [row, col, r, g, b] anchors. Returns
  # [row, col, abgr_color] triples with both position and shade
  # jittered per variant, ready for `paint`.
  def self.jitter_accents(accent_specs, w, h)
    accent_specs.map do |row, col, r, g, b|
      jr, jg, jb = jitter_color(r, g, b, ACCENT_JITTER)
      jrow = (row + rand(ACCENT_DRIFT * 2 + 1) - ACCENT_DRIFT).clamp(0, h - 1)
      jcol = (col + rand(ACCENT_DRIFT * 2 + 1) - ACCENT_DRIFT).clamp(0, w - 1)
      [jrow, jcol, abgr(jr, jg, jb)]
    end
  end

  # -- mask building -------------------------------------------------------

  # row_specs: one entry per row, top to bottom. `half_width` counts
  # columns outward from center (1 == center column only). Each
  # eligible cell is independently filled with probability `density`;
  # the center column itself is always filled when `spine` is true
  # (default) so shapes don't fall apart into disconnected speckles.
  def self.build_mask(w, h, row_specs)
    center = w / 2
    mask = Array.new(w * h, false)

    h.times do |row|
      spec = row_specs[row]
      next unless spec
      half_width = spec[:half_width] || 0
      density = spec[:density] || 0
      spine = spec[:spine]
      spine = true if spine.nil?

      half_width.times do |i|
        filled = (i == 0 && spine) || rand < density
        next unless filled
        col_r = center + i
        col_l = center - i
        mask[row * w + col_r] = true if col_r >= 0 && col_r < w
        mask[row * w + col_l] = true if col_l >= 0 && col_l < w
      end
    end

    mask
  end

  def self.mask_filled?(mask, w, h, row, col)
    return false if row < 0 || row >= h || col < 0 || col >= w
    mask[row * w + col]
  end

  # accents: array of [row, col, color] triples stamped on top of the
  # shaded mask, regardless of whether the mask filled that cell.
  def self.paint(args, name, w, h, mask, base_color, edge_color, accents)
    pa = args.pixel_array(name)
    pa.w = w
    pa.h = h
    pa.pixels.fill(0, 0, w * h)

    h.times do |row|
      w.times do |col|
        idx = row * w + col
        next unless mask[idx]
        edge = !mask_filled?(mask, w, h, row - 1, col) ||
               !mask_filled?(mask, w, h, row + 1, col) ||
               !mask_filled?(mask, w, h, row, col - 1) ||
               !mask_filled?(mask, w, h, row, col + 1)
        pa.pixels[idx] = edge ? edge_color : base_color
      end
    end

    accents.each do |row, col, color|
      next if row < 0 || row >= h || col < 0 || col >= w
      pa.pixels[row * w + col] = color
    end

    name
  end

  # -- ship designs ----------------------------------------------------

  PLAYER_W = 11
  PLAYER_H = 14
  PLAYER_ROWS = [
    { half_width: 1, density: 0 },
    { half_width: 1, density: 0 },
    { half_width: 2, density: 0.9 },
    { half_width: 2, density: 1.0 },
    { half_width: 3, density: 0.6 },
    { half_width: 3, density: 0.9 },
    { half_width: 5, density: 0.5 },
    { half_width: 5, density: 0.6 },
    { half_width: 4, density: 0.5 },
    { half_width: 2, density: 1.0 },
    { half_width: 2, density: 1.0 },
    { half_width: 2, density: 0.8 },
    { half_width: 1, density: 1.0 },
    { half_width: 1, density: 1.0 },
  ]

  def self.build_player(args, name)
    center = PLAYER_W / 2
    mask = build_mask(PLAYER_W, PLAYER_H, PLAYER_ROWS)
    body = abgr(70, 150, 255)
    edge = abgr(20, 60, 140)
    accents = [
      [4, center, abgr(210, 255, 255)],   # cockpit glass
      [13, center, abgr(255, 170, 40)],   # engine glow
      [12, center, abgr(255, 190, 90)],
    ]
    paint(args, name, PLAYER_W, PLAYER_H, mask, body, edge, accents)
  end

  BEE_W = 13
  BEE_H = 11
  BEE_ROWS = [
    { half_width: 0, density: 0 },
    { half_width: 1, density: 1.0 },
    { half_width: 2, density: 0.9 },
    { half_width: 3, density: 0.85 },
    { half_width: 4, density: 0.85 },
    { half_width: 4, density: 0.85 },
    { half_width: 3, density: 0.85 },
    { half_width: 2, density: 0.9 },
    { half_width: 2, density: 0.7 },
    { half_width: 1, density: 1.0 },
    { half_width: 1, density: 0.6 },
  ]

  BEE_ACCENTS = [
    [0, BEE_W / 2 - 2, 40, 40, 40],    # antennae
    [0, BEE_W / 2 + 2, 40, 40, 40],
    [2, BEE_W / 2 - 1, 255, 80, 80],   # eyes
    [2, BEE_W / 2 + 1, 255, 80, 80],
  ]

  def self.build_bee(args, name)
    mask = build_mask(BEE_W, BEE_H, BEE_ROWS)
    br, bg, bb = jitter_color(235, 210, 60, COLOR_JITTER)
    dr, dg, db = darken(br, bg, bb, 0.45)
    body = abgr(br, bg, bb)
    edge = abgr(dr, dg, db)
    accents = jitter_accents(BEE_ACCENTS, BEE_W, BEE_H)
    paint(args, name, BEE_W, BEE_H, mask, body, edge, accents)
  end

  BUTTERFLY_W = 15
  BUTTERFLY_H = 11
  BUTTERFLY_ROWS = [
    { half_width: 1, density: 1.0 },
    { half_width: 1, density: 1.0 },
    { half_width: 2, density: 0.9 },
    { half_width: 5, density: 0.35 },
    { half_width: 7, density: 0.35 },
    { half_width: 7, density: 0.35 },
    { half_width: 6, density: 0.35 },
    { half_width: 4, density: 0.4 },
    { half_width: 2, density: 0.8 },
    { half_width: 1, density: 1.0 },
    { half_width: 1, density: 0.7 },
  ]

  BUTTERFLY_ACCENTS = [
    [4, BUTTERFLY_W / 2 - 6, 255, 225, 255], # wing eye-spots
    [4, BUTTERFLY_W / 2 + 6, 255, 225, 255],
  ]

  def self.build_butterfly(args, name)
    mask = build_mask(BUTTERFLY_W, BUTTERFLY_H, BUTTERFLY_ROWS)
    br, bg, bb = jitter_color(190, 110, 230, COLOR_JITTER)
    dr, dg, db = darken(br, bg, bb, 0.45)
    body = abgr(br, bg, bb)
    edge = abgr(dr, dg, db)
    accents = jitter_accents(BUTTERFLY_ACCENTS, BUTTERFLY_W, BUTTERFLY_H)
    paint(args, name, BUTTERFLY_W, BUTTERFLY_H, mask, body, edge, accents)
  end

  BOSS_W = 13
  BOSS_H = 13
  BOSS_ROWS = [
    { half_width: 2, density: 0.9 },
    { half_width: 3, density: 0.95 },
    { half_width: 4, density: 0.95 },
    { half_width: 5, density: 0.9 },
    { half_width: 5, density: 0.9 },
    { half_width: 6, density: 0.85 },
    { half_width: 6, density: 0.85 },
    { half_width: 5, density: 0.9 },
    { half_width: 5, density: 0.9 },
    { half_width: 4, density: 0.9 },
    { half_width: 3, density: 0.9 },
    { half_width: 2, density: 0.9 },
    { half_width: 1, density: 1.0 },
  ]

  BOSS_ACCENTS = [
    [2, BOSS_W / 2,     140, 235, 255], # sensor core
    [2, BOSS_W / 2 - 1, 140, 235, 255],
    [5, BOSS_W / 2 - 6, 255, 220, 80],  # cannon tips
    [5, BOSS_W / 2 + 6, 255, 220, 80],
  ]

  def self.build_boss(args, name)
    mask = build_mask(BOSS_W, BOSS_H, BOSS_ROWS)
    br, bg, bb = jitter_color(230, 60, 60, COLOR_JITTER)
    dr, dg, db = darken(br, bg, bb, 0.45)
    body = abgr(br, bg, bb)
    edge = abgr(dr, dg, db)
    accents = jitter_accents(BOSS_ACCENTS, BOSS_W, BOSS_H)
    paint(args, name, BOSS_W, BOSS_H, mask, body, edge, accents)
  end
end
