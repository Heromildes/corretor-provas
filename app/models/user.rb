class User < ApplicationRecord
  # Sem :registerable (ninguém cria conta pela tela) e sem :recoverable (não há e-mail configurado).
  # :lockable bloqueia a conta por 30 min após 20 senhas erradas (config/initializers/devise.rb).
  devise :database_authenticatable, :rememberable, :validatable, :lockable, :trackable

  normalizes :email, with: ->(email) { email.strip.downcase }

  def display_name
    name.presence || email.split("@").first
  end

  def initials
    display_name.split(/[\s._-]+/).first(2).map { _1[0] }.join.upcase
  end
end
