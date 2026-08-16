# Formation build-up, entrance swoops, idle formation sway, and the
# dive-bomb attack AI. Every enemy is a plain Hash living in
# args.state.enemies so it survives hot-reload.
module Enemies
  # `w`/`h` are on-screen sizes chosen to roughly match each
  # generated sprite's pixel-grid aspect ratio (see sprite_gen.rb).
  STATS = {
    boss:      { w: 44, h: 44, hp: 2, score: 150, angle: 180 },
    butterfly: { w: 40, h: 30, hp: 1, score: 80,  angle: 180 },
    bee:       { w: 34, h: 29, hp: 1, score: 50,  angle: 0   },
  }

  def self.kind_for_row(row)
    return :boss if row < 2
    return :butterfly if row < 4
    :bee
  end

  # Builds a fresh 8x5 formation and sends every enemy in from off
  # screen on its own staggered entrance curve.
  def self.build_wave(args)
    wave = args.state.wave
    enemies = []

    C::ROWS.times do |row|
      kind = kind_for_row(row)
      stats = STATS[kind]
      variants = args.state.enemy_sprite_variants[kind]

      C::COLS.times do |col|
        slot_x = C::FORMATION_LEFT_X + col * C::COL_SPACING
        slot_y = C::FORMATION_TOP_Y - row * C::ROW_SPACING
        side = col.even? ? -1 : 1
        entry_x0 = side < 0 ? -80 : C::SCREEN_W + 80
        entry_y0 = C::SCREEN_H + 80 + rand(120)
        delay = row * 10 + col * 4 + rand(10)

        enemies << {
          kind: kind, col: col, row: row,
          sprite: variants.sample, # picked once at spawn, kept for the enemy's whole life
          slot_x: slot_x, slot_y: slot_y,
          x: entry_x0, y: entry_y0,
          w: stats[:w], h: stats[:h],
          hp: stats[:hp], score: stats[:score],
          state: :entering,
          entry_started_at: Kernel.tick_count + delay,
          entry_duration: 80 + rand(30),
          entry_p0: { x: entry_x0, y: entry_y0 },
          entry_p1: { x: side < 0 ? slot_x - 260 : slot_x + 260, y: slot_y + 260 + rand(80) },
          entry_p2: { x: slot_x, y: slot_y },
          dive_fired: false,
          hit_flash_until: 0,
        }
      end
    end

    args.state.enemies = enemies
    args.state.next_dive_at = Kernel.tick_count + 120 - [wave * 4, 60].min
  end

  def self.tick(args)
    formation_offset_x = Math.sin(Kernel.tick_count * 0.015) * 40
    formation_bob = Math.sin(Kernel.tick_count * 0.02) * 4

    args.state.enemies.each do |e|
      case e[:state]
      when :entering then tick_entering(args, e)
      when :formation
        e[:x] = e[:slot_x] + formation_offset_x
        e[:y] = e[:slot_y] + formation_bob
      when :diving then tick_diving(args, e)
      end
    end

    maybe_trigger_dive(args)
  end

  def self.tick_entering(args, e)
    return if Kernel.tick_count < e[:entry_started_at]

    t = ((Kernel.tick_count - e[:entry_started_at]).to_f / e[:entry_duration]).clamp(0, 1)
    pt = Curve.quad(e[:entry_p0], e[:entry_p1], e[:entry_p2], Curve.smoothstep(t))
    e[:x] = pt[:x]
    e[:y] = pt[:y]
    e[:state] = :formation if t >= 1
  end

  def self.tick_diving(args, e)
    t = ((Kernel.tick_count - e[:dive_started_at]).to_f / e[:dive_duration]).clamp(0, 1)
    pt = Curve.cubic(e[:dive_p0], e[:dive_p1], e[:dive_p2], e[:dive_p3], t)
    e[:x] = pt[:x]
    e[:y] = pt[:y]

    if !e[:dive_fired] && t > 0.35
      Bullets.fire_enemy(args, e)
      e[:dive_fired] = true
    end

    start_re_entry(args, e) if t >= 1
  end

  # Diving enemy reached the bottom of its run -- loop it back in from
  # off screen to rejoin its original formation slot. Keeps enemy
  # count constant without needing "fly back up" homing logic.
  def self.start_re_entry(args, e)
    side = rand(2).zero? ? -1 : 1
    entry_x0 = side < 0 ? -80 : C::SCREEN_W + 80
    entry_y0 = C::SCREEN_H + 80

    e[:entry_p0] = { x: entry_x0, y: entry_y0 }
    e[:entry_p1] = { x: (e[:slot_x] + entry_x0) / 2.0, y: e[:slot_y] + 260 }
    e[:entry_p2] = { x: e[:slot_x], y: e[:slot_y] }
    e[:entry_started_at] = Kernel.tick_count
    e[:entry_duration] = 70
    e[:x] = entry_x0
    e[:y] = entry_y0
    e[:state] = :entering
  end

  def self.maybe_trigger_dive(args)
    return if Kernel.tick_count < args.state.next_dive_at

    candidates = args.state.enemies.select { |e| e[:state] == :formation }
    return if candidates.empty?

    squad_size = [1 + args.state.wave / 3, 3, candidates.size].min
    # NOTE: DragonRuby's Array#sample doesn't take a count argument,
    # so shuffle-then-take stands in for `candidates.sample(squad_size)`.
    squad = candidates.shuffle.first(squad_size)
    squad.each { |e| start_dive(args, e) }
    Audio.play(args, 'sounds/dive_alert.wav')

    cooldown = [140 - args.state.wave * 6, 55].max
    args.state.next_dive_at = Kernel.tick_count + cooldown + rand(40)
  end

  def self.start_dive(args, e)
    player = args.state.player
    target_x = (player[:alive] ? player[:x] : e[:slot_x]).clamp(80, C::SCREEN_W - 80)
    swoop_dir = e[:x] < 640 ? -1 : 1

    e[:dive_p0] = { x: e[:x], y: e[:y] }
    e[:dive_p1] = { x: e[:x] + swoop_dir * 160, y: e[:y] - 220 }
    e[:dive_p2] = { x: target_x - swoop_dir * 120, y: 260 }
    e[:dive_p3] = { x: (target_x + rand(120) - 60).clamp(-40, C::SCREEN_W + 40), y: -80 }
    e[:dive_started_at] = Kernel.tick_count
    e[:dive_duration] = 150 - [args.state.wave * 3, 60].min
    e[:dive_fired] = false
    e[:state] = :diving
  end

  def self.render(args)
    args.state.enemies.each do |e|
      stats = STATS[e[:kind]]
      pulse = Kernel.tick_count < e[:hit_flash_until] ? 1.3 : 1.0

      args.outputs.sprites << {
        x: e[:x], y: e[:y], w: e[:w] * pulse, h: e[:h] * pulse,
        anchor_x: 0.5, anchor_y: 0.5,
        path: e[:sprite], angle: stats[:angle],
      }
    end
  end
end
