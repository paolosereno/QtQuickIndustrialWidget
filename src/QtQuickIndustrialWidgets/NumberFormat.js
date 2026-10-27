.pragma library

// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

/**
 * Fixed-point text of value with decimals digits after the point, never a negative zero.
 * Same text as QString::number(value, 'f', decimals), except that a result showing zero
 * has no sign (e.g. -0.04 with 1 decimal is "0.0", not "-0.0").
 */
function formatFixed(value, decimals) {
    if (isNaN(value)) {
        return "nan";
    }
    if (!isFinite(value)) {
        return value > 0 ? "inf" : "-inf";
    }
    let text = Number(value).toFixed(decimals);
    if (text.startsWith('-')) {
        let zero = true;
        for (let i = 1; i < text.length && zero; ++i) {
            zero = text.charAt(i) === '0' || text.charAt(i) === '.';
        }
        if (zero) {
            text = text.substring(1);
        }
    }
    return text;
}

/**
 * Text of a scale label of RadialGauge, LinearGauge and IndustrialKnob.
 * With precision 0 the value rounded to the nearest integer; otherwise no decimals for a
 * whole value and one decimal for any other value, through formatFixed().
 */
function scaleLabelText(value, precision) {
    if (precision === 0) {
        return String(Math.round(value));
    }
    const isWhole = (value === Math.floor(value));
    return formatFixed(value, isWhole ? 0 : 1);
}
