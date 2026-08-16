# Owns both bullet arrays (player + enemy): spawning, movement, and
# despawning off-screen. Collision resolution lives in Collisions.
module Bullets
  def self.fire_player(args)
    p = args.state.player
    args.state.player_bullets << {
      x: p[:x], y: p[:y] + p[:h] / 2,
      w: C::PLAYER_BULLET_W, h: C::PLAYER_BULLET_H,
      dx: 0, dy: C::PLAYER_BULLET_SPEED,
    }
    Audio.play(args, 'sounds/shoot.wav')
  end

  # Diving enemies fire aimed shots at wherever the player currently is.
  # Boss-type enemies fire a two-way spread instead of a single shot.
  def self.fire_enemy(args, e)
    player = args.state.player
    angles = e[:kind] == :boss ? [-14, 14] : [0]
    base = player[:alive] ? Geometry.angle_to({ x: e[:x], y: e[:y] }, { x: player[:x], y: player[:y] }) : 270

    angles.each do |offset|
      vec = Geometry.angle_vec2(base + offset)
      args.state.enemy_bullets << {
        x: e[:x], y: e[:y],
        w: C::ENEMY_BULLET_W, h: C::ENEMY_BULLET_H,
        dx: vec[:x] * C::ENEMY_BULLET_SPEED,
        dy: vec[:y] * C::ENEMY_BULLET_SPEED,
      }
    end
  end

  def self.tick(args)
    args.state.player_bullets.each { |b| b[:x] += b[:dx]; b[:y] += b[:dy] }
    args.state.enemy_bullets.each  { |b| b[:x] += b[:dx]; b[:y] += b[:dy] }

    args.state.player_bullets.reject! { |b| b[:y] > C::SCREEN_H + 20 }
    args.state.enemy_bullets.reject! do |b|
      b[:y] < -20 || b[:y] > C::SCREEN_H + 20 || b[:x] < -20 || b[:x] > C::SCREEN_W + 20
    end
  end

  def self.render(args)
    args.state.player_bullets.each do |b|
      args.outputs.sprites << {
        x: b[:x], y: b[:y], w: b[:w], h: b[:h],
        anchor_x: 0.5, anchor_y: 0.5,
        path: 'sprites/bullet.png', r: 130, g: 220, b: 255,
      }
    end

    args.state.enemy_bullets.each do |b|
      args.outputs.sprites << {
        x: b[:x], y: b[:y], w: b[:w], h: b[:h],
        anchor_x: 0.5, anchor_y: 0.5,
        path: 'sprites/enemy_bullet.png',
      }
    end
  end
end
