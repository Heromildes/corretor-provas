class Users::SessionsController < Devise::SessionsController
  layout "auth"

  # Além do bloqueio por conta (20 erros → 30 min, via :lockable), limita tentativas por IP
  # para dificultar quem testa senhas em vários e-mails.
  rate_limit to: 50, within: 30.minutes, only: :create,
             store: Rails.env.production? ? Rails.cache : ActiveSupport::Cache::MemoryStore.new,
             with: -> { redirect_to new_user_session_path, alert: "Muitas tentativas a partir desta rede. Aguarde 30 minutos e tente de novo." }
end
