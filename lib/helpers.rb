# frozen_string_literal: true

require 'bcrypt'

module RobinCMS
  def authenticated?(hash, guess)
    hashed = BCrypt::Password.new(hash)
    hashed == guess
  end

  def make_stub(str)
    str.gsub(/\s/, '-').gsub(/[^\w-]/, '')
  end
end
