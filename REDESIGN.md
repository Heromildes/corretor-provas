# REDESIGN.md — como levar uma tela do CW Hub para o novo visual

Guia para redesenhar as telas do `web/` (Vue 3 + Tailwind v4 + shadcn-vue) no visual novo do CW Hub.
A referência pronta é **`/admin/processos`** (índice, detalhe, novo/editar, modais) e o **shell**
(sidebar + barra superior). Na dúvida, abra esses arquivos e copie o padrão:

| Tela | Arquivo |
|---|---|
| Índice | `web/src/pages/admin/administrativo/ProcessosIndex.vue` |
| Detalhe | `web/src/pages/admin/administrativo/ProcessoShow.vue` |
| Formulário | `web/src/pages/admin/administrativo/ProcessoForm.vue` |
| Modais | `web/src/components/admin/processos/{EtapaDialog,ProcessoStatusDialog,RelatorioWizard}.vue` |
| Shell | `web/src/layouts/AdminLayout.vue`, `web/src/components/admin/AppSidebar.vue` |

**Estado:** todas as telas do admin já estão no v2 (processos, painel, estoque, colaboradores, clientes, ativos,
cadastros, perfil, menu, consultar CNPJ, 404/em breve e o conteúdo do shell: busca ⌘K, notificações, seletor de área). A vitrine viva
de componentes e classes fica em **`/admin/_design`** (`web/src/pages/admin/Design.vue`) — confira lá antes de criar
classe nova. Referências mais recentes por tipo: índice com filtros `UsersIndex.vue`/`ativos/ItemsIndex.vue`;
detalhe `UserShow.vue`/`ativos/ItemShow.vue`; formulário longo `UserForm.vue`/`ativos/ItemForm.vue`; upload
`estoque/ListagemImport.vue`/`ativos/ItemsImport.vue`.

A base veio do redesign do kapiva-faculdades (`kapiva-faculdades/REDESIGN.md`, `kapiva_ui_v2*.css`), mas
**o gosto do CW é mais minimalista** — as regras abaixo são as que valem aqui.

---

## 1. O gosto do CW (leia antes de tudo)

Estas preferências saíram das revisões da tela de processos. Elas mandam sobre qualquer padrão herdado.

1. **Minimalista, mas bonito.** Fundo limpo, bordas finas (1px `--cw-line`), quase sem sombra, bastante
   respiro. Nada de "caixinha dentro de caixinha", pílulas coloridas em tudo ou cartões navy pesados.
   A primeira versão (chips coloridos, anel de progresso, cartão hero navy, faixa colorida na lateral do
   cartão) foi considerada **poluída**.
2. **Cor só onde informa.** Status = **ponto colorido + texto** (`cw-status`), não pílula preenchida.
   Prazo normal = texto comum; **vencido em vermelho**, **perto do prazo em laranja**.
3. **Ícones, sim — discretos.** Ícone pequeno (≈15px, opacidade ~75%) ao lado do dado: prazo
   (`CalendarClock`), cliente (`Building2`), filial (`MapPin`), responsável (`User`), datas (`Calendar`).
   Filtros também levam ícone (ver §4). Tirar os ícones foi rejeitado.
4. **O ícone do item tem a cor da situação.** Na lista e no topo do detalhe, o ícone do registro fica:
   🟢 verde se concluído → 🔴 vermelho se vencido → 🟠 laranja se perto do prazo → senão a cor do status.
   (`processoTone()` em `lib/status.ts`; replique a ideia para cada recurso.)
5. **Cores da marca = cores do logo.**
   - **Verde-petróleo `#1a454c`** (o "W" do logo) → **ações principais e de edição**:
     botão principal da página (`cw-btn--teal`, ex.: "Nova etapa") e editar (`cw-btn--teal-outline`).
   - **Dourado `#e8c34a`** (família do "C", que no logo é `#b5a282`) → **destaques**: item ativo da
     sidebar, barra de progresso, eyebrow do cabeçalho, links de ação de relatório.
   - Dois botões lado a lado **não podem ter a mesma cor** (o par dourado sólido + dourado claro foi rejeitado).
   - Pendente: o "Novo processo" do índice ainda é dourado (`cw-btn--solid`); a tendência é usar
     `cw-btn--teal` nas ações principais. Confirme com o usuário antes de trocar em massa.
6. **Sem botão de voltar no detalhe.** O breadcrumb da barra superior já faz isso.
7. **Ações secundárias escondidas até importar.** Na lista: a linha inteira abre o registro e
   Ver/Editar/Excluir ficam num menu **"⋯"** que aparece no hover. No detalhe: editar/excluir de cada
   item aparecem no hover (`cw-reveal`; sempre visíveis em telas de toque).
