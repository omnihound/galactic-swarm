require 'app/constants.rb'
require 'app/curve.rb'
require 'app/audio.rb'
require 'app/high_score.rb'
require 'app/starfield.rb'
require 'app/sprite_gen.rb'
require 'app/fx.rb'
require 'app/bullets.rb'
require 'app/player.rb'
require 'app/enemies.rb'
require 'app/collisions.rb'
require 'app/scenes.rb'
require 'app/game.rb'

module Main
  def tick args
    Game.tick args
  end
end
