module ApplicationHelper
  # ---------- Tons (cor só onde informa) ----------
  # Variáveis CSS do cw-v2.css usadas em pontos, ícones e barras.
  TONE_VARS = {
    success: "var(--cw-success)", info: "var(--cw-info)", warning: "var(--cw-warning)",
    danger: "var(--cw-danger)", purple: "var(--cw-purple)", gold: "var(--cw-gold-strong)", muted: "var(--cw-muted)"
  }.freeze

  CONCEPT_TONES = { "MB" => :success, "B" => :info, "R" => :warning, "NS" => :danger }.freeze

  def tone_var(tone) = TONE_VARS.fetch(tone.to_sym, TONE_VARS[:muted])
  def concept_tone(code) = CONCEPT_TONES.fetch(code.to_s, :muted)

  # Cor da prova: falhou → vermelho; em andamento → azul; corrigida → cor do conceito.
  def submission_tone(submission)
    return :danger if submission.failed?
    return :info if submission.processing?
    concept_tone(submission.concept)
  end

  # Cor da turma: falha → vermelho; corrigindo → azul; tudo pronto → verde; vazia → cinza.
  def batch_tone(stats)
    return :danger if stats.failed.positive?
    return :info if stats.processing.positive?
    return :success if stats.finished?
    :muted
  end

  # Faixa do bloco pela proporção da nota (mesmas faixas do conceito).
  def ratio_tone(ratio) = concept_tone(Grading.concept_for(ratio * 100))

  def status_dot(label, tone, live: false, **options)
    tag.span(label, **options, class: [ "cw-status", ("is-live" if live), options[:class] ],
      style: "--dot: #{tone_var(tone)}")
  end

  def concept_status(code, long: false)
    return tag.span("—", class: "cw-text-muted") if code.blank?
    status_dot(long ? "#{code} · #{Grading.label_for(code)}" : code, concept_tone(code), title: Grading.label_for(code))
  end

  def submission_status(submission)
    tone = case submission.status
    when "done" then :success
    when "failed" then :danger
    when "queued" then :muted
    else :info
    end
    status_dot(submission.status_label, tone, live: submission.processing?)
  end

  def points(value)
    return "—" if value.nil?
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def percent(part, whole)
    whole.to_d.zero? ? 0 : (part.to_d * 100 / whole.to_d).round(1).clamp(0, 100)
  end

  # ---------- Breadcrumb da barra superior ----------
  def breadcrumbs(*crumbs)
    content_for(:breadcrumbs) do
      safe_join(crumbs.each_with_index.map do |(label, path), index|
        last = index == crumbs.size - 1
        piece = last || path.nil? ? tag.span(label, "aria-current": ("page" if last)) : link_to(label, path)
        separator = index.zero? ? "".html_safe : icon(:chevron_right)
        hide = !last && index.positive? && crumbs.size > 2
        hide ? tag.span(separator + piece, class: "cw-crumbs__hide-sm") : separator + piece
      end)
    end
  end

  # ---------- Destaques de erro na resposta do aluno ----------
  def highlight_transcription(item)
    text = item.transcription.to_s
    return tag.p("Sem resposta.", class: "cw-quote is-empty") if text.blank?

    ranges = []
    item.issue_list.each_with_index do |issue, index|
      quote = issue[:quote].to_s.strip
      next if quote.length < 2
      start = text.index(quote) || text.downcase.index(quote.downcase)
      next unless start
      finish = start + quote.length
      next if ranges.any? { |r| start < r[:finish] && finish > r[:start] }
      ranges << { start:, finish:, issue:, index: }
    end
    ranges.sort_by! { |r| r[:start] }

    html = +""
    cursor = 0
    ranges.each do |r|
      html << ERB::Util.html_escape(text[cursor...r[:start]])
      html << issue_mark(text[r[:start]...r[:finish]], r[:issue], r[:index], item)
      cursor = r[:finish]
    end
    html << ERB::Util.html_escape(text[cursor..])
    tag.p(html.html_safe, class: "cw-quote")
  end

  ISSUE_TONES = { "grammar" => :danger, "spelling" => :warning, "vocabulary" => :purple, "content" => :info, "incomplete" => :muted }.freeze

  def issue_tone(kind) = ISSUE_TONES.fetch(kind.to_s, :muted)

  def issue_mark(fragment, issue, index, item)
    kind = issue[:kind].to_s
    tooltip = tag.span(class: "issue-tip", role: "tooltip") do
      tag.span(SubmissionItem::ISSUE_KINDS[kind] || kind, class: "issue-tip-kind") +
        tag.span(issue[:explanation]) +
        (issue[:suggestion].present? ? tag.span("→ #{issue[:suggestion]}", class: "issue-tip-fix") : "".html_safe)
    end
    tag.mark(class: "issue issue-#{kind}", tabindex: 0, data: { issue_target: "#{dom_id(item)}_issue_#{index}" }) do
      ERB::Util.html_escape(fragment) + tooltip
    end
  end

  # ---------- Ícones (traço estilo Lucide) ----------
  ICONS = {
    check: '<path d="M20 6 9 17l-5-5"/>',
    circle_check: '<circle cx="12" cy="12" r="9"/><path d="m8.5 12 2.5 2.5 4.5-5"/>',
    circle_alert: '<circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/>',
    circle_dashed: '<path d="M10.1 2.2a10 10 0 0 1 3.8 0M17.6 3.7a10 10 0 0 1 2.7 2.7M21.8 10.1a10 10 0 0 1 0 3.8M20.3 17.6a10 10 0 0 1-2.7 2.7M13.9 21.8a10 10 0 0 1-3.8 0M6.4 20.3a10 10 0 0 1-2.7-2.7M2.2 13.9a10 10 0 0 1 0-3.8M3.7 6.4a10 10 0 0 1 2.7-2.7"/>',
    loader: '<path d="M21 12a9 9 0 1 1-6.2-8.6"/>',
    upload: '<path d="M12 13v8M4 14.9A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.5 8.2"/><path d="m8 17 4-4 4 4"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    chevron_left: '<path d="m15 18-6-6 6-6"/>',
    chevron_right: '<path d="m9 18 6-6-6-6"/>',
    arrow_right: '<path d="M5 12h14M13 6l6 6-6 6"/>',
    download: '<path d="M12 15V3M7 10l5 5 5-5M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>',
    trash: '<path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6M10 11v6M14 11v6"/>',
    refresh: '<path d="M3 12a9 9 0 0 1 15.5-6.2L21 8M21 3v5h-5M21 12a9 9 0 0 1-15.5 6.2L3 16M3 21v-5h5"/>',
    sparkles: '<path d="M12 3 13.8 8.2 19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 15v4M17 17h4"/>',
    file_text: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>',
    files: '<path d="M15 2H9a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V7z"/><path d="M15 2v5h5M3 8v12a2 2 0 0 0 2 2h9"/>',
    print: '<path d="M6 9V3h12v6M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><path d="M6 14h12v8H6z"/>',
    pencil: '<path d="M21.2 6.8a2.8 2.8 0 0 0-4-4L4 16v4h4z"/><path d="m15 5 4 4"/>',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M6 21v-1a6 6 0 0 1 12 0v1"/>',
    layers: '<path d="m12 2 10 5-10 5L2 7z"/><path d="m2 17 10 5 10-5M2 12l10 5 10-5"/>',
    book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V2H6.5A2.5 2.5 0 0 0 4 4.5z"/><path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5"/>',
    calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    award: '<circle cx="12" cy="8" r="6"/><path d="M15.5 13 17 22l-5-3-5 3 1.5-9"/>',
    chart: '<path d="M3 3v18h18M7 16v-4M12 16V8M17 16v-7"/>',
    more: '<circle cx="5" cy="12" r="1.2"/><circle cx="12" cy="12" r="1.2"/><circle cx="19" cy="12" r="1.2"/>',
    zoom: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3M11 8v6M8 11h6"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"/>',
    log_out: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
    lock: '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
    mail: '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-10 6L2 7"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    grad: '<path d="M22 10 12 5 2 10l10 5z"/><path d="M6 12v5c3 2 9 2 12 0v-5"/>',
    logo: '<path d="M4 12.5 9.5 18 20 6.5" stroke-width="2.6"/>'
  }.freeze

  def icon(name, css = nil)
    tag.svg(ICONS.fetch(name).html_safe, class: css, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true)
  end
end
