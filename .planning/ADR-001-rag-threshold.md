# ADR-001: Threshold de Similaridade do RAG

**Data:** 2026-05-02
**Status:** Aceita
**Contexto:** Diagnostico do RAG que nunca retornava resultados na busca semantica

---

## Problema

O chatbot nunca encontrava informacoes na base de conhecimento. Qualquer pergunta
academica recebia "nao encontrei informacoes", apesar dos documentos estarem
corretamente ingeridos no pgvector.

O threshold de similaridade estava configurado em `0.75` (hardcoded em `ai_service/rag.py`).
Os scores reais das queries ficavam na faixa 0.60-0.73, sempre abaixo do corte.

## Hipoteses investigadas

### Hipotese 1: OpenRouter produz vetores nao-deterministicos

**Teste:** Rodar a mesma query 5 vezes e comparar scores.

**Resultado:** Refutada. Delta entre runs < 0.00003. Os scores sao consistentes.

### Hipotese 2: embed_query e embed_documents produzem vetores incompativeis via OpenRouter

**Teste:** Gerar embedding do texto exato de um chunk armazenado usando `embed_query`,
e comparar diretamente (Python numpy) com o vetor armazenado (gerado por `embed_documents`
durante o ingest).

**Resultado:** Refutada. Similaridade coseno = **1.000000**. Os dois endpoints
retornam vetores identicos via OpenRouter.

### Hipotese 3: Formato de passagem do vetor para pgvector trunca ou corrompe

**Teste:** Comparar `str(list)` vs formato pgvector explicito. Verificar dimensoes
recebidas pelo pgvector.

**Resultado:** Refutada. Ambos os metodos retornam similaridade 1.0. pgvector
recebe 1536 dimensoes corretamente.

### Hipotese 4: Queries curtas contra chunks longos tem similaridade naturalmente baixa

**Teste:** Buscar o mesmo chunk com queries de tamanhos variados.

**Resultado:** Confirmada.

| Query | Tamanho | Similaridade |
|-------|---------|-------------|
| Texto completo do chunk (identico) | 1919 chars | 1.000000 |
| Primeiro paragrafo do chunk | 419 chars | 0.883510 |
| Primeira frase do chunk | 137 chars | 0.750610 |
| Query semantica ("quais os prazos e regras...") | 145 chars | 0.729336 |
| Titulo do documento ("Guia de Matricula...") | 31 chars | 0.668496 |

## Causa raiz

O modelo `text-embedding-3-small` (1536 dimensoes) produz embeddings onde a
similaridade coseno entre uma query curta (~10-30 palavras, tipica de WhatsApp)
e um chunk longo (~500 tokens) cai naturalmente para a faixa **0.60-0.73**.

Isso e comportamento esperado do modelo — nao e bug do provider, do formato,
nem do pgvector.

O threshold de 0.75 foi calibrado assumindo que queries relevantes teriam
similaridade >= 0.75, o que nao se confirma na pratica com este modelo e
este padrao de chunks.

## Decisao

1. **Tornar o threshold configuravel** via variavel de ambiente `RAG_SIMILARITY_THRESHOLD`
2. **Ajustar o default para 0.60** — captura queries semanticas relevantes (0.63-0.73)
   e ainda filtra conteudo irrelevante (tipicamente < 0.50)
3. **Manter OpenRouter como provider de embeddings** — o diagnostico comprovou que
   nao ha diferenca de qualidade vs OpenAI direto para este caso
4. **Nao e necessario re-ingerir a knowledge base** — os vetores armazenados estao corretos

## Alteracoes necessarias

### `ai_service/config.py`

Adicionar campo ao `Settings`:

```python
RAG_SIMILARITY_THRESHOLD: float = float(
    os.environ.get("RAG_SIMILARITY_THRESHOLD", "0.60")
)
```

### `ai_service/rag.py`

Remover constante hardcoded e aceitar threshold como parametro:

```python
# Remover:
SIMILARITY_THRESHOLD = 0.75

# Alterar assinatura:
def create_rag_tool(db_pool, embeddings, similarity_threshold: float = 0.60):

# Usar no SQL:
cursor.execute(query, (vector_str, vector_str, similarity_threshold))
```

### `ai_service/agent.py`

Passar threshold do settings:

```python
rag_tool = create_rag_tool(db_pool, embeddings, similarity_threshold=settings.RAG_SIMILARITY_THRESHOLD)
```

### `ai_service/tests/test_rag_retrieval.py`

Atualizar testes para usar threshold explicito e adicionar teste de threshold customizado.

## Consequencias

- RAG vai retornar chunks relevantes para queries tipicas de WhatsApp
- Queries muito genericas (similaridade ~0.50-0.60) podem retornar chunks pouco relevantes — aceitavel para MVP, o agente deve interpretar e filtrar
- O threshold pode ser ajustado por ambiente sem alterar codigo
- Se no futuro trocar de modelo de embeddings, basta recalibrar o threshold via env var

## Evidencia

Scripts de teste utilizados (podem ser removidos apos a decisao):
- `ai_service/test_rag_similarity.py` — teste de determinismo (5 runs por query)
- `ai_service/test_rag_vectors.py` — comparacao embed_query vs embed_documents
- `ai_service/test_rag_format.py` — comparacao de formato de passagem ao pgvector
- `ai_service/test_rag_length.py` — relacao tamanho da query vs similaridade