8. **Ações em texto, não em botão-caixa**, dentro de cartões: `cw-link-btn` ("Concluir", "Gerar relatório").
9. **Não mexer no que já funciona.** Ex.: paginação — a lista já carrega a próxima página ao rolar
   (20 por página, `useInfiniteQuery` + `useIntersectionObserver`); não alterar sem pedido explícito.
10. **Escuro é o padrão**, mas tudo tem que ficar bom nos dois temas e no celular.

---

## 2. Arquitetura de estilos

- **`web/src/styles/cw-v2.css`** — tokens + componentes, importado em `style.css` **fora de `@layer`**
  (vence os utilitários do Tailwind/shadcn nos elementos onde é aplicado, sem `!important`).
- Prefixo **`cw-*`**. A parte **minimalista** (a preferida) está no fim do arquivo, classes `cw-m*`.
  As classes do começo (`cw-card`, `cw-table`, `cw-chip`, `cw-hero`, `cw-ring`, `cw-tl-*`…) são da
  primeira versão, mais "cheia" — use só se fizer sentido; o padrão agora é `cw-m*`.
- **Escopo**: a raiz da página leva `class="cw-v2 cw-page cw-mpage"` (Poppins, peso ≥ 500, largura
  máx. 76rem centralizada). Páginas não migradas continuam com Geist + shadcn puro.
- Shell (sidebar `.cw-shell`, barra `.cw-topbar`) já é v2 em todas as páginas.

### Tokens

| Token | Uso |
|---|---|
| `--cw-bg`, `--cw-surface`, `--cw-surface-2`, `--cw-surface-alt` | fundo da página, cartão, hover, campos |
| `--cw-line`, `--cw-line-strong` | bordas e divisórias |
| `--cw-ink`, `--cw-ink-soft`, `--cw-muted` | título, corpo, secundário (o mais claro permitido) |
| `--res`, `--res-soft`, `--res-ink`, `--res-grad`, `--on-res` | dourado de destaque (texto sobre ele = navy) |
| `--cw-gold-strong` | dourado legível no tema claro (pontos/ícones de status) |
| `--cw-teal`, `--cw-teal-grad`, `--cw-teal-soft`, `--cw-teal-ink` | verde-petróleo do logo |
| `--cw-success`, `--cw-info`, `--cw-warning`, `--cw-danger`, `--cw-purple` (+ `-soft`) | estados |

Todos têm variante em `.dark` (o tema é a classe `dark` no `<html>`). Nunca use cor fixa de
texto/fundo sem a variante escura.

---

## 3. Componentes Vue reutilizáveis (`web/src/components/admin/v2/`)

- **`CwModal.vue`** — modal no desktop, *bottom sheet* no celular. Props: `open`, `title`, `subtitle`,
  `size` (`sm`/`md`/`wide`/`lg`), `dismissable` (falso enquanto processa). Slots: `icon`, `eyebrow`,
  `subtitle`, padrão (corpo rolável), `actions` (rodapé). Use `form="id"` nos botões do rodapé.
- **`CwEmpty.vue`** — estado vazio (ícone sobre círculos, título, texto, CTAs no slot). `tone="danger"` para erro.
- **`CwPageHead.vue`** — cabeçalho da 1ª versão (mais pesado); no padrão minimalista use `cw-mhead` (§4).
- **`ConfirmDialog.vue`** (global, já v2) — aviso centralizado com ícone; `destructive` deixa vermelho.

Helpers em **`web/src/lib/status.ts`**: `toneColor[tone]` (cor sólida p/ ponto/ícone),
`toneChip(tone)`, `prazoAnualTone(dias)`, `processoTone(status, dias)`, `processoStatusIcon[status]`.
Crie equivalentes por recurso (ex.: `itemTone`) seguindo o mesmo formato.

---

## 4. Tela de índice (padrão)

