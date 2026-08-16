# Small bezier/easing helpers used to give enemies swooping,
# non-robotic entrance and dive-bomb flight paths.
module Curve
  def self.smoothstep(t)
    t = t.clamp(0, 1)
    t * t * (3 - 2 * t)
  end

  # Quadratic bezier -- used for the formation entrance swoop.
  def self.quad(p0, p1, p2, t)
    mt = 1 - t
    {
      x: mt * mt * p0[:x] + 2 * mt * t * p1[:x] + t * t * p2[:x],
      y: mt * mt * p0[:y] + 2 * mt * t * p1[:y] + t * t * p2[:y],
    }
  end

  # Cubic bezier -- used for the dive-bomb attack run.
  def self.cubic(p0, p1, p2, p3, t)
    mt = 1 - t
    a = mt * mt * mt
    b = 3 * mt * mt * t
    c = 3 * mt * t * t
    d = t * t * t
    {
      x: a * p0[:x] + b * p1[:x] + c * p2[:x] + d * p3[:x],
      y: a * p0[:y] + b * p1[:y] + c * p2[:y] + d * p3[:y],
    }
  end
end
