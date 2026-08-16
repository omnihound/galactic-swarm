module Player
  def self.tick(args)
    p = args.state.player

    unless p[:alive]
      if p[:respawn_at] && Kernel.tick_count >= p[:respawn_at]
        p[:alive] = true
        p[:x] = 640
        p[:invuln_until] = Kernel.tick_count + C::PLAYER_INVULN_TICKS
        p[:respawn_at] = nil
      end
      return
    end

    # Touch: the ship follows the finger's x position directly (with a
    # little smoothing) instead of accelerating like keyboard/analog
    # input. A finger down also counts as "firing" -- mobile players
    # get auto-fire for free, no on-screen button needed.
    touch = args.inputs.finger_one
    if touch
      p[:x] = p[:x].lerp(touch.x, 0.4)
    else
      dx = args.inputs.left_right_perc_with_wasd
      p[:x] += dx * C::PLAYER_SPEED
    end
    p[:x] = p[:x].clamp(p[:w] / 2 + 10, C::SCREEN_W - p[:w] / 2 - 10)

    p[:cooldown] -= 1 if p[:cooldown] > 0

    firing = touch ||
             args.inputs.keyboard.key_held.space ||
             args.inputs.keyboard.key_held.z ||
             (args.inputs.controller_one && args.inputs.controller_one.key_held.a)

    if firing && p[:cooldown] <= 0
      Bullets.fire_player(args)
      p[:cooldown] = C::PLAYER_FIRE_COOLDOWN
    end
  end

  def self.hit!(args)
    p = args.state.player
    return unless p[:alive]

    p[:alive] = false
    p[:lives] -= 1
    FX.explosion(args, p[:x], p[:y], scale: 1.8)
    Audio.play(args, 'sounds/player_explosion.wav')

    p[:respawn_at] = Kernel.tick_count + C::PLAYER_RESPAWN_DELAY if p[:lives] > 0
  end

  def self.render(args)
    p = args.state.player
    return unless p[:alive]

    blinking = Kernel.tick_count < p[:invuln_until]
    return if blinking && Kernel.tick_count.idiv(4).even?

    # Thruster flicker beneath the ship for a little extra juice.
    flame_h = 8 + rand(6)
    args.outputs.sprites << {
      x: p[:x] - 4, y: p[:y] - p[:h] / 2 - flame_h,
      w: 8, h: flame_h, path: :solid,
      r: 255, g: 140 + rand(80), b: 40, a: 210,
    }

    args.outputs.sprites << {
      x: p[:x], y: p[:y], w: p[:w], h: p[:h],
      anchor_x: 0.5, anchor_y: 0.5,
      path: args.state.player_sprite,
    }
  end
end
