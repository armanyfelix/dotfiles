function finiteNonnegative(value) {
    const number = Number(value);
    return Number.isFinite(number) ? Math.max(0, number) : 0;
}

function fixedValue(value) {
    // Values below the promotion threshold must never round to a four-digit
    // integer part. Keep the visible maximum at 999.9 instead.
    return Math.min(999.9, finiteNonnegative(value)).toFixed(1);
}

function formatPercent(value) {
    return Math.min(100, Math.round(finiteNonnegative(value))) + "%";
}

function formatBinary(bytes, perSecond) {
    const units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"];
    let value = finiteNonnegative(bytes);
    let unitIndex = 0;

    // Promote at 1000 for a compact three-digit integer field, while keeping
    // IEC conversion (1024 of one unit equals one of the next unit).
    while (value >= 1000 && unitIndex < units.length - 1) {
        value /= 1024;
        unitIndex += 1;
    }

    return fixedValue(value) + " " + units[unitIndex]
        + (perSecond ? "/s" : "");
}

function formatBytes(bytes) {
    return formatBinary(bytes, false);
}

function formatRate(bytesPerSecond) {
    return formatBinary(bytesPerSecond, true);
}

function formatTokens(tokens) {
    const units = ["", "k", "m", "b", "t"];
    let value = finiteNonnegative(tokens);
    let unitIndex = 0;

    while (value >= 1000 && unitIndex < units.length - 1) {
        value /= 1000;
        unitIndex += 1;
    }

    return fixedValue(value) + units[unitIndex];
}

function widestBinaryText(perSecond) {
    // M is normally the widest IEC prefix glyph in proportional UI fonts.
    return "999.9 MiB" + (perSecond ? "/s" : "");
}

function widestTokenText() {
    // Likewise, m is wider than the other compact token suffixes.
    return "999.9m";
}

function tabularFont(baseFont) {
    return Qt.font({
        family: baseFont.family,
        pointSize: baseFont.pointSize,
        weight: baseFont.weight,
        italic: baseFont.italic,
        underline: baseFont.underline,
        strikeout: baseFont.strikeout,
        capitalization: baseFont.capitalization,
        letterSpacing: baseFont.letterSpacing,
        wordSpacing: baseFont.wordSpacing,
        hintingPreference: baseFont.hintingPreference,
        kerning: baseFont.kerning,
        preferShaping: baseFont.preferShaping,
        features: {"tnum": 1}
    });
}
