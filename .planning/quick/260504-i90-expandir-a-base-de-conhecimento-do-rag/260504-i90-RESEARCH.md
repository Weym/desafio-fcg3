# Quick Task 260504-i90: Expandir a base de conhecimento do RAG - Research

**Researched:** 2026-05-04
**Domain:** RAG content optimization + Brazilian academic regulations
**Confidence:** HIGH

## Summary

The current knowledge base has 5 files totaling ~6,100 tokens (~17 chunks at 500-token chunk size). The `regulamento.md` is critically empty (85 tokens, 1 useless chunk), `documentos.md` doesn't exist, and there's a bug preventing `regulamento.md` from being ingested (`CATEGORY_MAP` references `regulamento.pdf`). The expansion plan is well-defined in `RAG_EXPANSION_PLAN.md`.

**Primary recommendation:** Write each markdown section to be 300-450 tokens (3 well-developed paragraphs in Portuguese) — this ensures sections map cleanly to individual chunks without being split mid-thought or merged with unrelated sections.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- Use real structures from Brazilian CS university programs (semestral system, 3000h+ carga horaria, aprovacao >= 5.0 or 7.0, 75% frequencia per LDB Art. 24) but with fictional institution name and dates
- Rules should be recognizable by a real CS student or professor as plausible/accurate
- Execute all 7 actions from RAG_EXPANSION_PLAN.md in a single quick task
- Order: bug fix → regulamento.md → documentos.md (new) → matricula.md → faq.md → calendario.md → curriculo.md
- Single plan, atomic commits per logical unit
- Use frequent ## and ### markdown headers (every 3-5 paragraphs / every major topic)
- Each section should be self-contained within ~500 tokens
- Avoid cross-referencing between files where possible

### Specifics

- regulamento.md must cover: aprovacao, reprovacao, jubilamento, frequencia, exame final, revisao de nota, segunda chamada, abono de faltas, regime especial, estagio, TCC, colacao de grau
- documentos.md: new file + new CATEGORY_MAP entry ("documentos.md": "documentos")
- Bug fix in ingest.py line 22: "regulamento.pdf" → "regulamento.md"
- Chunk size = 500 tokens, overlap = 50

</user_constraints>

## RecursiveCharacterTextSplitter Behavior (Verified)

### Default Separators [VERIFIED: langchain_text_splitters 1.1.2 runtime test]

The `from_tiktoken_encoder(chunk_size=500, chunk_overlap=50, encoding_name="cl100k_base")` configuration uses these separators in priority order:

```
['\n\n', '\n', ' ', '']
```

**Critical behavior verified empirically:**

1. **Primary split on `\n\n`** — the splitter first tries to split on double-newlines (paragraph boundaries). This means a blank line between sections IS the primary chunk boundary.
2. **Merging small sections** — if consecutive sections separated by `\n\n` total < 500 tokens, they are MERGED into one chunk. Sections of 100-200 tokens will be combined with neighbors.
3. **Splitting large sections** — if a single section > 500 tokens, it splits on `\n` (single newline), then ` ` (space) as fallback.
4. **Overlap** — the 50-token overlap means the end of chunk N is repeated at the start of chunk N+1, providing continuity.

### Portuguese Token Density [VERIFIED: tiktoken cl100k_base]

Portuguese academic text is more token-dense than English:

| Content | Tokens |
|---------|--------|
| 3 well-developed paragraphs | ~300-350 tokens |
| 4 paragraphs with detail | ~400-450 tokens |
| 5 paragraphs (near limit) | ~480-520 tokens |
| 1 short intro paragraph | ~50-100 tokens |

### Current File Chunk Distribution [VERIFIED: runtime test]

| File | Total Tokens | Chunks | Chunk Sizes |
|------|-------------|--------|-------------|
| matricula.md | 1690 | 4 | [494, 429, 423, 354] |
| faq.md | 1463 | 4 | [425, 427, 440, 200] |
| calendario.md | 1381 | 4 | [404, 327, 422, 266] |
| curriculo.md | 1483 | 4 | [463, 468, 468, 150] |
| regulamento.md | 85 | 1 | [85] — useless |

**Target after expansion:** Each file should produce 8-15 high-quality chunks (4000-7500 tokens per file).

## Optimal Section Writing Strategy

### The 300-450 Token Sweet Spot

Based on verified splitter behavior:

| Section Size | What Happens | Verdict |
|-------------|--------------|---------|
| < 150 tokens | Merged with next section — loses topic isolation | BAD |
| 150-299 tokens | May be merged or standalone depending on neighbors | RISKY |
| 300-450 tokens | One clean chunk, room for overlap without splitting | IDEAL |
| 451-500 tokens | Fits in one chunk but tight — overlap may push it over | ACCEPTABLE |
| > 500 tokens | Split mid-section on `\n` boundary — loses coherence | BAD |

