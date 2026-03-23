/**
 * DateRangeSlider - plain JS dual-thumb date range slider.
 * Usage: new DateRangeSlider(containerEl, { min, max, onChange, onReset })
 */
function DateRangeSlider(container, opts) {
    var min = opts.min, max = opts.max;
    var start = min, end = max;
    var dragging = null;
    var onChange = opts.onChange || function () {};
    var onReset = opts.onReset || null;

    // Build DOM
    container.innerHTML =
        '<div class="date-slider-block">' +
            '<label class="date-slider-label">Date Range</label>' +
            '<div class="slider-inputs">' +
                '<input type="number" class="slider-year-input ds-start" min="' + min + '" max="' + max + '" value="' + min + '">' +
                '<span class="slider-separator">to</span>' +
                '<input type="number" class="slider-year-input ds-end" min="' + min + '" max="' + max + '" value="' + max + '">' +
            '</div>' +
            '<div class="slider-bar">' +
                '<div class="slider-bar-background"></div>' +
                '<div class="slider-bar-active"></div>' +
                '<div class="slider-thumb ds-thumb-left"></div>' +
                '<div class="slider-thumb ds-thumb-right"></div>' +
            '</div>' +
            (onReset ? '<button class="slider-reset-button">Reset Date Filter</button>' : '') +
        '</div>';

    var bar = container.querySelector('.slider-bar');
    var active = container.querySelector('.slider-bar-active');
    var thumbL = container.querySelector('.ds-thumb-left');
    var thumbR = container.querySelector('.ds-thumb-right');
    var inputStart = container.querySelector('.ds-start');
    var inputEnd = container.querySelector('.ds-end');

    function pct(year) { return ((year - min) / (max - min)) * 100; }

    function render() {
        var lp = pct(start), rp = pct(end);
        active.style.left = lp + '%';
        active.style.width = (rp - lp) + '%';
        thumbL.style.left = lp + '%';
        thumbR.style.left = rp + '%';
        inputStart.value = start;
        inputEnd.value = end;
    }

    function posToYear(clientX) {
        var rect = bar.getBoundingClientRect();
        var p = Math.min(Math.max((clientX - rect.left) / rect.width, 0), 1);
        return Math.min(Math.max(Math.round(min + p * (max - min)), min), max);
    }

    function onMove(e) {
        if (!dragging) return;
        var cx = e.touches ? e.touches[0].clientX : e.clientX;
        var year = posToYear(cx);
        if (dragging === 'min' && year <= end) start = year;
        else if (dragging === 'max' && year >= start) end = year;
        render();
    }

    function onUp() {
        if (dragging) { dragging = null; onChange(start, end); }
        window.removeEventListener('mousemove', onMove);
        window.removeEventListener('mouseup', onUp);
        window.removeEventListener('touchmove', onMove);
        window.removeEventListener('touchend', onUp);
    }

    function startDrag(which) {
        return function (e) {
            e.preventDefault();
            dragging = which;
            window.addEventListener('mousemove', onMove);
            window.addEventListener('mouseup', onUp);
            window.addEventListener('touchmove', onMove);
            window.addEventListener('touchend', onUp);
        };
    }

    thumbL.addEventListener('mousedown', startDrag('min'));
    thumbL.addEventListener('touchstart', startDrag('min'));
    thumbR.addEventListener('mousedown', startDrag('max'));
    thumbR.addEventListener('touchstart', startDrag('max'));

    inputStart.addEventListener('change', function () {
        var v = Math.min(parseInt(this.value) || min, end);
        start = Math.max(v, min);
        render();
        onChange(start, end);
    });
    inputEnd.addEventListener('change', function () {
        var v = Math.max(parseInt(this.value) || max, start);
        end = Math.min(v, max);
        render();
        onChange(start, end);
    });

    if (onReset) {
        container.querySelector('.slider-reset-button').addEventListener('click', function () {
            start = min; end = max;
            render();
            onReset();
        });
    }

    // Public API
    this.setRange = function (s, e) { start = s; end = e; render(); };
    this.getRange = function () { return [start, end]; };

    render();
}