```vue
<div class="cw-v2 cw-page cw-mpage">
  <header class="cw-mhead">
    <div class="cw-mhead__lead">
      <span class="cw-mhead__icon"><GitBranchIcon /></span>
      <div>
        <h1 class="cw-mhead__title">Processos</h1>
        <p class="cw-mhead__sub">5 processos</p>
      </div>
    </div>
    <RouterLink class="cw-btn cw-btn--teal cw-btn--sm"><PlusIcon /> Novo …</RouterLink>
  </header>

  <div class="cw-mbar">
    <div class="cw-seg" role="group" aria-label="Status">   <!-- filtros em texto, com ícone -->
      <button :aria-pressed="…" :style="{ '--tone': toneColor[tone] }"><Icon /> Pendente</button>
    </div>
    <div class="cw-mbar__right">
      <div class="cw-msearch" role="search"><SearchIcon /><input type="search" /></div>
      <label class="cw-msort"><select>…</select><ChevronDownIcon /></label>
    </div>
  </div>

  <div class="cw-mlist">
    <table class="cw-mtable hidden md:table">…</table>   <!-- desktop -->
    <ul class="cw-mrows md:hidden">…</ul>                <!-- celular -->
  </div>
  <div class="cw-mfoot">20 de 57 · Carregar mais</div>
</div>
```

- **Filtros** (`cw-seg`): texto + ícone na cor do status (`--tone`). Ícones de status de processo:
  Todos `LayoutList`, Pendente `CircleDashed`, Em andamento `CircleDotDashed`, Concluído `CircleCheck`,
  Pausado `CirclePause`.
- **Coluna principal**: `cw-mitem` = ícone `cw-mitem__icon` (com `--tone` da situação) + `cw-mname`
  (link) + `cw-msub` (cliente · data).
- **Status**: `<span class="cw-status" :style="{ '--dot': toneColor[tone] }">Em andamento</span>`.
- **Progresso**: `cw-mprog` (barra fina `cw-mprog__bar` + "1/4"; `.is-done` fica verde).
- **Prazo**: `<span class="cw-ico-text"><CalendarClockIcon /> Restam 30 dias</span>`, com
  `cw-text-danger` / `cw-text-warning` só quando vencido/perto.
- **Pessoa**: `cw-person` + `cw-avatar` (iniciais).
- **Ações**: linha clicável (`@click` que ignora cliques em `a, button`) + menu "⋯" (`cw-dots cw-reveal`
  com `DropdownMenu` do shadcn; conteúdo com `class="cw-v2"`).
- Colunas menos importantes somem em telas menores (`hidden lg:table-cell`, `hidden xl:table-cell`).
- Carregamento: esqueleto com `cw-skel`. Vazio/erro: `CwEmpty`.

## 5. Tela de detalhe (padrão)

- **Cabeçalho `cw-mshead`** (sem voltar): eyebrow `cw-mshead__eyebrow` com ícone na cor da situação
  (`cw-mhead__icon cw-mhead__icon--xs cw-mhead__icon--tone`) → título `cw-mshead__title` (h1) →
  linha `cw-mshead__meta` com o **status clicável** (`cw-status-btn`, abre o modal de status) e os dados
  com ícone (`cw-ico-text`, separados por `cw-mshead__sep`) → descrição `cw-mshead__desc`.
  Ações à direita em `cw-mshead__actions` (Editar = `cw-btn--teal-outline`).
- **Layout `cw-show-grid`**: conteúdo à esquerda + coluna de resumo à direita (sticky; no celular vem antes).
- **Resumo `cw-msummary`**: um único cartão — rótulo, número grande (`cw-msummary__big`), barra fina,
  e a lista `cw-mdl` (`dt` com ícone `cw-ico-text` à esquerda, valor à direita).
- **Seção** `cw-msection-head` (título + contagem em `small` + ação principal `cw-btn--teal`) e
  legenda `cw-mlegend` (pontos pequenos, texto cinza).
- **Linha do tempo `cw-mtl`**: nó numerado `cw-mtl-node` (✓ verde quando concluído; borda colorida se
  atrasado/perto) + cartão `cw-mtl-card` (topo: "Etapa N · Departamento" + status em ponto; título h3;
  ações em linha: data `cw-mdate`, `cw-link-btn--success` "Concluir", `cw-mdivider`,
  `cw-link-btn--res` relatório, e `cw-mtl-card__tools cw-reveal` com editar/excluir).

## 6. Formulários e modais

- Página de formulário: `cw-formpage` + `cw-card` + `<form class="cw-form">`. Dentro de `.cw-form` os
  `Input`/`NativeSelect`/`Textarea`/combobox do shadcn já ficam no visual v2. Rótulo `cw-label`
  (ou `Label` do shadcn), dica `cw-hint`, erro `cw-error`, duas colunas `cw-grid-2`,
  rodapé `cw-form__actions`.
- Escolha única (status etc.): `cw-choice` (rádios em pílula; `cw-choice--stack` empilhado).
- Modais: sempre `CwModal`; cancelar = `cw-btn--secondary`, ação = botão principal; excluir à esquerda
  com `cw-btn--danger-soft cw-modal__actions-start`.
