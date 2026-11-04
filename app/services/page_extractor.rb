require "open3"

# Converte os arquivos de UM aluno (PDF digitado, PDF escaneado, fotos de frente e verso…) em:
#   - texto extraído (só de PDFs com camada de texto)
#   - imagens JPEG de cada página, na ordem do envio (para a IA "ver" a prova e para a tela de revisão)
class PageExtractor
  class Error < StandardError; end

  MAX_PAGES = 8
  DPI = 150
  MAX_SIDE = 2000

  Result = Data.define(:text, :images) do
    # Texto "útil": ignora linhas de sublinhado e espaços. Pouco texto = provável escaneado/foto.
    def text_layer?
      text.to_s.gsub(/[_\s]/, "").length > 200
    end
  end

  # Aceita um anexo, uma lista de anexos ou uma coleção has_many_attached.
  def initialize(attachments)
    @attachments = attachments.respond_to?(:attachments) ? attachments.attachments.to_a : Array.wrap(attachments)
  end

  # Entrega um Result ao bloco; as imagens ficam num diretório temporário apagado no fim.
  def call
    Dir.mktmpdir("prova") do |dir|
      texts = []
      images = []
      @attachments.each_with_index do |attachment, index|
        attachment.blob.open(tmpdir: dir) do |file|
          prefix = File.join(dir, format("arq%02d", index))
          if attachment.blob.content_type == "application/pdf"
            text, pages = from_pdf(file.path, prefix, remaining: MAX_PAGES - images.size)
            texts << text if text.present?
            images.concat(pages)
          else
            images << from_image(file.path, prefix)
          end
        end
        raise Error, "São mais de #{MAX_PAGES} páginas. Envie só as páginas de um aluno por vez." if images.size > MAX_PAGES
      end
      raise Error, "Não consegui ler nenhuma página dos arquivos." if images.empty?

      return yield(Result.new(text: texts.join("\n\n").strip, images: images))
    end
  end

  private

  def from_pdf(path, prefix, remaining:)
    pages = run("pdfinfo", path).first[/^Pages:\s+(\d+)/, 1].to_i
    if pages > remaining
      raise Error, "O envio tem mais de #{MAX_PAGES} páginas (este PDF tem #{pages}). Envie só as páginas de um aluno por vez."
    end

    text, = run("pdftotext", "-layout", path, "-")
    run("pdftoppm", "-r", DPI.to_s, "-jpeg", "-jpegopt", "quality=85", path, prefix)
    images = Dir["#{prefix}-*.jpg"].sort_by { |f| f[/(\d+)\.jpg\z/, 1].to_i }.map { |f| Pathname(f) }
    [ text.to_s.gsub("​", "").strip, images ]
  end

  def from_image(path, prefix)
    output = "#{prefix}-1.jpg"
    run(imagemagick, path, "-auto-orient", "-resize", "#{MAX_SIDE}x#{MAX_SIDE}>", "-strip", "-quality", "85", output)
    Pathname(output)
  end

  # ImageMagick 7 usa `magick`; o 6 (Debian/Ubuntu) usa `convert`.
  def imagemagick
    @imagemagick ||= ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, "magick")) } ? "magick" : "convert"
  end

  def run(*cmd)
    stdout, stderr, status = Open3.capture3(*cmd)
    raise Error, "Falha ao processar o arquivo (#{cmd.first}): #{stderr.strip.truncate(200)}" unless status.success?
    [ stdout, stderr ]
  rescue Errno::ENOENT
    raise Error, "Ferramenta '#{cmd.first}' não encontrada no servidor."
  end
end
