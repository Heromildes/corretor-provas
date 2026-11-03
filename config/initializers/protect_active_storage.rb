# Arquivos das provas (PDFs e páginas) também exigem login: os controllers do Active Storage
# não herdam do ApplicationController, então aplicamos o mesmo filtro neles.
Rails.application.config.to_prepare do
  ActiveStorage::BaseController.before_action :authenticate_user!
end