### Writing Rules for Clean Chunking

1. **Every `##` or `###` section should be 300-450 tokens** (3-4 paragraphs of Portuguese prose)
2. **Always put a blank line before and after headers** — this creates the `\n\n` boundary the splitter uses
3. **Make each section self-contained** — include the topic name, the rule, the exception, and the consequence in the SAME section
4. **Repeat key terms** — don't use "conforme mencionado acima"; instead repeat "a frequencia minima de 75%" explicitly
5. **Start sections with the topic statement** — "O jubilamento ocorre quando..." not "Conforme regulamento..."
6. **Avoid bullet-only sections** — bullets are split on `\n` and lose context; wrap bullet content in prose paragraphs
7. **Headers are NOT separated from content** — the header + its content form ONE chunk unit

### Anti-Pattern: Lists Without Context

```markdown
## BAD - will produce disconnected chunks

### Tipos de documento:
- Historico escolar
- Declaracao de vinculo
- Comprovante de matricula
```

```markdown
## GOOD - self-contained chunk

### Historico Escolar

O historico escolar e o documento oficial que registra todas as disciplinas cursadas
pelo aluno, com notas finais, situacao (aprovado/reprovado) e carga horaria.
A emissao leva ate 5 dias uteis apos a solicitacao. O documento e valido por
tempo indeterminado e pode ser solicitado a qualquer momento durante ou apos
a conclusao do curso. Para solicitar, o aluno deve estar com situacao regular
(sem pendencias financeiras ou documentais).
```

## Brazilian Academic Regulations Reference

### Key Rules to Encode [ASSUMED — based on standard Brazilian university regulations]

| Rule | Source | Value |
|------|--------|-------|
| Frequencia minima | LDB Art. 24, VI | 75% por disciplina |
| Carga horaria CC | MEC Diretrizes Curriculares | Min. 3000h (normalmente 3200h) |
| Duracao padrao | Resolucoes MEC | 8 semestres (4 anos) |
| Tempo max integralizacao | Tipico | 14 semestres (1.75× duracao) |
| Escala de notas | Pratica brasileira | 0 a 10, uma casa decimal |
| Aprovacao direta | Mais comum | >= 7,0 |
| Direito a exame final | Tipico | Media 3,0 a 6,9 |
| Aprovacao apos exame | Tipico | (MS + EF) / 2 >= 5,0 |
| Reprovacao direta | Tipico | < 3,0 |
| Prazo revisao de nota | Tipico | 3-5 dias uteis apos divulgacao |
| Segunda chamada | Tipico | Requerimento em ate 3 dias uteis |
| TCC | Obrigatorio para bacharelado | Orientador + banca de 3 |
| Estagio supervisionado | MEC Resolucao | Min. 160h (tipico 300h) |
| Jubilamento alerta | Tipico | Ao atingir 80% do tempo max |
| Colacao de grau | Tipico | Apos integralizacao total + quitacao |

### Abono de Faltas — Casos Legais [ASSUMED — based on legislacao brasileira]

- Servico militar obrigatorio (Decreto-Lei 715/1969)
- Convocacao para juri ou mesa receptora de votos
- Falecimento de familiar em 1o grau (ate 8 dias)
- Licenca-maternidade (120 dias — Lei 11.770/2008)
- Licenca-paternidade (5-20 dias)
- Doencas infectocontagiosas (Decreto-Lei 1.044/1969) — regime domiciliar, NAO abono
- Gestantes (Lei 6.202/1975) — regime especial a partir do 8o mes

**IMPORTANT NOTE:** Atestado medico NÃO abona falta na maioria das IES brasileiras — apenas justifica para fins de segunda chamada de prova.

## Common Pitfalls

### Pitfall 1: Redundancy Between Files Degrading Retrieval

**What goes wrong:** The same information appears in `matricula.md` AND `faq.md` AND `regulamento.md` — the RAG retrieves multiple low-differentiation chunks instead of the single best answer.
**Why it happens:** FAQ naturally repeats information from other sources.
**How to avoid:**
- `regulamento.md` = authoritative rules (the "law")
- `matricula.md` = procedural how-to (the "workflow")
- `faq.md` = quick answers that REFERENCE the rule without re-explaining it in full
- `documentos.md` = document-specific procedures
- Each file answers a DIFFERENT type of question about the same topic

### Pitfall 2: Sections Too Small Get Merged Into Wrong Topics

