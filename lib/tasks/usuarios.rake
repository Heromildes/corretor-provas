# Contas são criadas só pelo terminal (não há cadastro na tela).
#   bin/rails "usuarios:criar[professora@escola.com.br,Sandy Metz]"
#   SENHA=... bin/rails "usuarios:criar[...]"   # sem SENHA, gera uma senha forte e mostra uma vez
namespace :usuarios do
  desc "Cria (ou atualiza a senha de) uma conta de professor(a)"
  task :criar, %i[email nome] => :environment do |_, args|
    abort "Uso: bin/rails \"usuarios:criar[email,Nome]\"" if args[:email].blank?

    password = ENV["SENHA"].presence || SecureRandom.base58(14)
    user = User.find_or_initialize_by(email: args[:email].strip.downcase)
    user.name = args[:nome] if args[:nome].present?
    user.password = password
    user.unlock_access! if user.persisted? && user.access_locked?
    user.save!

    puts "Conta pronta: #{user.email}"
    puts "Senha: #{password}" if ENV["SENHA"].blank?
  end

  desc "Desbloqueia uma conta antes dos 30 minutos"
  task :desbloquear, %i[email] => :environment do |_, args|
    user = User.find_by!(email: args[:email].to_s.strip.downcase)
    user.unlock_access!
    puts "Conta desbloqueada: #{user.email}"
  end

  desc "Lista as contas"
  task listar: :environment do
    User.order(:email).each do |u|
      puts [ u.email, u.name, (u.access_locked? ? "BLOQUEADA" : "ativa"), u.last_sign_in_at ].compact.join(" · ")
    end
  end
end
