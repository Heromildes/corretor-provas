# Corretor de Provas com IA

Corrige automaticamente a atividade **"The Pursuit of Happyness – Employability Skills in Action"** (Instituto Ivoti) com o modelo `gpt-6-luna` da OpenAI. A professora arrasta as provas dos alunos (PDF digitado, PDF escaneado ou foto do celular), e a IA lê cada uma e dá nota por bloco. Os erros aparecem destacados no texto, tudo em tempo real.

## Notas
| Bloco | Pontos |
|---|---|
| 8 habilidades da tabela | 5 cada (40) |
| 2 perguntas pessoais (strongest / weakest) | 30 cada (60) |
| **Total** | **100** |

Conceito: **NS** 0–59 · **R** 60–74 · **B** 75–89 · **MB** 90–100.

## Como rodar
```bash
bundle install
cp .env.example .env        # coloque sua OPENAI_API_KEY
bin/rails db:prepare db:seed
bin/dev                     # http://localhost:3000  (PORT=3100 bin/dev para outra porta)
```
O `bin/dev` sobe 3 processos: o servidor web, o Tailwind e os **jobs** (Solid Queue), que fazem a correção. As atualizações ao vivo chegam pelo Solid Cable (Turbo Streams).

Dependências do sistema: `poppler` (`pdftotext`/`pdftoppm`) e `imagemagick` (com `libheif` para fotos HEIC de iPhone).

## Login
Todas as páginas, os arquivos das provas e as atualizações em tempo real exigem login (Devise).
- **Não existe cadastro pela tela.** As contas são criadas pelo terminal:
  ```bash
  bin/rails "usuarios:criar[professora@escola.com.br,Nome da Professora]"   # gera e mostra uma senha forte
  SENHA=minhasenha123 bin/rails "usuarios:criar[professora@escola.com.br]"   # ou define a senha
  bin/rails usuarios:listar
  bin/rails "usuarios:desbloquear[professora@escola.com.br]"
  ```
- Em desenvolvimento, `bin/rails db:seed` cria a conta definida em `ADMIN_EMAIL`/`ADMIN_PASSWORD` no `.env`.
- **Bloqueio:** depois de 20 senhas erradas, a conta fica bloqueada por 30 minutos e libera sozinha. Também há um limite de 50 tentativas por IP a cada 30 minutos.

## Visual
O padrão visual segue o `REDESIGN.md` (classes `cw-*` em `app/assets/tailwind/cw-v2.css`):
- cor principal fúcsia (botões e destaques), sem sidebar: a página usa a largura total;
- tema claro como padrão, com botão para alternar para o escuro;
- status mostrado como ponto colorido mais texto;
- ações secundárias no menu "⋯".

## Como funciona
1. `PageExtractor` (`app/services/page_extractor.rb`) extrai o texto do PDF e gera imagens JPEG de cada página. Fotos são giradas conforme o EXIF e redimensionadas.
2. `AiGrader` (`app/services/ai_grader.rb`) envia rubrica, texto e imagens para a Responses API com **JSON Schema estrito**. A resposta traz, para cada bloco: transcrição, nota, feedback, pontos fortes e erros (trecho literal, tipo, explicação e sugestão).
3. `GradeSubmissionJob` grava o resultado. Os modelos enviam as atualizações via Turbo Stream para a lista da turma e para a página do aluno.
4. A professora pode ajustar qualquer nota (de 0,5 em 0,5). O total e o conceito são recalculados na hora.

A rubrica fica no banco (`Activity#rubric`), definida em `db/seeds.rb`. O PDF respondido (`db/reference/pursuit_answered.pdf`) é usado como referência de qualidade, não como gabarito literal.

## Testes
```bash
bin/rails test
```
Os testes usam uma resposta gravada da OpenAI (`test/fixtures/files/openai_response.json`) e não gastam créditos.
Para testar a interface sem a API, rode `OPENAI_FAKE_RESPONSE=test/fixtures/files/openai_response_full.json bin/dev`. Isso só funciona fora de produção.
