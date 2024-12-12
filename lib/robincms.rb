# frozen_string_literal: true

require 'sinatra/base'

require_relative 'version'
require_relative 'model'

module RobinCMS
  class CMS < Sinatra::Base
    set :sessions, true
    set :public_folder, File.join(__dir__, 'public')
    set :views, File.join(__dir__, 'views')

    get '/login' do
      erb :login
    end

    post '/login' do
      unless authenticated?(ENV['ADMIN_PASS'], params['password'])
        @error = 'Incorrect username or password'
        erb :login
      end

      session['authenticated'] = true

      redirect '/admin'
    end

    get '/logout' do
      session['authenticated'] = nil

      redirect '/login'
    end

    get '/admin' do
      @articles = Article.all

      erb :admin
    end

    get '/admin/article' do
      if params['id']
        @article = Article.find(params['id'])

        return 404 unless @article

        erb :article
      else
        @article = Article.new

        erb :article
      end
    end

    post '/admin/article' do
      if params['id']
        @article = Article.find(params['id'])

        return 404 unless @article

        @article.content = params['content']
        @article.meta = params
        @article.update
      else
        id = make_stub(params['title'])

        if Article.find(id)
          @error = 'An article with the same name already exists'
          erb :error
        end

        Article.create(id, params['content'], meta)
      end

      redirect '/admin'
    end

    post '/admin/article/delete' do
      if params['id']
        @article = Article.find(params['id'])

        return 404 unless @article

        @article.delete
      else
        return 404
      end

      redirect '/admin'
    end

    before /\/admin/ do
      unless session['authenticated']
        redirect '/login'
      end
    end

    error 404 do
      'Not found.'
    end

    error do
      [500, 'Oops, something went wrong...']
    end
  end
end
