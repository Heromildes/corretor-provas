require "test_helper"

class PageExtractorTest < ActiveSupport::TestCase
  Upload = Struct.new(:blob)

  def upload(path, content_type)
    Upload.new(ActiveStorage::Blob.create_and_upload!(io: File.open(path), filename: File.basename(path), content_type: content_type))
  end

  test "PDF digitado: extrai texto e gera uma imagem por página" do
    PageExtractor.new(upload(ANSWERED_PDF, "application/pdf")).call do |result|
      assert result.text_layer?
      assert_includes result.text, "Dean Witter"
      assert_equal 2, result.images.size
      assert result.images.all? { File.size(_1) > 10_000 }
    end
  end

  test "foto: normaliza para JPEG sem camada de texto" do
    Dir.mktmpdir do |dir|
      system("pdftoppm", "-r", "60", "-f", "1", "-l", "1", "-png", ANSWERED_PDF.to_s, File.join(dir, "foto"), exception: true)
      photo = Dir[File.join(dir, "foto*.png")].first
      PageExtractor.new(upload(photo, "image/png")).call do |result|
        assert_not result.text_layer?
        assert_equal 1, result.images.size
        assert result.images.first.to_s.end_with?(".jpg")
      end
    end
  end

  test "arquivo corrompido gera erro amigável" do
    Dir.mktmpdir do |dir|
      bad = File.join(dir, "ruim.pdf")
      File.write(bad, "não é pdf")
      assert_raises(PageExtractor::Error) do
        PageExtractor.new(upload(bad, "application/pdf")).call { flunk "não deveria chegar aqui" }
      end
    end
  end

  test "PDF com páginas demais (turma inteira num arquivo) é recusado" do
    Dir.mktmpdir do |dir|
      many = File.join(dir, "turma.pdf")
      system("pdfunite", *([ ANSWERED_PDF.to_s ] * 4), many, exception: true)
      error = assert_raises(PageExtractor::Error) do
        PageExtractor.new(upload(many, "application/pdf")).call { flunk "não deveria chegar aqui" }
      end
      assert_match "8 páginas", error.message
    end
  end
end
