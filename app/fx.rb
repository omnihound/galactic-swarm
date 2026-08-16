# Visual-only effects: explosion animations and floating "+score"
# popups. Deliberately has no gameplay side effects.
module FX
  def self.explosion(args, x, y, scale: 1.0)
    args.state.explosions << { x: x, y: y, started_at: Kernel.tick_count, scale: scale }
  end

  def self.popup_score(args, x, y, amount)
    args.state.score_popups << { x: x, y: y, text: "+#{amount}", started_at: Kernel.tick_count }
  end

  def self.tick(args)
    args.state.explosions.reject! { |ex| Kernel.tick_count - ex[:started_at] > C::EXPLOSION_DURATION }
    args.state.score_popups.reject! { |p| Kernel.tick_count - p[:started_at] > 40 }
  end

  def self.render(args)
    args.state.explosions.each do |ex|
      age = Kernel.tick_count - ex[:started_at]
      frame = (age / (C::EXPLOSION_DURATION.to_f / C::EXPLOSION_FRAME_COUNT)).to_i.clamp(0, C::EXPLOSION_FRAME_COUNT - 1)
      size = 32 * ex[:scale]
      args.outputs.sprites << {
        x: ex[:x], y: ex[:y], w: size, h: size,
        anchor_x: 0.5, anchor_y: 0.5,
        path: 'sprites/explosion-sheet.png',
        source_x: frame * C::EXPLOSION_FRAME_W, source_y: 0,
        source_w: C::EXPLOSION_FRAME_W, source_h: C::EXPLOSION_FRAME_H,
      }
    end

    args.state.score_popups.each do |p|
      age = Kernel.tick_count - p[:started_at]
      args.outputs.labels << {
        x: p[:x], y: p[:y] + age * 0.6, text: p[:text], size_px: 16,
        anchor_x: 0.5, r: 255, g: 255, b: 140, a: (255 - age * 7).clamp(0, 255),
      }
    end
  end
end
