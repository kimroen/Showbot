# showbot_web.rb
# The web front-end for showbot

# Gems
require 'bundler/setup'
require 'coffee_script'
require 'sinatra' unless defined?(Sinatra)
require "sinatra/reloader" if development?

require File.join(File.dirname(__FILE__), 'environment')


SHOWS_JSON = File.expand_path(File.join(File.dirname(__FILE__), "public", "shows.json")) unless defined? SHOWS_JSON

class ShowbotWeb < Sinatra::Base
  configure do
    set :public_folder, "#{File.dirname(__FILE__)}/public"
    set :views, "#{File.dirname(__FILE__)}/views"
    set :shows, Shows.new(SHOWS_JSON)
  end

  configure(:production, :development) do
    enable :logging
  end

  configure :development do
    register Sinatra::Reloader
  end

  # =================
  # Pages
  # =================

  # CoffeeScript
  get '/js/showbot.js' do
    coffee :'coffeescripts/showbot'
  end

  get '/' do
    @title = "Home"
    @suggestion_sets = Suggestion.recent.all(:order => [:created_at.desc]).group_by_show
    haml :index
  end

  get '/titles' do
    @title = "Title Suggestions in the last 24 hours"
    @suggestion_sets = Suggestion.recent.all(:order => [:created_at.desc]).group_by_show
    haml :'suggestion/index'
  end

  get '/links' do
    @title = "Suggested Links in the last 24 hours"
    @links = Link.recent.all(:order => [:created_at.desc])
    haml :links
  end

  get '/all' do
    @title = "All Title Suggestions"
    @suggestion_sets = Suggestion.all(:order => [:created_at.desc]).group_by_show
    haml :'suggestion/index'
  end

  # ===========
  # Helpers
  # ===========

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def external_link(link)
      /^http/.match(link) ? link : "http://#{link}"
    end

    # Returns a string truncated in the middle
    # Note: Rounds max_length down to nearest even number
    def truncate_string(string, max_length)
      if string.length > max_length
        # +/- 2 is to account for the elipse in the middle
        "#{string[0..(max_length/2)-2]}...#{string[-(max_length/2)+2..-1]}"
      else
        string
      end
    end

    def suggestion_set_hr(suggestion_set)
      text = "Show Not Listed"
      if suggestion_set.slug
        text = Shows.find_show_title(suggestion_set.slug)
      end
      "<h2 class='show_break'>#{text}</h2>"
    end

  end # helpers

end
