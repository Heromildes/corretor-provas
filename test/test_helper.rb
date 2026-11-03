ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    FIXTURE_RESPONSE = Rails.root.join("test/fixtures/files/openai_response.json").to_s
    ANSWERED_PDF = Rails.root.join("db/reference/pursuit_answered.pdf")
    BLANK_PDF = Rails.root.join("db/reference/pursuit_blank.pdf")

    def activity
      @activity ||= Activity.first || begin
        silence_stream($stdout) { load Rails.root.join("db/seeds.rb") }
        Activity.first
      end
    end

    def create_submission(path: ANSWERED_PDF, content_type: "application/pdf")
      batch = Batch.create!(name: "Turma teste", activity: activity)
      batch.submissions.create!(
        file: { io: File.open(path), filename: File.basename(path), content_type: content_type },
        original_filename: File.basename(path)
      )
    end

    # Usa a resposta gravada da OpenAI em vez de chamar a API.
    def with_fake_openai(path = FIXTURE_RESPONSE)
      previous = ENV["OPENAI_FAKE_RESPONSE"]
      ENV["OPENAI_FAKE_RESPONSE"] = path
      yield
    ensure
      ENV["OPENAI_FAKE_RESPONSE"] = previous
    end

    def silence_stream(stream)
      old = stream.dup
      stream.reopen(File::NULL)
      yield
    ensure
      stream.reopen(old)
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_teacher
    sign_in users(:professora)
  end
end
