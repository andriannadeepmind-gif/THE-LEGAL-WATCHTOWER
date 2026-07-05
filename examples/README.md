# Example Outputs

This directory contains example outputs from the analysis scripts for demonstration and testing purposes.

## Files

### benchmark-results.json
Example output from `scripts/benchmark-performance.py`

**Contents:**
- Query performance metrics (median, p95, p99)
- Per-article response times
- Cache hit rates
- Complexity scores

**Usage:**
```bash
# Generate actual results
python3 scripts/benchmark-performance.py \
    --endpoint http://localhost:8080/sparql \
    --iterations 100 \
    --output benchmark-results.json
```

---

### citation-embeddings-report.json
Example output from `scripts/generate-citation-embeddings.py`

**Contents:**
- Network statistics
- Semantic centrality scores
- Top 10 semantic hubs
- Citation patterns

**Usage:**
```bash
# Generate actual results
python3 scripts/generate-citation-embeddings.py \
    --endpoint http://localhost:8080/sparql \
    --embeddings-dir embeddings/ \
    --output citation-embeddings-report.json
```

---

## Notes

- These are **example outputs** for demonstration only
- Based on sample constitutional articles (1, 2, 5, 16, 21, 25, 28, 106)
- Actual results will vary based on your data
- Run the scripts with your SPARQL endpoint for real metrics

---

## Expected Ranges

### Performance Benchmark
- **Median response:** 8-15ms (good), 15-30ms (acceptable), >30ms (needs optimization)
- **P95 response:** 25-45ms (good), 45-80ms (acceptable), >80ms (needs optimization)
- **Cache hit rate:** >90% (excellent), 80-90% (good), <80% (needs tuning)

### Citation Embeddings
- **Semantic centrality:** 0.7-1.0 (primary hub), 0.4-0.7 (secondary), <0.4 (peripheral)
- **Citation frequency:** Varies by article importance
- **Network density:** 0.5-1.5 citations/article (typical for constitutional law)

---

## Visualization

To visualize these results, use standard JSON viewers or import into analysis tools:

```python
import json
import matplotlib.pyplot as plt

# Load benchmark results
with open('benchmark-results.json') as f:
    data = json.load(f)

# Plot article performance
articles = [r['article_number'] for r in data['detailed_results']['simple_queries']['per_article_results']]
medians = [r['median_ms'] for r in data['detailed_results']['simple_queries']['per_article_results']]

plt.bar(articles, medians)
plt.xlabel('Article Number')
plt.ylabel('Median Response Time (ms)')
plt.title('Query Performance by Article')
plt.show()
```

---

**Last Updated:** 2025-11-14  
**Version:** 1.2.0
