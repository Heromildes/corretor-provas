require "net/http"
require "base64"

# Corrige uma prova com o modelo da OpenAI (Responses API + Structured Outputs).
class AiGrader
  class Error < StandardError; end
  class TransientError < Error; end      # vale a pena tentar de novo (rede, 429, 5xx)
  class ConfigurationError < Error; end

  ENDPOINT = URI("https://api.openai.com/v1/responses")
  ISSUE_KINDS = SubmissionItem::ISSUE_KINDS.keys

  Result = Data.define(:student_name, :overall_feedback, :items) do
    def item(key)
      items.find { |i| i[:key] == key.to_s } ||
        { key: key.to_s, page: nil, points: 0, transcription: "", feedback: "Resposta não encontrada na prova.", strengths: "", issues: [] }
    end
  end

  def initialize(activity:, text:, images:, api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_MODEL", "gpt-6-luna"))
    @activity = activity
    @text = text
    @images = images
    @api_key = api_key
    @model = model
  end

  def call
    raise ConfigurationError, "OPENAI_API_KEY não configurada." if @api_key.blank?

    body = post(request_body)
    parse(body)
  end

  def request_body
    {
      model: @model,
      input: [
        { role: "developer", content: [ { type: "input_text", text: system_prompt } ] },
        { role: "user", content: user_content }
      ],
      text: { format: { type: "json_schema", name: "correcao_prova", strict: true, schema: schema } }
    }
  end

  private

  # ---------- Prompt ----------

  def system_prompt
    <<~PROMPT
      Você é um(a) professor(a) experiente de inglês como língua estrangeira (EFL) no Brasil, corrigindo
      uma atividade da disciplina "#{@activity.subject}". Corrija com justiça, rigor e gentileza.

      ATIVIDADE: #{@activity.name}
      Enunciado: #{@activity.instructions}

      O QUE É IMPRESSO NA FOLHA (não é resposta do aluno):
      #{printed_template}

      O QUE É RESPOSTA DO ALUNO: TODO texto que esteja DENTRO das células da tabela (abaixo de cada título de
      habilidade) e TODO texto escrito sobre/entre as linhas abaixo de cada pergunta — digitado no computador
      OU escrito à mão. A folha em branco não tem nenhum texto dentro das células; portanto, qualquer frase
      dentro de uma célula foi escrita pelo aluno e DEVE ser transcrita e corrigida.

      ITENS E RUBRICA (total #{@activity.total_points.to_i} pontos):
      #{rubric_text}

      REGRAS DE CORREÇÃO
      - Use passos de 0,5 ponto. Nunca ultrapasse o máximo do item.
      - Em branco, ilegível ou fora do tema = 0 ponto, com feedback explicando.
      - "transcription": copie FIELMENTE o que o aluno escreveu naquele item, sem corrigir nada
        (mantenha erros de grafia e pontuação, mesmo óbvios). Se estiver em branco, use "".
      - As linhas pautadas da folha passam por baixo/através da escrita: isso NÃO é texto riscado.
        Só considere algo riscado se houver um traço claramente feito pelo aluno por cima das palavras.
      - "issues": aponte cada erro. "quote" deve ser um trecho LITERAL e curto (2 a 8 palavras) da transcription,
        exatamente como aparece, para ser destacado na tela. "kind" ∈ #{ISSUE_KINDS.join(", ")}.
        "explanation" em português (curta e didática). "suggestion" = trecho corrigido em inglês.
        Para conteúdo errado/insuficiente use kind "content" ou "incomplete".
      - "feedback": 1 a 3 frases em português justificando a nota com base na rubrica.
      - "strengths": o que o aluno fez bem (português, curto). Pode ser "" se nada.
      - "page": número da página (1, 2, ...) onde a resposta está.
      - "student_name": o nome escrito no campo "Aluno(a)", ou null se não houver.
      - "overall_feedback": 2 a 4 frases em português para a professora, com visão geral e próximos passos.

      EXEMPLO DE PROVA BEM RESPONDIDA NA TABELA (apenas referência de qualidade; NÃO é gabarito literal —
      aceite outras cenas corretas do filme). Se o aluno escrever algo parecido ou até idêntico a este exemplo,
      continua sendo resposta DO ALUNO e deve ser avaliada normalmente pela rubrica:
      #{@activity.reference_text.to_s.gsub(/_{5,}/, "").squeeze("\n").strip.presence || "(sem referência)"}
    PROMPT
  end

  def printed_template
    lines = [
      "- Cabeçalho: logo da escola, \"Aluno(a): ____\", \"Data: __/__/__\", \"Disciplina\", \"Professor(a)\"; pôster do filme.",
      "- Título e enunciado da atividade (o texto do Enunciado acima).",
      "- Títulos das células da tabela (faixa cinza): #{@activity.rubric_items.select { _1[:kind] == "table" }.map { _1[:title] }.join(", ")}.",
      "- \"Answer the following prompts…\" e as perguntas numeradas: #{@activity.rubric_items.filter_map { _1[:question] }.join(" | ")}",
      "- Linhas em branco (________) e o rodapé com endereço e telefone da escola."
    ]
    lines.join("\n")
  end

  def rubric_text
    @activity.rubric_items.map do |item|
      lines = [ "- key \"#{item[:key]}\" | #{item[:title]} | máximo #{item[:max_points].to_i} pts" ]
      lines << "  Pergunta: #{item[:question]}" if item[:question]
      lines << "  Foco da habilidade: #{item[:focus]}" if item[:focus]
      lines << "  Critérios: #{item[:criteria]}"
      lines.join("\n")
    end.join("\n")
  end

  def user_content
    content = [ { type: "input_text", text: intro_text } ]
    @images.each_with_index do |path, index|
      content << { type: "input_text", text: "Página #{index + 1}:" }
      content << { type: "input_image", image_url: "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(path))}", detail: "high" }
    end
    content
  end

  def intro_text
    if @text.to_s.gsub(/[_\s]/, "").length > 200
      <<~TXT
        Corrija a prova abaixo. Seguem o texto extraído do PDF (camada digital, confiável para a transcrição)
        e as imagens das páginas (para conferir a posição de cada resposta e qualquer escrita à mão).

        TEXTO EXTRAÍDO:
        #{@text}
      TXT
    else
      "Corrija a prova abaixo. O arquivo é uma foto ou escaneamento: leia com atenção a escrita (inclusive à mão) nas imagens."
    end
  end

  def schema
    {
      type: "object",
      additionalProperties: false,
      required: %w[student_name overall_feedback items],
      properties: {
        student_name: { type: [ "string", "null" ] },
        overall_feedback: { type: "string" },
        items: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: %w[key page transcription points feedback strengths issues],
            properties: {
              key: { type: "string", enum: @activity.rubric_items.map { |i| i[:key] } },
              page: { type: [ "integer", "null" ] },
              transcription: { type: "string" },
              points: { type: "number" },
              feedback: { type: "string" },
              strengths: { type: "string" },
              issues: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  required: %w[quote kind explanation suggestion],
                  properties: {
                    quote: { type: "string" },
                    kind: { type: "string", enum: ISSUE_KINDS },
                    explanation: { type: "string" },
                    suggestion: { type: "string" }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  # ---------- HTTP ----------

  def post(payload)
    # Só para desenvolvimento/testes: simula a resposta da OpenAI a partir de um arquivo JSON.
    if (fake = ENV["OPENAI_FAKE_RESPONSE"]).present? && !Rails.env.production?
      sleep ENV.fetch("OPENAI_FAKE_DELAY", 0).to_f
      return JSON.parse(File.read(fake))
    end

    http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 600

    request = Net::HTTP::Post.new(ENDPOINT)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    body = JSON.parse(response.body) rescue {}

    if response.code.to_i == 429 && (body.dig("error", "code") == "insufficient_quota" || body.dig("error", "message").to_s.include?("credits"))
      raise ConfigurationError, "A conta da OpenAI está sem créditos. Adicione créditos em platform.openai.com e clique em \"Tentar de novo\"."
    end

    case response.code.to_i
    when 200..299 then body
    when 401
      raise ConfigurationError, "Chave da OpenAI inválida ou revogada (401). Atualize OPENAI_API_KEY."
    when 429, 500..599
      raise TransientError, "OpenAI indisponível (#{response.code}): #{body.dig('error', 'message')}"
    else
      raise Error, "OpenAI recusou a requisição (#{response.code}): #{body.dig('error', 'message')}"
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError => e
    raise TransientError, "Falha de conexão com a OpenAI: #{e.message}"
  end

  def parse(body)
    if body["status"] == "incomplete"
      raise TransientError, "Resposta incompleta da IA (#{body.dig('incomplete_details', 'reason')})."
    end

    message = Array(body["output"]).find { |o| o["type"] == "message" }
    part = Array(message&.dig("content")).find { |c| c["type"] == "output_text" }
    refusal = Array(message&.dig("content")).find { |c| c["type"] == "refusal" }
    raise Error, "A IA recusou corrigir: #{refusal['refusal']}" if refusal
    raise TransientError, "A IA não devolveu texto." if part.nil?

    data = JSON.parse(part["text"]).deep_symbolize_keys
    Result.new(
      student_name: data[:student_name].to_s.strip.presence,
      overall_feedback: data[:overall_feedback],
      items: Array(data[:items]).map { |item| item.merge(key: item[:key].to_s) }
    )
  rescue JSON::ParserError
    raise TransientError, "A IA devolveu um JSON inválido."
  end
end
