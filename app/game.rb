# Top-level scene dispatch and game/wave lifecycle. This is the only
# module that knows about scene transitions -- everything else just
# does its one job when told to.
module Game
  NEXT_WAVE_DELAY = 75
  EXTRA_LIFE_SCORE_STEP = 15000

  def self.tick(args)
    args.outputs.background_color = [6, 6, 18]

    Starfield.setup(args)
    Starfield.tick(args)
    SpriteGen.setup(args)

    args.state.scene ||= :title
    args.state.high_score ||= HighScore.load(args)

    case args.state.scene
    when :title then tick_title(args)
    when :playing then tick_playing(args)
    when :game_over then tick_game_over(args)
    end
  end

  def self.tick_title(args)
    Starfield.render(args)
    Scenes.render_title(args)
    start_new_game(args) if start_pressed?(args)
  end

  def self.tick_playing(args)
    Player.tick(args)
    Enemies.tick(args)
    Bullets.tick(args)
    Collisions.tick(args)
    FX.tick(args)
    check_extra_life(args)

    Starfield.render(args)
    Enemies.render(args)
    Bullets.render(args)
    Player.render(args)
    FX.render(args)
    Scenes.render_hud(args)

    advance_wave_if_clear(args)
    end_game_if_over(args)
  end

  def self.tick_game_over(args)
    Starfield.render(args)
    Scenes.render_game_over(args)
    start_new_game(args) if start_pressed?(args)
  end

  def self.start_pressed?(args)
    args.inputs.keyboard.key_down.space ||
      args.inputs.keyboard.key_down.enter ||
      args.inputs.keyboard.key_down.z ||
      (args.inputs.controller_one && args.inputs.controller_one.key_down.a)
  end

  def self.start_new_game(args)
    args.state.score = 0
    args.state.wave = 1
    args.state.next_extra_life_score = EXTRA_LIFE_SCORE_STEP
    args.state.player = {
      x: 640, y: C::PLAYER_Y, w: C::PLAYER_W, h: C::PLAYER_H,
      lives: C::PLAYER_LIVES_START, alive: true, cooldown: 0,
      invuln_until: Kernel.tick_count + C::PLAYER_INVULN_TICKS,
      respawn_at: nil,
    }
    args.state.player_bullets = []
    args.state.enemy_bullets = []
    args.state.explosions = []
    args.state.score_popups = []
    args.state.wave_transition_at = nil
    args.state.game_over_at = nil

    Enemies.build_wave(args)
    show_wave_banner(args, 'WAVE 1')
    args.state.scene = :playing
  end

  def self.show_wave_banner(args, text)
    args.state.wave_banner_text = text
    args.state.wave_banner_until = Kernel.tick_count + 100
  end

  def self.advance_wave_if_clear(args)
    if args.state.wave_transition_at
      if Kernel.tick_count >= args.state.wave_transition_at
        args.state.wave += 1
        args.state.wave_transition_at = nil
        Enemies.build_wave(args)
        show_wave_banner(args, "WAVE #{args.state.wave}")
      end
      return
    end

    return unless args.state.enemies.empty?

    args.state.wave_transition_at = Kernel.tick_count + NEXT_WAVE_DELAY
    show_wave_banner(args, 'WAVE CLEAR!')
    Audio.play(args, 'sounds/wave_clear.wav')
  end

  def self.end_game_if_over(args)
    p = args.state.player
    if p[:lives] <= 0 && !p[:alive] && !args.state.game_over_at
      args.state.game_over_at = Kernel.tick_count + 90
    end

    return unless args.state.game_over_at
    return if Kernel.tick_count < args.state.game_over_at

    args.state.high_score = [args.state.score, args.state.high_score].max
    HighScore.save(args) if args.state.score >= args.state.high_score
    args.state.scene = :game_over
  end

  def self.check_extra_life(args)
    return unless args.state.score >= args.state.next_extra_life_score
    args.state.player[:lives] += 1
    args.state.next_extra_life_score += EXTRA_LIFE_SCORE_STEP
    Audio.play(args, 'sounds/extra_life.wav')
  end
end
