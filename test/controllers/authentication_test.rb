require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  PASSWORD = "senha-de-teste-123"

  setup { @user = users(:professora) }

  def attempt(password)
    post user_session_path, params: { user: { email: @user.email, password: password } }
  end

  test "todas as páginas exigem login" do
    batch = Batch.create!(name: "T", activity: activity)
    [ root_path, batch_path(batch), submission_path(create_submission) ].each do |path|
      get path
      assert_redirected_to new_user_session_path, path
    end
    get batch_path(batch, format: :csv)
    assert_response :unauthorized
  end

  test "arquivos das provas também exigem login" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("x"), filename: "a.pdf", content_type: "application/pdf")
    get rails_blob_path(blob, disposition: "inline")
    assert_response :unauthorized

    sign_in @user
    get rails_blob_path(blob, disposition: "inline")
    assert_response :redirect, "logada, o arquivo abre"
    assert_no_match %r{/entrar}, response.location
  end

  test "não existe cadastro nem recuperação de senha" do
    assert_not Rails.application.routes.url_helpers.respond_to?(:new_user_registration_path)
    assert_not Rails.application.routes.url_helpers.respond_to?(:new_user_password_path)
    get "/users/sign_up"
    assert_response :not_found
  end

  test "login com senha certa abre as turmas" do
    attempt(PASSWORD)
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select ".cw-menu__head", @user.email
  end

  test "20 senhas erradas bloqueiam a conta por 30 minutos" do
    19.times { attempt("errada") }
    assert_not @user.reload.access_locked?

    attempt("errada")
    assert @user.reload.access_locked?, "a 20ª tentativa bloqueia"

    attempt(PASSWORD)
    assert_response :unprocessable_content
    assert_match "bloqueada", flash[:alert].to_s

    travel 29.minutes do
      attempt(PASSWORD)
      assert_response :unprocessable_content, "ainda bloqueada antes dos 30 minutos"
    end

    travel 31.minutes do
      attempt(PASSWORD)
      assert_redirected_to root_path
      assert_equal 0, @user.reload.failed_attempts
    end
  end

  test "sair encerra a sessão" do
    sign_in @user
    delete destroy_user_session_path
    get root_path
    assert_redirected_to new_user_session_path
  end
end
