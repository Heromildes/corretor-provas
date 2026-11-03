# Atividade base: "The Pursuit of Happyness – Employability Skills in Action"
# 8 blocos da tabela (5 pts cada) + 2 perguntas pessoais (30 pts cada) = 100 pts.

table_criteria = <<~TXT.squish
  Até 2 pts: o exemplo é uma cena ou ação real do filme (sem invenções nem confusões de enredo).
  Até 1,5 pt: o exemplo demonstra claramente ESTA habilidade e cita a característica de forma explícita.
  Até 1 pt: a cena é específica e detalhada (o que, quando e como), não uma frase genérica.
  Até 0,5 pt: inglês claro e correto (gramática, ortografia, vocabulário).
  Em branco ou ilegível = 0.
TXT

open_criteria = <<~TXT.squish
  Até 6 pts: identifica exatamente DUAS habilidades válidas da lista (Career Development, Communication,
  Ethics & Legal, Foundational, Interpersonal, Leadership, Problem Solving & Critical Thinking, Teamwork).
  Até 12 pts: justifica cada habilidade com cenas/exemplos concretos do filme.
  Até 6 pts: análise crítica, opinião pessoal coerente e bem argumentada.
  Até 6 pts: inglês (gramática, ortografia, vocabulário, organização e coesão do texto).
  Se citar só uma habilidade, no máximo metade dos pontos de identificação e justificativa. Em branco = 0.
TXT

skills = [
  [ "career_development", "Career Development", "Planejamento de carreira, metas, determinação para crescer profissionalmente." ],
  [ "communication", "Communication", "Comunicação verbal e não verbal, escuta, clareza, persuasão." ],
  [ "ethics_legal", "Ethics & Legal", "Honestidade, integridade, responsabilidade, respeito às regras e leis." ],
  [ "foundational", "Foundational", "Habilidades básicas: matemática, leitura, escrita, tecnologia, gestão do tempo." ],
  [ "interpersonal", "Interpersonal", "Relacionamentos, empatia, respeito, paciência, lidar com pessoas." ],
  [ "leadership", "Leadership", "Responsabilidade, tomada de decisão, inspirar e orientar outras pessoas." ],
  [ "problem_solving", "Problem Solving & Critical Thinking", "Soluções criativas, raciocínio, análise de situações difíceis." ],
  [ "teamwork", "Teamwork", "Colaboração, cooperação, trabalho com colegas e relações profissionais." ]
]

rubric = skills.map do |key, title, focus|
  { key:, title:, kind: "table", max_points: 5, focus:, criteria: table_criteria }
end

rubric << {
  key: "strongest", kind: "open", max_points: 30,
  title: "1. Two strongest skills",
  question: "In your opinion, which two employability skills was Chris the strongest? Explain your response.",
  criteria: open_criteria
}
rubric << {
  key: "weakest", kind: "open", max_points: 30,
  title: "2. Two weakest skills",
  question: "In your opinion, which two employability skills was Chris the weakest? Explain your response.",
  criteria: open_criteria + " É uma pergunta de opinião: aceite qualquer escolha bem fundamentada com cenas do filme."
}

reference_path = Rails.root.join("db/reference/pursuit_answered.pdf")
reference_text = File.exist?(reference_path) ? `pdftotext -layout #{reference_path.to_s.shellescape} -` : nil

activity = Activity.find_or_initialize_by(name: "The Pursuit of Happyness – Employability Skills in Action")
activity.update!(
  subject: "Academic Reading and Writing",
  instructions: "As you watch 'The Pursuit of Happyness', provide examples from the movie showing how Chris Gardner " \
                "exemplifies each of the employability skills. Reference the specific characteristic from your notes " \
                "and describe a detailed scene and example below.",
  rubric: rubric,
  reference_text: reference_text
)

if File.exist?(reference_path) && !activity.reference_file.attached?
  activity.reference_file.attach(io: File.open(reference_path), filename: "pursuit_answered.pdf", content_type: "application/pdf")
end

puts "Atividade pronta: #{activity.name} (#{activity.total_points.to_i} pts)"

# Conta de acesso em desenvolvimento (definida no .env; em produção use bin/rails "usuarios:criar[...]").
if (email = ENV["ADMIN_EMAIL"]).present? && (password = ENV["ADMIN_PASSWORD"]).present?
  user = User.find_or_initialize_by(email: email.downcase)
  user.update!(name: ENV.fetch("ADMIN_NAME", "Professora"), password: password)
  puts "Conta de acesso: #{user.email}"
end
