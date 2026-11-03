require "open3"

# Converte o arquivo enviado (PDF digitado, PDF escaneado ou foto) em:
#   - texto extraído (quando o PDF tem camada de texto)
#   - imagens JPEG de cada página (para a IA "ver" a prova e para a tela de revisão)
class PageExtractor
  class Error < StandardError; end

  MAX_PAGES = 6
  DPI = 150
  MAX_SIDE = 2000

  Result = Data.define(:text, :images) do
    # Texto "útil": ignora linhas de sublinhado e espaços. Pouco texto = provável PDF escaneado.
    def text_layer?
      text.to_s.gsub(/[_\s]/, "").length > 200
    end
  end

  def initialize(attachment)
    @attachment = attachment
  end

  # Retorna Result com images = [Pathname] dentro de um diretório temporário (apagado após o bloco).
  def call
    Dir.mktmpdir("prova") do |dir|
      @attachment.blob.open(tmpdir: dir) do |file|
        result = pdf? ? from_pdf(file.path, dir) : from_image(file.path, dir)
        raise Error, "Não consegui ler nenhuma página do arquivo." if result.images.empty?
        return yield(result)
      end
    end
  end

  private

  def pdf?
    @attachment.blob.content_type == "application/pdf"
  end

  def from_pdf(path, dir)
    pages = run("pdfinfo", path).first[/^Pages:\s+(\d+)/, 1].to_i
    if pages > MAX_PAGES
      raise Error, "O arquivo tem #{pages} páginas (máximo #{MAX_PAGES}). Envie um arquivo por aluno."
    end
    text, = run("pdftotext", "-layout", "-l", MAX_PAGES.to_s, path, "-")
    run("pdftoppm", "-r", DPI.to_s, "-l", MAX_PAGES.to_s, "-jpeg", "-jpegopt", "quality=85", path, File.join(dir, "page"))
    images = Dir[File.join(dir, "page-*.jpg")].sort_by { |f| f[/(\d+)\.jpg\z/, 1].to_i }.map { |f| Pathname(f) }
    Result.new(text: text.to_s.gsub("​", "").strip, images: images)
  end

  def from_image(path, dir)
    output = File.join(dir, "page-1.jpg")
    run(imagemagick, path, "-auto-orient", "-resize", "#{MAX_SIDE}x#{MAX_SIDE}>", "-strip", "-quality", "85", output)
    Result.new(text: "", images: [ Pathname(output) ])
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