- Wizard: `cw-steps` / `cw-step` (`is-current`, `is-done`), resumo `cw-note`, erro `cw-alert`,
  carregando `cw-busy`.
- Popover de busca (picker): `cw-picker` (+ `__search`, `__list`, `__option`).
- *Ainda não passaram pela revisão minimalista* (§1): o formulário e os modais de processos estão na
  1ª versão. Ao migrar outras telas, aplique a eles o mesmo enxugamento.

## 7. Botões — resumo

| Classe | Quando |
|---|---|
| `cw-btn--teal` | ação principal da página/seção ("Nova etapa", "Criar", "Salvar") |
| `cw-btn--teal-outline` | editar / ação secundária de destaque |
| `cw-btn--solid` (dourado) | legado da 1ª versão — evitar ao lado de outro dourado |
| `cw-btn--secondary` | cancelar, neutro |
| `cw-btn--ghost` | ação discreta no cabeçalho (ex.: baixar relatório) |
| `cw-btn--danger` / `--danger-soft` | excluir (confirmação / dentro de modal) |
| `cw-link-btn` (`--success`, `--res`, `--danger`, `--icon`) | ações em texto dentro de cartões |
| `cw-dots` + `cw-reveal` | menu "⋯" da linha |
| Tamanhos | `cw-btn--sm` (padrão nas telas), `cw-btn--xs` |

---

## 8. Armadilhas

- **CSS sem layer vence o Tailwind.** Uma classe `cw-*` que define `display` anula `hidden`/`md:hidden`
  no mesmo elemento (a lista de celular apareceu no desktop por isso). Ponha a visibilidade num wrapper,
  use uma classe `cw-*` que não defina `display`, ou `hidden!`.
- **Especificidade**: `.cw-mtable td` vence `.cw-text-danger` sozinho — por isso as classes de cor são
  `.cw-v2 .cw-text-*`. Ao criar cores de texto, prefixe com `.cw-v2`.
- **Dourado no tema claro** some sobre fundo claro: para pontos/ícones use `toneColor.gold`
  (`--cw-gold-strong`), não `--res`.
- **`input type=date`**: o ícone nativo duplica o nosso; em `cw-mdate` ele é escondido e o clique chama
  `showPicker()`.
- **Teleport**: modais, dropdowns e popovers saem da árvore — ponha `cw-v2` no conteúdo deles.
- **`<input type="search">`** tem papel `searchbox` (não `textbox`) — os E2E usam `getByRole('searchbox', …)` nas
  buscas de lista; mantenha o tipo coerente com o teste.
- **Excluir à esquerda em formulário**: `cw-modal__actions-start` funciona também dentro de `cw-form__actions`
  (a regra de celular que estica o botão vale só no rodapé de modal).
- **Grades no celular**: `display: grid` sem `grid-template-columns: minmax(0, 1fr)` estoura a largura quando há
  texto `nowrap` dentro.
- **Testes E2E** (`web/e2e/`): mantenha `id`s, `aria-label`s e textos que eles usam (ex.:
  `#processo-cliente`, "Nova etapa", "Gerar relatório", diálogo "Gerar relatório de contagem",
  `#wizard-arquivo`). O título da etapa (h3) precisa ser **filho direto** do `article` que contém os botões
  (o teste pega o elemento mais interno que contém o heading). Antes de renomear algo:
  `grep -rn "texto" web/e2e`.

---

## 9. Checklist de entrega

1. Raiz `cw-v2 cw-page cw-mpage`; cabeçalho `cw-mhead` (índice) ou `cw-mshead` (detalhe, sem voltar).
2. Status em ponto; cor só para alerta; ícones discretos nos dados; ícone do item na cor da situação.
3. Ação principal verde-petróleo; nenhum par de botões com a mesma cor.
4. Ações secundárias no "⋯"/hover; linha clicável.
5. Modais em `CwModal`/`ConfirmDialog`.
6. Conferido em **escuro e claro**, **1440px e 390px** (ver abaixo).
7. `pnpm -s typecheck`, `pnpm -s lint`, `pnpm -s test` em `web/` — e os E2E da tela se mexeu em textos/ids.

**Como conferir rápido**: com a API (`cargo loco start`, porta 5165, banco de demo) e o Vite (5173)
rodando, um script Node com o Playwright de `web/node_modules` faz login com o admin de `.demo-admin`,
define a área (`PATCH /api/admin/hub_area` com o cookie `cw_csrf` no header `X-CSRF-Token`), troca o tema
via `localStorage['cw-theme']` e tira screenshots das telas e dos modais.
