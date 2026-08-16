# All hit-testing lives here: player bullets vs enemies, enemy
# bullets vs player, and diving enemies ramming the player. Dead
# enemies are pruned from args.state.enemies at the end of the tick,
# so callers elsewhere never need to check for a :dead state.
module Collisions
  def self.overlap?(a, b)
    (a[:x] - b[:x]).abs * 2 < (a[:w] + b[:w]) && (a[:y] - b[:y]).abs * 2 < (a[:h] + b[:h])
  end

  def self.tick(args)
    player = args.state.player
    invulnerable = Kernel.tick_count < player[:invuln_until]

    args.state.player_bullets.reject! do |b|
      hit = args.state.enemies.find { |e| e[:state] != :dead && overlap?(b, e) }
      next false unless hit
      resolve_enemy_hit(args, hit)
      true
    end

    if player[:alive] && !invulnerable
      args.state.enemy_bullets.reject! do |b|
        if overlap?(b, player)
          Player.hit!(args)
          true
        else
          false
        end
      end

      rammer = args.state.enemies.find { |e| e[:state] == :diving && overlap?(e, player) }
      if rammer
        resolve_enemy_hit(args, rammer)
        Player.hit!(args)
      end
    end

    args.state.enemies.reject! { |e| e[:state] == :dead }
  end

  def self.resolve_enemy_hit(args, e)
    e[:hp] -= 1

    if e[:hp] <= 0
      e[:state] = :dead
      FX.explosion(args, e[:x], e[:y])
      FX.popup_score(args, e[:x], e[:y], e[:score])
      args.state.score += e[:score]
      Audio.play(args, 'sounds/explosion.wav')
    else
      e[:hit_flash_until] = Kernel.tick_count + 6
      Audio.play(args, 'sounds/enemy_hit.wav')
    end
  end
end
