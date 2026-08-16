# Scrolling starfield background. Runs continuously regardless of
# scene (title, playing, game over) to keep the screen alive.
module Starfield
  def self.setup(args)
    return if args.state.stars
    args.state.stars = (1..C::STAR_COUNT).map do
      {
        x: rand(C::SCREEN_W),
        y: rand(C::SCREEN_H),
        speed: 0.6 + rand * 2.4,
        size: [1, 1, 2, 2, 3].sample,
      }
    end
  end

  def self.tick(args)
    args.state.stars.each do |s|
      s[:y] -= s[:speed]
      if s[:y] < 0
        s[:y] = C::SCREEN_H
        s[:x] = rand(C::SCREEN_W)
      end
    end
  end

  def self.render(args)
    args.state.stars.each do |s|
      args.outputs.sprites << {
        x: s[:x], y: s[:y], w: s[:size], h: s[:size], path: :solid,
        r: 200, g: 210, b: 255, a: 180,
      }
    end
  end
end
