(function() {
  function parseNumber(value) {
    if (!value) return null;
    var normalized = String(value).trim().replace(',', '.');
    if (normalized === '') return null;
    var parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : null;
  }

  function parseQuantity(value) {
    var parsed = parseNumber(value);
    if (parsed === null) return null;
    return parsed < 0 ? 0 : Math.floor(parsed);
  }

  function formatCurrency(amount) {
    var hasDecimals = Math.abs(amount % 1) > 0.001;
    return new Intl.NumberFormat('sv-SE', {
      minimumFractionDigits: hasDecimals ? 2 : 0,
      maximumFractionDigits: 2
    }).format(amount) + ' kr';
  }

  function formatEditableNumber(amount) {
    if (amount === null || amount === undefined || amount === '') return '';
    return String(amount)
      .replace(',', '.')
      .replace(/[^0-9.]/g, '')
      .replace(/(\.\d*?)0+$/, '$1')
      .replace(/\.0$/, '')
      .replace(/\.$/, '');
  }

  function sanitizePrice(value) {
    var cleaned = String(value || '').replace(',', '.').replace(/[^0-9.]/g, '');
    var parts = cleaned.split('.');
    if (parts.length > 2) cleaned = parts.shift() + '.' + parts.join('');
    if (cleaned.startsWith('.')) cleaned = '0' + cleaned;
    return cleaned;
  }

  function sanitizeQuantity(value) {
    return String(value || '').replace(/[^\d]/g, '');
  }

  function setText(node, text) {
    if (node) node.textContent = text;
  }

  function toggleClass(node, className, enabled) {
    if (node) node.classList.toggle(className, enabled);
  }

  function init() {
    var root = document.querySelector('[data-party-economy]');
    if (!root) return;

    var priceInputs = Array.prototype.slice.call(root.querySelectorAll('[data-role="price-input"]'));
    var quantityInputs = Array.prototype.slice.call(root.querySelectorAll('[data-role="quantity-input"]'));
    if (!priceInputs.length && !quantityInputs.length) return;

    function visibleArticleIds() {
      return Array.prototype.slice.call(root.querySelectorAll('[data-role="article-header"]:not(.is-hidden-column)')).map(function(header) {
        return header.dataset.articleId;
      });
    }

    function visibleQuantityInputs() {
      return quantityInputs.filter(function(input) {
        var cell = input.closest('[data-role="article-cell"]');
        return cell && !cell.classList.contains('is-hidden-column');
      });
    }

    function rowMemberIds() {
      return Array.prototype.slice.call(root.querySelectorAll('tbody tr[data-member-id]')).map(function(row) {
        return row.dataset.memberId;
      });
    }

    function focusInput(input) {
      if (!input) return;
      input.focus();
      input.select();
    }

    function moveToPrice(input, offset) {
      var index = priceInputs.indexOf(input);
      if (index === -1) return;
      focusInput(priceInputs[index + offset]);
    }

    function moveToNextQuantity(input, offset) {
      var inputs = visibleQuantityInputs();
      var index = inputs.indexOf(input);
      if (index === -1) return;
      focusInput(inputs[index + offset]);
    }

    function moveInGrid(input, rowOffset, columnOffset) {
      var articleIds = visibleArticleIds();
      var memberIds = rowMemberIds();
      var rowIndex = memberIds.indexOf(input.dataset.memberId);
      var columnIndex = articleIds.indexOf(input.dataset.articleId);
      if (rowIndex === -1 || columnIndex === -1) return;

      var nextRow = rowIndex + rowOffset;
      var nextColumn = columnIndex + columnOffset;
      if (nextRow < 0 || nextColumn < 0 || nextRow >= memberIds.length || nextColumn >= articleIds.length) return;

      focusInput(root.querySelector(
        '[data-role="quantity-input"][data-member-id="' + memberIds[nextRow] + '"][data-article-id="' + articleIds[nextColumn] + '"]'
      ));
    }

    function updateInputState(input) {
      var role = input.dataset.role;
      var empty = input.value.trim() === '';
      var quantity = role === 'quantity-input' ? parseQuantity(input.value) : null;
      var zero = role === 'quantity-input' && !empty && quantity === 0;
      var active = !empty && !zero;

      toggleClass(input, 'is-empty', role === 'quantity-input' && empty);
      toggleClass(input, 'is-zero', zero);
      toggleClass(input, 'is-active-value', active);

      if (role === 'quantity-input') {
        toggleClass(input.closest('[data-role="article-cell"]'), 'is-pending', empty);
      }
    }

    function normalizePrice(input) {
      var parsed = parseNumber(input.value);
      input.value = parsed === null ? '' : formatEditableNumber(parsed);
      updateInputState(input);
    }

    function normalizeQuantity(input) {
      var parsed = parseQuantity(input.value);
      input.value = parsed === null ? '' : String(parsed);
      updateInputState(input);
    }

    function recalculate() {
      var priceByArticle = {};
      var articleNameById = {};
      var articleData = {};
      var memberData = {};
      var pendingCount = 0;

      priceInputs.forEach(function(input) {
        var articleId = input.dataset.articleId;
        var price = parseNumber(input.value);
        priceByArticle[articleId] = price !== null && price > 0 ? price : null;
        articleNameById[articleId] = input.dataset.articleName || articleId;
      });

      quantityInputs.forEach(function(input) {
        var articleId = input.dataset.articleId;
        var memberId = input.dataset.memberId;
        var cell = input.closest('[data-role="article-cell"]');

        articleData[articleId] = articleData[articleId] || {
          quantity: 0,
          revenue: 0,
          missingPrice: false
        };
        memberData[memberId] = memberData[memberId] || {
          total: 0,
          missingItems: []
        };

        if (cell && cell.classList.contains('is-hidden-column')) return;

        if (input.value.trim() === '') {
          pendingCount += 1;
          return;
        }

        var quantity = parseQuantity(input.value);
        if (quantity === null || quantity === 0) return;

        articleData[articleId].quantity += quantity;
        if (priceByArticle[articleId] !== null) {
          articleData[articleId].revenue += quantity * priceByArticle[articleId];
          memberData[memberId].total += quantity * priceByArticle[articleId];
        } else {
          articleData[articleId].missingPrice = true;
          if (memberData[memberId].missingItems.indexOf(articleNameById[articleId]) === -1) {
            memberData[memberId].missingItems.push(articleNameById[articleId]);
          }
        }
      });

      var missingArticles = [];
      var totalSales = 0;

      Object.keys(articleNameById).forEach(function(articleId) {
        var summary = articleData[articleId] || { quantity: 0, revenue: 0, missingPrice: false };
        var visible = summary.quantity > 0 || priceByArticle[articleId] !== null;
        if (summary.missingPrice) {
          missingArticles.push(articleNameById[articleId]);
        } else {
          totalSales += summary.revenue;
        }

        var header = root.querySelector('[data-role="article-header"][data-article-id="' + articleId + '"]');
        var footer = root.querySelector('[data-role="article-summary-cell"][data-article-id="' + articleId + '"]');
        var cells = root.querySelectorAll('[data-role="article-cell"][data-article-id="' + articleId + '"]');

        setText(root.querySelector('[data-role="article-quantity"][data-article-id="' + articleId + '"]'), summary.quantity + ' st');
        setText(root.querySelector('[data-role="article-revenue"][data-article-id="' + articleId + '"]'), summary.missingPrice ? 'Pris saknas' : formatCurrency(summary.revenue));
        toggleClass(header, 'is-hidden-column', !visible);
        toggleClass(footer, 'is-hidden-column', !visible);
        toggleClass(header, 'has-warning', summary.missingPrice);
        toggleClass(footer, 'has-warning', summary.missingPrice);
        cells.forEach(function(cell) {
          toggleClass(cell, 'is-hidden-column', !visible);
        });
      });

      Object.keys(memberData).forEach(function(memberId) {
        var summary = memberData[memberId];
        var missing = summary.missingItems.length > 0;
        setText(root.querySelector('[data-role="member-total-main"][data-member-id="' + memberId + '"]'), missing ? 'Pris saknas' : formatCurrency(summary.total));
        setText(root.querySelector('[data-role="member-total-sub"][data-member-id="' + memberId + '"]'), missing ? summary.missingItems.join(', ') : '');
        toggleClass(root.querySelector('[data-role="member-total-cell"][data-member-id="' + memberId + '"]'), 'has-warning', missing);
      });

      var salesReady = missingArticles.length === 0;
      setText(root.querySelector('[data-role="overview-total-sales"]'), salesReady ? formatCurrency(totalSales) : 'Pris saknas');
      setText(root.querySelector('[data-role="overall-total-main"]'), salesReady ? formatCurrency(totalSales) : 'Pris saknas');
      setText(root.querySelector('[data-role="pending-summary"]'), pendingCount > 0 ? pendingCount + ' tomma rutor' : 'Allt ifyllt');
      toggleClass(root.querySelector('[data-role="overall-total-cell"]'), 'has-warning', !salesReady);

      var banner = root.querySelector('[data-role="issues-banner"]');
      if (banner) {
        if (missingArticles.length > 0) {
          banner.textContent = 'Pris saknas: ' + missingArticles.join(', ');
          banner.classList.add('meta-chip-warning');
        } else {
          banner.textContent = 'Alla priser klara';
          banner.classList.remove('meta-chip-warning');
        }
      }
    }

    priceInputs.forEach(function(input) {
      input.addEventListener('input', function() {
        var caret = input.selectionStart;
        input.value = sanitizePrice(input.value);
        if (caret !== null) input.setSelectionRange(caret, caret);
        updateInputState(input);
        recalculate();
      });
      input.addEventListener('blur', function() {
        normalizePrice(input);
        recalculate();
      });
      input.addEventListener('focus', function() {
        input.select();
      });
      input.addEventListener('keydown', function(event) {
        if (['e', 'E', '+', '-'].indexOf(event.key) !== -1) {
          event.preventDefault();
          return;
        }
        if (event.key === 'Enter' || event.key === 'ArrowDown') {
          event.preventDefault();
          moveToPrice(input, 1);
        } else if (event.key === 'ArrowUp') {
          event.preventDefault();
          moveToPrice(input, -1);
        }
      });
    });

    quantityInputs.forEach(function(input) {
      input.addEventListener('input', function() {
        var caret = input.selectionStart;
        input.value = sanitizeQuantity(input.value);
        if (caret !== null) input.setSelectionRange(caret, caret);
        updateInputState(input);
        recalculate();
      });
      input.addEventListener('blur', function() {
        normalizeQuantity(input);
        recalculate();
      });
      input.addEventListener('focus', function() {
        input.select();
      });
      input.addEventListener('keydown', function(event) {
        if (['e', 'E', '+', '-', '.', ','].indexOf(event.key) !== -1) {
          event.preventDefault();
          return;
        }
        if (event.key === 'Enter') {
          event.preventDefault();
          moveToNextQuantity(input, event.shiftKey ? -1 : 1);
        } else if (event.key === 'ArrowRight') {
          event.preventDefault();
          moveInGrid(input, 0, 1);
        } else if (event.key === 'ArrowLeft') {
          event.preventDefault();
          moveInGrid(input, 0, -1);
        } else if (event.key === 'ArrowUp') {
          event.preventDefault();
          moveInGrid(input, -1, 0);
        } else if (event.key === 'ArrowDown') {
          event.preventDefault();
          moveInGrid(input, 1, 0);
        }
      });
    });

    priceInputs.concat(quantityInputs).forEach(updateInputState);
    recalculate();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
