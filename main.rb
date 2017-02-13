require 'rubygems'
require 'pry'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret_random_string' 

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_BET_AMOUNT = 500

before do
  @show_hit_or_stay_buttons = true
end

helpers do
  def calculate_total(cards) # cards is [["H", "3"], ["D", "J"], ... ]
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    #correct for Aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace' 
      end 
    end 

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"

  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg} and #{session[:player_name]} now has <strong><em>$#{session[:player_pot]}</em></strong> remaining"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:player_name]} lost!</strong> #{msg} and #{session[:player_name]} now has <strong><em>$#{session[:player_pot]}</em></strong> remaining"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>It's a tie!</strong> #{msg} and #{session[:player_name]} now has <strong><em>$#{session[:player_pot]}</em></strong> remaining"
  end
end

# put calculate_total([["H", "3"], ["D", "J"]]) here not working, helper method can only be accessed in request handler or view

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end 
end

get '/new_player' do
  # calculate_total([["H", "3"], ["D", "J"]])  works (helper methods only accessible in request scope or view)
  session[:player_pot] = INITIAL_BET_AMOUNT
  erb :new_player
end


post '/new_player' do
  if params[:player_name].empty?
    @error = "name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/bet'
end


get '/bet' do
  #session[:player_bet] = nil  - not needed
  erb :bet
end


post '/bet' do
  if params[:bet_amount].to_i == 0  
# input field value comes as string, notice parmas[:bet_amount].nil? check is not needed because if you don't type anything, "".to_i is 0  also know that  nil.to_s is "" nil.to_i is 0
    @error = "Must make a bet. Must type a number."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end


get '/game' do
  session[:turn] = session[:player_name]
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  # deck
  session[:deck] = suits.product(values).shuffle!

  # deal cards
  # deler cards
  # player cards
  # create a deck and put it in session
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop 
  session[:player_cards] << session[:deck].pop 
  session[:dealer_cards] << session[:deck].pop 
  session[:player_cards] << session[:deck].pop 

  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    winner!("Wow, #{session[:player_name]} already hit blackjack")
  end

  erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")  
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:player_name]} busted at #{player_total}")
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  # @success = "#{session[:player_name]} has chosen to stay."   not needed anymore
  # @show_hit_or_stay_buttons = false   not needed anymore
  redirect '/game/dealer'
end


get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  session[:turn] = "dealer"

  # decision tree
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT #17, 18, 19, 20
    # dealer stays when it's 17, 18, 19, 20
    redirect '/game/compare'
  else
    # dealer hits - dealer lower that 17 has to hit
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
end


post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end


get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}")
  end

  erb :game, layout:false
end


get '/game_over' do
  erb :game_over
end


# this code is just to show how to show nested template, that's all. no usage for your production
get '/nested_template' do
  erb :"/users/profile"
end

