(function () {
  const root = document.querySelector("[data-moonink-search-page]");
  if (!root) {
    return;
  }

  const input = root.querySelector("#moonink-search-query");
  const status = root.querySelector("[data-search-status]");
  const results = root.querySelector("[data-moonink-search-results]");
  if (!(input instanceof HTMLInputElement) || !status || !results) {
    return;
  }

  const searchIndexUrl = new URL("../search-index.json", window.location.href).toString();

  function tokenize(text) {
    return (text || "").toLowerCase().match(/[a-z0-9]+/g) || [];
  }

  function containsToken(text, token) {
    return (text || "").toLowerCase().includes(token);
  }

  function scoreItem(item, tokens) {
    let total = 0;
    for (const token of tokens) {
      let tokenScore = 0;
      if (containsToken(item.title, token)) {
        tokenScore += 12;
      }
      if (containsToken(item.summary, token)) {
        tokenScore += 8;
      }
      if (Array.isArray(item.tags) && item.tags.some((tag) => containsToken(tag, token))) {
        tokenScore += 6;
      }
      if (containsToken(item.excerpt, token)) {
        tokenScore += 3;
      }
      if (tokenScore === 0) {
        return 0;
      }
      total += tokenScore;
    }
    return total;
  }

  function formatKind(kind) {
    if (!kind) {
      return "Page";
    }
    return kind.charAt(0).toUpperCase() + kind.slice(1);
  }

  function clearResults() {
    results.textContent = "";
  }

  function node(tag, className, text) {
    const element = document.createElement(tag);
    if (className) {
      element.className = className;
    }
    if (text) {
      element.textContent = text;
    }
    return element;
  }

  function renderResults(items) {
    clearResults();
    for (const item of items) {
      const li = node("li", "search-result");
      const link = node("a", "search-result-link");
      link.href = item.url;

      const title = node("h2", "search-result-title", item.title);
      link.appendChild(title);

      const metaParts = [formatKind(item.kind)];
      if (item.date) {
        metaParts.push(item.date);
      }
      if (Array.isArray(item.tags) && item.tags.length > 0) {
        metaParts.push(item.tags.join(", "));
      }
      li.appendChild(link);
      li.appendChild(node("p", "search-result-meta", metaParts.join(" · ")));

      const description = item.summary || item.excerpt;
      if (description) {
        li.appendChild(node("p", "search-result-summary", description));
      }
      results.appendChild(li);
    }
  }

  function compareResults(left, right) {
    if (left.score !== right.score) {
      return right.score - left.score;
    }
    const leftDate = left.item.date || "";
    const rightDate = right.item.date || "";
    if (leftDate !== rightDate) {
      return rightDate.localeCompare(leftDate);
    }
    return left.item.title.localeCompare(right.item.title);
  }

  function updateStatus(message) {
    status.textContent = message;
  }

  let items = [];
  let indexLoaded = false;

  fetch(searchIndexUrl)
    .then((response) => {
      if (!response.ok) {
        throw new Error("Failed to load search index");
      }
      return response.json();
    })
    .then((document) => {
      items = Array.isArray(document.items) ? document.items : [];
      indexLoaded = true;
      updateStatus("Type to search the generated index.");
    })
    .catch(() => {
      updateStatus("Search index could not be loaded.");
    });

  function runSearch() {
    if (!indexLoaded) {
      updateStatus("Loading search index...");
      return;
    }
    const query = input.value.trim();
    const tokens = tokenize(query);
    if (tokens.length === 0) {
      clearResults();
      updateStatus("Type to search the generated index.");
      return;
    }

    const matches = items
      .map((item) => ({ item, score: scoreItem(item, tokens) }))
      .filter((entry) => entry.score > 0)
      .sort(compareResults)
      .slice(0, 24);

    if (matches.length === 0) {
      clearResults();
      updateStatus("No results matched that query.");
      return;
    }

    renderResults(matches.map((entry) => entry.item));
    updateStatus(matches.length + " result" + (matches.length === 1 ? "" : "s") + " found.");
  }

  input.addEventListener("input", runSearch);
})();
