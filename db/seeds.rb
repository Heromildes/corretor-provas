# Atividade base: "The Pursuit of Happyness – Employability Skills in Action"
# 8 blocos da tabela (5 pts cada) + 2 perguntas pessoais (30 pts cada) = 100 pts.

# Cada critério tem NÍVEIS FIXOS e descritos. A IA escolhe um nível por critério e o sistema soma:
# assim a mesma prova recebe (quase) sempre a mesma nota.
table_criteria = [
  { key: "cena", label: "Cena do filme", levels: [
    { points: 0, desc: "Sem exemplo, exemplo inventado ou que não acontece no filme." },
    { points: 1, desc: "Exemplo vago/genérico (ex.: 'ele trabalha duro') ou com detalhe incorreto do enredo." },
    { points: 2, desc: "Cena ou ação real e correta do filme." }
  ] },
  { key: "ligacao", label: "Ligação com a habilidade", levels: [
    { points: 0, desc: "O exemplo não tem relação com esta habilidade." },
    { points: 0.5, desc: "Relação fraca ou só implícita." },
    { points: 1, desc: "Relação clara com a habilidade." },
    { points: 1.5, desc: "Relação clara E nomeia a característica específica (ex.: honestidade, empatia, gestão do tempo)." }
  ] },
  { key: "detalhe", label: "Detalhe", levels: [
    { points: 0, desc: "Frase genérica, sem situação concreta." },
    { points: 0.5, desc: "Algum detalhe da situação." },
    { points: 1, desc: "Cena específica e bem descrita (o que, quando, como)." }
  ] },
  { key: "ingles", label: "Inglês", levels: [
    { points: 0, desc: "Dois ou mais erros, ou um erro que atrapalha a compreensão." },
    { points: 0.5, desc: "Claro, com no máximo um erro leve." }
  ] }
]

open_criteria = [
  { key: "identificacao", label: "Duas habilidades", levels: [
    { points: 0, desc: "Nenhuma habilidade válida da lista." },
    { points: 3, desc: "Só uma habilidade válida (ou uma das duas não é da lista)." },
    { points: 6, desc: "Duas habilidades válidas da lista, claramente nomeadas." }
  ] },
  { key: "justificativa", label: "Justificativa com cenas", levels: [
    { points: 0, desc: "Sem justificativa." },
    { points: 3, desc: "Justificativa genérica, sem cenas do filme." },
    { points: 6, desc: "Só uma habilidade com cena concreta, ou as duas com cenas vagas." },
    { points: 9, desc: "As duas com cenas concretas, mas uma pouco desenvolvida ou com detalhe impreciso." },
    { points: 12, desc: "As duas com cenas concretas, corretas e bem explicadas." }
  ] },
  { key: "analise", label: "Análise pessoal", levels: [
    { points: 0, desc: "Sem opinião ou análise." },
    { points: 2, desc: "Opinião superficial, sem argumento." },
    { points: 4, desc: "Opinião coerente com alguma reflexão." },
    { points: 6, desc: "Reflexão pessoal clara, bem argumentada e convincente." }
  ] },
  { key: "ingles", label: "Inglês", levels: [
    { points: 0, desc: "Incompreensível." },
    { points: 2, desc: "Muitos erros que atrapalham a leitura." },
    { points: 4, desc: "Erros frequentes, mas compreensível." },
    { points: 5, desc: "Poucos erros (até 3) e boa organização." },
    { points: 6, desc: "Praticamente sem erros, bem organizado e coeso." }
  ] }
]

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
  { key:, title:, kind: "table", max_points: 5, focus:, criteria: table_criteria, notes: "Em branco ou ilegível = 0 em todos os critérios." }
end

rubric << {
  key: "strongest", kind: "open", max_points: 30,
  title: "1. Two strongest skills",
  question: "In your opinion, which two employability skills was Chris the strongest? Explain your response.",
  criteria: open_criteria,
  notes: "Em branco = 0 em todos os critérios."
}
rubric << {
  key: "weakest", kind: "open", max_points: 30,
  title: "2. Two weakest skills",
  question: "In your opinion, which two employability skills was Chris the weakest? Explain your response.",
  criteria: open_criteria,
  notes: "Em branco = 0 em todos os critérios. É uma pergunta de opinião: aceite qualquer escolha bem fundamentada com cenas do filme."
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
