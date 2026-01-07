#===============================================================================
# Redistribuidor de EV'S
# Creado por Clara. Compatibilidad con Essentials BES
# Compatibilidad con La Base De Sky y mejoras por DPertierra
# Permite mover los ev's que ya posee el pokémon a otra posición.
# El coste va aumentando a mas puntos añades a un stat(de base los que ya tiene actualmente)
# Pretende ser un "clon" de la pantalla de datos de los pokémon, si quieres editar esa parte, 
# Ve a def drawPokeData
#===============================================================================

module EVRedirector
  EDIT_EVS = true
  EDIT_IVS = true

  COST_DIFFERENCE_EV = 500
  COST_DIFFERENCE_IV = 2000
  MAX_EVS = 510
  MAX_EV_PER_STAT = 252
  MAX_IV = 31

  # Si este parámetro está en true en la parte del summary donde está la C saldran las opciones para acceder
  # Al EV/IV Redirector
  ADD_EV_IV_REDIRECTOR_TO_SUMMARY = true

  module_function
  def add_options_to_summary(page = :summary, subpage = :page_allstats)
    if EDIT_EVS && EDIT_IVS
      # options = [:EVRedirector, :IVRedirector]
      options = [_INTL("Organizar EVs"), _INTL("Organizar IVs")]
    elsif EDIT_EVS
      options = [_INTL("Organizar EVs")]
    else
      options = [_INTL("Organizar IVs")]
    end
    UIHandlers.edit_hash(page, subpage, "options", options)
  end

  def can_change_mode?
    return EDIT_EVS && EDIT_IVS
  end
end






