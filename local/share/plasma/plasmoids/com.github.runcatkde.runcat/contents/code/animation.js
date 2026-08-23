.pragma library

function clamp(value, minimum, maximum) {
    return Math.min(maximum, Math.max(minimum, value));
}

function smooth(previous, current, alpha) {
    const weight = clamp(alpha, 0, 1);
    return previous + (current - previous) * weight;
}

function cycleDuration(cpuUsage, slowCycleMs, fastCycleMs, reverseSpeed) {
    const low = Math.min(slowCycleMs, fastCycleMs);
    const high = Math.max(slowCycleMs, fastCycleMs);
    const boundedCpu = clamp(cpuUsage, 0, 100);
    const load = (reverseSpeed ? 100 - boundedCpu : boundedCpu) / 100;

    // Geometric interpolation emphasizes changes near the fast end while
    // preserving the configured minimum and maximum cycle durations.
    const speed = Math.pow(load, 0.55);
    return high * Math.pow(low / high, speed);
}

function frameInterval(cpuUsage, frameCount, slowCycleMs, fastCycleMs, maxFps,
                       reverseSpeed, speedPercent) {
    const frames = Math.max(1, frameCount);
    const numericSpeed = Number(speedPercent);
    const speedScale = Number.isFinite(numericSpeed)
        ? clamp(numericSpeed, 25, 200) / 100
        : 1;
    const fps = Math.max(1, maxFps) * Math.max(1, speedScale);
    const desired = cycleDuration(
        cpuUsage,
        slowCycleMs,
        fastCycleMs,
        reverseSpeed
    ) / frames / speedScale;
    return Math.max(1000 / fps, desired);
}
