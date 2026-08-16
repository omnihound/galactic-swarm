# Non-gameplay screens: title, in-game HUD + wave banner, game over.
module Scenes
  def self.render_title(args)
    args.outputs.labels << {
      x: 640, y: 540, text: 'GALACTIC SWARM', size_px: 64,
      anchor_x: 0.5, r: 255, g: 220, b: 60,
    }
    args.outputs.labels << {
      x: 640, y: 495, text: 'a Galaga-inspired arcade shooter', size_px: 20,
      anchor_x: 0.5, r: 190, g: 190, b: 220,
    }

    args.outputs.sprites << {
      x: 640, y: 330, w: 36, h: 46, anchor_x: 0.5, anchor_y: 0.5,
      path: args.state.player_sprite,
    }

    if Kernel.tick_count.idiv(30).even?
      args.outputs.labels << {
        x: 640, y: 250, text: 'PRESS SPACE TO START', size_px: 26,
        anchor_x: 0.5, r: 255, g: 255, b: 255,
      }
    end

    args.outputs.labels << {
      x: 640, y: 170, text: 'ARROWS / WASD move    SPACE / Z shoot', size_px: 18,
      anchor_x: 0.5, r: 170, g: 170, b: 190,
    }

    if args.state.high_score > 0
      args.outputs.labels << {
        x: 640, y: 130, text: "HIGH SCORE #{args.state.high_score}", size_px: 20,
        anchor_x: 0.5, r: 200, g: 200, b: 255,
      }
    end
  end

  def self.render_hud(args)
    args.outputs.labels << {
      x: 20, y: 700, text: "SCORE #{args.state.score}", size_px: 22, r: 255, g: 255, b: 255,
    }
    args.outputs.labels << {
      x: 20, y: 672, text: "WAVE #{args.state.wave}", size_px: 18, r: 180, g: 180, b: 210,
    }

    args.state.player[:lives].times do |i|
      args.outputs.sprites << {
        x: 1260 - i * 28, y: 700, w: 17, h: 22,
        anchor_x: 1, anchor_y: 1, path: args.state.player_sprite,
      }
    end

    return unless args.state.wave_banner_until && Kernel.tick_count < args.state.wave_banner_until

    args.outputs.labels << {
      x: 640, y: 400, text: args.state.wave_banner_text, size_px: 42,
      anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255,
    }
  end

  def self.render_game_over(args)
    args.outputs.sprites << { x: 0, y: 0, w: C::SCREEN_W, h: C::SCREEN_H, path: :solid, r: 0, g: 0, b: 0, a: 130 }

    args.outputs.labels << {
      x: 640, y: 420, text: 'GAME OVER', size_px: 56, anchor_x: 0.5, r: 255, g: 80, b: 80,
    }
    args.outputs.labels << {
      x: 640, y: 360, text: "SCORE #{args.state.score}   HIGH SCORE #{args.state.high_score}",
      size_px: 22, anchor_x: 0.5, r: 255, g: 255, b: 255,
    }

    if Kernel.tick_count.idiv(30).even?
      args.outputs.labels << {
        x: 640, y: 290, text: 'PRESS SPACE TO RESTART', size_px: 20, anchor_x: 0.5,
        r: 255, g: 255, b: 255,
      }
    end
  end
end
