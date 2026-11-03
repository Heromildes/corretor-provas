require "test_helper"

class AiGraderTest < ActiveSupport::TestCase
  def grader(**opts)
    AiGrader.new(activity: activity, text: "texto", images: [ ANSWERED_PDF ], api_key: "sk-test", **opts)
  end

  test "requisição usa gpt-6-luna, JSON Schema estrito e envia as páginas como imagem" do
    body = grader.request_body
    assert_equal "gpt-6-luna", body[:model]
    format = body.dig(:text, :format)
    assert_equal "json_schema", format[:type]
    assert format[:strict]
    item_schema = format.dig(:schema, :properties, :items, :items)
    assert_equal activity.rubric_items.map { _1[:key] }, item_schema.dig(:properties, :key, :enum)
    assert_equal item_schema[:properties].keys.map(&:to_s).sort, item_schema[:required].sort

    user = body[:input].last[:content]
    assert user.any? { _1[:type] == "input_image" && _1[:image_url].start_with?("data:image/jpeg;base64,") }
    assert_includes body[:input].first[:content].first[:text], "máximo 30 pts"
  end

  test "interpreta a resposta da OpenAI" do
    result = with_fake_openai { grader.call }
    assert_equal 10, result.items.size
    assert_equal 5, result.item(:career_development)[:points]
    assert_equal "", result.item(:strongest)[:transcription]
    assert_nil result.student_name
  end

  test "item ausente vira zero" do
    result = AiGrader::Result.new(student_name: nil, overall_feedback: "", items: [])
    assert_equal 0, result.item(:teamwork)[:points]
  end

  test "sem chave configurada" do
    assert_raises(AiGrader::ConfigurationError) { AiGrader.new(activity:, text: "", images: [], api_key: "").call }
  end
end