**What goes wrong:** A 50-token section about "abono de faltas" gets merged with the previous section about "reprovacao por falta" — the chunk now mixes two distinct topics.
**How to avoid:** Minimum 300 tokens per section. If a topic is naturally short, expand with examples, procedures, or consequences to reach the minimum.

### Pitfall 3: Headers Split From Their Content

**What goes wrong:** Using `\n\n\n` (triple newline) or excessive whitespace between a header and its content causes the splitter to see them as separate segments.
**How to avoid:** Standard formatting only: `\n\n## Header\n\nContent...`

### Pitfall 4: Long Bullet Lists

**What goes wrong:** A list of 15 document types as bullets creates a section of 600+ tokens that gets split between items, producing chunks like "- Certidao\n- Atestado" without context.
**How to avoid:** Group bullets into themed sub-sections of 3-5 items each with prose explanation.

## Architecture Patterns

### Content Organization Per File (Deduplication Strategy)

```
regulamento.md    → WHAT are the rules (normative, authoritative)
                    Categories: aprovacao, frequencia, jubilamento, regime especial
                    
matricula.md      → HOW to enroll (procedural, step-by-step)  
                    Categories: prazos, limites, fluxo, cancelamento
                    
documentos.md     → WHAT documents exist, HOW to get them
                    Categories: tipos, prazos, requisitos, status
                    
faq.md            → SHORT answers to specific questions
                    Pattern: Pergunta → Resposta concisa (reference other files for depth)
                    
calendario.md     → WHEN things happen (dates, deadlines)
                    Categories: matricula, avaliacoes, TCC, feriados
                    
curriculo.md      → WHAT to study (structure, requirements)
                    Categories: disciplinas, creditos, prerequisitos, eletivas
```

### Section Template for Consistent Chunks

```markdown
## [Topic Name - Specific Aspect]

[Opening statement defining the topic in one sentence. KEY TERMS included.]

[2-3 sentences of detail: rules, numbers, conditions, formula if applicable.
This paragraph carries the core factual content that answers the student's question.]

[1-2 sentences on exceptions, edge cases, or what to do if the standard rule
doesn't apply. End with actionable guidance: "o aluno deve procurar a secretaria"
or "consulte o calendario academico".]
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token counting | Manual char estimation | `tiktoken.encode()` offline check | Portuguese has variable token density |
| Chunk boundary testing | Guessing if section fits | Run `splitter.split_text()` on draft | Only way to verify actual boundaries |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Aprovacao direta >= 7,0, exame final 3,0-6,9 | Brazilian Regulations | Could be 5,0/6,0 at some institutions — but 7,0 is most common for federal/private universities post-2000 |
| A2 | Tempo max integralizacao = 14 semestres | Brazilian Regulations | Varies by institution (12-16 sem typical) — 14 is safe middle ground |
| A3 | Estagio min 160h | Brazilian Regulations | MEC minimum; many courses require 300h+ |
| A4 | Atestado medico nao abona falta | Brazilian Regulations | Correct for most IES but some have internal rules more permissive |

**Note:** All A1-A4 are for a FICTIONAL institution, so exact values are author's choice. The user decision says "recognizable as plausible" — these values meet that criterion.

## Sources

### Primary (HIGH confidence)

- `ai_service/ingest.py` — verified splitter config: `from_tiktoken_encoder(chunk_size=500, chunk_overlap=50, encoding_name="cl100k_base")`
- `langchain_text_splitters 1.1.2` — runtime verification of default separators: `['\n\n', '\n', ' ', '']`
- `tiktoken cl100k_base` — runtime token counting of Portuguese academic text
- `RAG_EXPANSION_PLAN.md` — authoritative scope definition for this task

### Secondary (MEDIUM confidence)

- Brazilian LDB (Lei 9.394/1996) Art. 24 — 75% frequency requirement is well-established law
- MEC Diretrizes Curriculares for CS (Resolucao CNE/CES 5/2016) — 3000h minimum

### Tertiary (LOW confidence)

- Specific grading thresholds (7.0 direct, 3.0-6.9 exam) — common but institution-dependent [ASSUMED]

## Metadata

**Confidence breakdown:**
- Splitter behavior: HIGH — runtime-verified with actual library
- Section sizing: HIGH — empirically tested with Portuguese text
- Brazilian regulations: MEDIUM — well-known rules but specific thresholds are institution-variable (acceptable for fictional institution)
- Deduplication strategy: MEDIUM — based on RAG best practices, not empirically tested with this specific threshold

**Research date:** 2026-05-04
**Valid until:** 2026-06-04 (stable — splitter behavior and regulations don't change frequently)