if EVRedirector::EDIT_EVS || EVRedirector::EDIT_IVS
  if UIHandlers.exists?(:summary, :page_allstats) && EVRedirector::ADD_EV_IV_REDIRECTOR_TO_SUMMARY
    EVRedirector.add_options_to_summary(:summary, :page_allstats)
  elsif UIHandlers.exists?(:summary, :page_skills) && EVRedirector::ADD_EV_IV_REDIRECTOR_TO_SUMMARY
    EVRedirector.add_options_to_summary(:summary, :page_skills)
  end

  class PokemonSummary_Scene
    alias ev_pbPageCustomOption pbPageCustomOption
    def pbPageCustomOption(cmd)
      if cmd == _INTL("Organizar EVs")
        return pbReorganizeEVs(@pokemon) if defined?(pbReorganizeEVs) && !@pokemon.egg?
      elsif cmd == _INTL("Organizar IVs")
        return pbReorganizeEVs(@pokemon, :IV) if defined?(pbReorganizeEVs) && !@pokemon.egg?
      end
      return ev_pbPageCustomOption(cmd)
    end
  end

  class EVReorganizeScene
      ######## CONFIGURACIÓN ########      
      BASECOLOR_LIGHT   = Color.new(248,248,248)
      SHADOWCOLOR_LIGHT = Color.new(47,46,54)
      
      BASECOLOR_DARK   = Color.new(64,64,64)
      SHADOWCOLOR_DARK = Color.new(176,176,176)
   
      
      ###############################
      def initialize(pokemon, mode = :EV)
        @pokemon = pokemon
        @mode = mode
        @original_evs = dup_ev_iv(pokemon.ev)
        @current_evs  = dup_ev_iv(@original_evs)
        @original_ivs = dup_ev_iv(pokemon.iv)
        @current_ivs  = dup_ev_iv(@original_ivs)
        # @max_evs = 510
        @cost_per_change = mode == :IV ? EVRedirector::COST_DIFFERENCE_IV : EVRedirector::COST_DIFFERENCE_EV
        @selected_stat = 0
        @changed = false
        @base=BASECOLOR_LIGHT
        @shadow=SHADOWCOLOR_LIGHT
    
        @base2=BASECOLOR_DARK
        @shadow2=SHADOWCOLOR_DARK
        @statshadows = {}
      end

      def dup_ev_iv(hash)
        new_hash = {}
        hash.each { |key, value| new_hash[key] = value }
        new_hash
      end

      def change_mode
        @mode = @mode == :EV ? :IV : :EV
        @cost_per_change = @mode == :IV ? EVRedirector::COST_DIFFERENCE_IV : EVRedirector::COST_DIFFERENCE_EV
      end
    
      def pbPokerus(pkmn)
        return pkmn.pokerusStage
      end
      
      def pbStartScene
        
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @sprites = {}
    
        addBackgroundPlane(@sprites,"bg","/EVRedirector/bg",@viewport)
        addBackgroundPlane(@sprites,"background","/EVRedirector/page",@viewport)
    
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["overlay2"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @overlay = @sprites["overlay"].bitmap
        @sprites["overlay2"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @overlay2 = @sprites["overlay2"].bitmap
    
        drawPokeData
        drawScreen
        
        pbFadeInAndShow(@sprites) { pbUpdate }
      end
      
      def drawPokeData
        @sprites["pokemon"]=PokemonSprite.new(@viewport)
        @sprites["pokemon"].setPokemonBitmap(@pokemon)
        # @sprites["pokemon"].tone=TERATONES[@pokemon.teratype] if @pokemon.isTera?
        @sprites["pokemon"].mirror=false
        @sprites["pokemon"].color=Color.new(0,0,0,0)
        @sprites["pokemon"].x = 104
        @sprites["pokemon"].y = 206
        @sprites["itemicon"] = ItemIconSprite.new(30, 320, @pokemon.item_id, @viewport)
        @sprites["itemicon"].item = @pokemon.item_id
        # pbPositionPokemonSprite(@sprites["pokemon"],40,144)
        
        imagepos = []
        textpos = []
        
        
        pbSetSystemFont(@overlay)

        ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
        imagepos.push([ballimage, 14, 60])
        pagename = "#{@mode.to_s} Redirector"
        textpos = [
          [pagename, 26, 22, :left, @base, @shadow],
          [@pokemon.name, 46, 68, :left, @base, @shadow],
          [_INTL("Objeto"), 66, 324, :left, @base, @shadow]
        ]

        aux_mode = @mode == :EV ? :IV : :EV
        textpos.push(["[D] " + _INTL("Cambiar modo ({1})", aux_mode.to_s), Graphics.width - 230, 22, :left, @base, @shadow]) if EVRedirector.can_change_mode?

        if @pokemon.hasItem?
          textpos.push([@pokemon.item.name, 16, 358, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        else
          textpos.push([_INTL("Ninguno"), 16, 358, :left, Color.new(192, 200, 208), Color.new(208, 216, 224)])
        end
        # Draws additional info for non-Egg Pokemon.
        if !@pokemon.egg?
          status = -1
          if @pokemon.fainted?
            status = GameData::Status.count - 1
          elsif @pokemon.status != :NONE
            status = GameData::Status.get(@pokemon.status).icon_position
          elsif @pokemon.pokerusStage == 1
            status = GameData::Status.count 
          end
          if status >= 0
            imagepos.push(["Graphics/UI/statuses", 124, 100, 0, 16 * status, 44, 16])
          end
          if @pokemon.pokerusStage == 2
            imagepos.push(["Graphics/UI/Summary/icon_pokerus", 176, 100])
          end
          imagepos.push(["Graphics/UI/shiny", 2, 134]) if @pokemon.shiny?
          textpos.push([@pokemon.level.to_s, 46, 98, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
          if @pokemon.male?
            textpos.push([_INTL("♂"), 178, 68, :left, Color.new(24, 146, 240), Color.new(13, 73, 119)])
          elsif @pokemon.female?
            textpos.push([_INTL("♀"), 178, 68, :left, Color.new(249, 93, 210), Color.new(128, 20, 90)])
          end
        end

        GameData::Stat.each_main { |s| @statshadows[s.id] = @shadow }
        if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
          @pokemon.nature_for_stats.stat_changes.each do |change|
            @statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
            @statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
          end
        end
        
        pbDrawTextPositions(@overlay, textpos)
        pbDrawImagePositions(@overlay, imagepos)
      end
      
      
      def pbUpdate
        pbUpdateSpriteHash(@sprites)
      end
      
      STAT_ORDER = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]
      
      STAT_NAMES = {:HP => _INTL("PS"), :ATTACK => (_INTL("Ataque")), :DEFENSE => _INTL("Defensa"), 
                    :SPEED => _INTL("Vel."), :SPECIAL_ATTACK => _INTL("At. Esp."), :SPECIAL_DEFENSE => _INTL("Def Esp.")}
      
      def drawScreen
        @overlay2.clear
        # drawPokeData
        textpos = []
        imagepos = []
        pbSetSystemFont(@overlay2)
        
        # Identificar los dos stats más altos
        top_stats = getTopTwoStats
    
        # Dibujar nombres y valores de stats
        stats =  { :HP => @pokemon.totalhp, :ATTACK => @pokemon.attack, :DEFENSE => @pokemon.defense,
                  :SPEED => @pokemon.speed, :SPECIAL_ATTACK => @pokemon.spatk, :SPECIAL_DEFENSE => @pokemon.spdef }
        
        # Recalcular valores actualizados
        # GameData::Stat.each_main { |s| statshadows[s.id] = @shadow }
        # if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
        #   @pokemon.nature_for_stats.stat_changes.each do |change|
        #     statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        #     statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
        #   end
        # end

        i = 0

        GameData::Stat.each_main {|stat|
          y = 88 + i * 32
          textpos.push([STAT_NAMES[stat.id], 234, y + 4, 0, @base, @statshadows[stat.id]])
          textpos.push([stats[stat.id].to_s, 366, y + 4, 2, @base2, @shadow2])
          textpos.push([@current_evs[stat.id].to_s, 424, y + 4, 2, @base2, @shadow2])
          textpos.push([@current_ivs[stat.id].to_s, 476, y + 4, 2, @base2, @shadow2])

          @arrowbitmap = AnimatedBitmap.new("Graphics/UI/EVRedirector/arrow_mini")
          rectsize = 32

          arrow_x = @mode == :EV ? 422 : 474
          @overlay2.blt(arrow_x-rectsize-8, y - 2, @arrowbitmap.bitmap, Rect.new(0, 0, rectsize, rectsize))
          @overlay2.blt(arrow_x+8, y - 2, @arrowbitmap.bitmap, Rect.new(rectsize, 0, rectsize, rectsize))
        

          # Marcar con imagen si es uno de los stats más altos
          if top_stats.include?(stat.id)
            imagepos.push(["Graphics/UI/EVRedirector/recomended", 330, y + 8, 0, 0, -1, -1])
          end
    
          # Selector
          if i == @selected_stat
            imagepos.push(["Graphics/UI/EVRedirector/selector", 224, y - 3, 0, 0, -1, -1])
          end
          i+=1
        }
    
        # EVs totales y restantes
        if @mode == :EV
          total_evs = @current_evs.values.inject(0) { |sum, ev| sum + ev }
          remaining_evs = EVRedirector::COST_DIFFERENCE_EV - total_evs
          textpos.push([_INTL("EVs Totales: {1}/{2}", total_evs, EVRedirector::COST_DIFFERENCE_EV), 234, 288, false, @base2, @shadow2])
          textpos.push([_INTL("EVs Restantes: {1}", remaining_evs), 234, 320, false, @base2, @shadow2])
        else
          stat = STAT_ORDER[@selected_stat]
          textpos.push([_INTL("IVs Totales: {1}/{2}", @current_ivs[stat], EVRedirector::MAX_IV), 234, 288, false, @base2, @shadow2]) if @current_ivs[stat]
          textpos.push([_INTL("IVs Restantes: {1}", EVRedirector::MAX_IV - @current_ivs[stat]), 234, 320, false, @base2, @shadow2]) if @current_ivs[stat]
        end
        # Coste
        cost = calculateCost
        cost_color = cost > $player.money ? Color.new(255, 0, 0) : @base2
        textpos.push(["Coste: #{cost}$", 234, 352, false, cost_color, @shadow2])
    
        # Confirmar botón
        confirm_color = @selected_stat == 6 ? Color.new(0, 255, 0) : @base2
        textpos.push(["Confirmar", 400, 352, false, confirm_color, @shadow2])
    
        if @selected_stat == 6
          imagepos.push(["Graphics/UI/EVRedirector/selectorS", 384, 345, 0, 0, -1, -1])
        end
        
        
        pbDrawTextPositions(@overlay2, textpos)
        pbDrawImagePositions(@overlay2, imagepos)
      end
      
      
      
      def pbScene
        loop do
          Graphics.update
          Input.update
          pbUpdate
    
          # Cálculo de EVs restantes y validación
          total_evs = @current_evs.values.inject(0) { |sum, ev| sum + ev }
          
          remaining_evs = EVRedirector::COST_DIFFERENCE_EV - total_evs
    
          # Navegación de estadísticas
          if Input.trigger?(Input::UP)
            @selected_stat = (@selected_stat - 1) % 7
          elsif Input.trigger?(Input::DOWN)
            @selected_stat = (@selected_stat + 1) % 7
          end

          if Input.trigger?(Input::SPECIAL) && EVRedirector.can_change_mode?
            if pbConfirmMessage(_INTL("¿Deseas cambiar de modo?"))
              change = true
              cost = calculateCost
              if cost > 0
                if cost <= $player.money
                  if Kernel.pbConfirmMessage(_INTL("¿Confirmar cambios?"))
                    applyChanges(cost)
                    pbMessage(_INTL("Los {1} fueron reorganizados con éxito.", "#{@mode.to_s}s"))
                  else
                    if Kernel.pbConfirmMessage(_INTL("Los cambios de #{@mode.to_s}s se revertirán. ¿Desea continuar?"))
                      revertChanges
                    else
                      change = false
                    end
                  end
                else
                  Kernel.pbMessage(_INTL("No tienes suficiente dinero para estos cambios de #{@mode.to_s}s.\nSe revertirán y se procederá con el cambio de modo"))
                  revertChanges
                end
              end
              change_mode if change
            end
          end
    
          # Modificación de EVs
          if @selected_stat < 6
            stat = STAT_ORDER[@selected_stat]
            if Input.repeat?(Input::LEFT)
              if @mode == :EV
                modifyEvs(stat, -1) if @current_evs[stat] > 0
              else
                modifyIvs(stat, -1) if @current_ivs[stat] > 0
              end
            elsif Input.repeat?(Input::RIGHT)
              if @mode == :EV
                modifyEvs(stat, 1) if @current_evs[stat] < EVRedirector::MAX_EV_PER_STAT && remaining_evs > 0
              else
                modifyIvs(stat, 1) if @current_ivs[stat] < EVRedirector::MAX_IV
              end
            elsif Input.repeat?(Input::JUMPDOWN)
              modifyEvs(stat, -4) if @current_evs[stat] >= 4 && @mode == :EV
            elsif Input.repeat?(Input::JUMPUP)
              modifyEvs(stat, 4) if @current_evs[stat] < EVRedirector::MAX_EV_PER_STAT - 4 && remaining_evs >= 4 && @mode == :EV
            elsif Input.trigger?(Input::AUX1)
              if @mode == :EV
                modifyEvs(stat, -@current_evs[stat]) # Quitar todos los EVs
              else
                modifyIvs(stat, -@current_ivs[stat]) # Quitar todos los IVs
              end
            elsif Input.trigger?(Input::AUX2)
              if @mode == :EV
                max_addable = [EVRedirector::MAX_EV_PER_STAT - @current_evs[stat], remaining_evs].min
                modifyEvs(stat, max_addable) # Añadir todos los EVs posibles
              else
                max_addable = EVRedirector::MAX_IV - @current_ivs[stat]
                modifyIvs(stat, max_addable) # Añadir todos los IVs posibles
              end
            end
          end
    
          # Confirmación de cambios
          if Input.trigger?(Input::USE) && @selected_stat == 6
            cost = calculateCost
            if cost >= 0 && cost <= $player.money
              if Kernel.pbConfirmMessage(_INTL("¿Confirmar cambios?"))
                applyChanges(cost)
                pbMessage(_INTL("Los {1} fueron reorganizados con éxito.", "#{@mode.to_s}s"))
                return @changed
                # break
              end
            elsif cost > $player.money
              Kernel.pbMessage(_INTL("No tienes suficiente dinero."))
            end
          end
    
          # Cancelación de cambios
          if Input.trigger?(Input::BACK)
            if Kernel.pbConfirmMessage("¿Cancelar la reorganización?")
              revertChanges
              return @changed
              # break
            end
          end
    
          drawScreen
        end
      end
    
      def modifyEvs(stat, change)
        @current_evs[stat] += change
        @pokemon.ev[stat] = @current_evs[stat]
        @pokemon.calc_stats
        pbSEPlay("GUI sel cursor")
      end

      def modifyIvs(stat, change)
        @current_ivs[stat] += change
        @pokemon.iv[stat] = @current_ivs[stat]
        @pokemon.calc_stats
        pbSEPlay("GUI sel cursor")
      end
      
      def applyChanges(cost)
        $player.money -= cost
        if @mode == :EV
          GameData::Stat.each_main { |s| @pokemon.ev[s.id] = @current_evs[s.id] }
        else
          GameData::Stat.each_main { |s| @pokemon.iv[s.id] = @current_ivs[s.id] }
        end
        @pokemon.calc_stats
        @changed = true
        pbSEPlay("SlotsCoin")
      end
      
      def revertChanges
        @current_evs = @original_evs.clone
        if @mode == :EV
          GameData::Stat.each_main { |s| @pokemon.ev[s.id] = @original_evs[s.id] }
        else
          GameData::Stat.each_main { |s| @pokemon.iv[s.id] = @original_ivs[s.id] }
        end
        @pokemon.calc_stats
      end
      
      def calculateCost
        cost = 0
        if @mode == :EV
          GameData::Stat.each_main { |s| 
            change = @current_evs[s.id] - @original_evs[s.id]
            cost += change * @cost_per_change if change > 0 
          }
        else
          GameData::Stat.each_main { |s| 
            change = @current_ivs[s.id] - @original_ivs[s.id]
            cost += change * @cost_per_change if change > 0 
          }
        end
        return cost
      end
    
      def getTopTwoStats
        base_stats = @pokemon.species_data.base_stats
        base_stats.sort_by { |key, value| -value }.first(2).map { |key, _value| key }
      end
      
      def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
      end
      
  end
    
  class EVReorganize
      def initialize(scene)
          @scene = scene
      end

      def pbStartScreen
          @scene.pbStartScene
          ret=@scene.pbScene
          @scene.pbEndScene
          return ret
      end

  end

  def pbReorganizeEVs(pokemon, mode = :EV)
      pbFadeOutIn {
          scene = EVReorganizeScene.new(pokemon, mode)
          screen = EVReorganize.new(scene)
          ret = screen.pbStartScreen
          return ret
      }
  end

end