const componentTypes = [
    "runner",
    "memory",
    "disk",
    "network",
    "gpu",
    "vram",
    "diskio",
    "codex",
    "claude"
];

function defaultSettings(type) {
    switch (type) {
    case "runner":
        return {
            runner: "cat",
            useIdleFrame: true,
            idleThreshold: 2,
            speedPercent: 100,
            flipHorizontally: false,
            reverseSpeed: false,
            showCpuUsage: false,
            showCpuTemperature: false,
            temperatureUnit: "celsius"
        };
    case "codex":
        return {showText: false};
    case "claude":
        return {showText: false, contextWindow: 200000};
    case "gpu":
        return {
            showText: false,
            showGpuTemperature: false,
            temperatureUnit: "celsius"
        };
    case "vram":
        return {showText: false};
    case "memory":
    case "disk":
        return {showText: false};
    default:
        return {};
    }
}

function boundedNumber(value, fallback, minimum, maximum) {
    const number = Number(value);
    if (!Number.isFinite(number)) {
        return fallback;
    }
    return Math.max(minimum, Math.min(maximum, Math.round(number)));
}

function normalizedSettings(type, source) {
    const value = source && typeof source === "object" ? source : {};
    const defaults = defaultSettings(type);

    if (type === "runner") {
        const runnerIds = [
            "cat", "dog", "slime", "drop", "coffee",
            "newton-cradle", "engine", "mochi"
        ];
        return {
            runner: runnerIds.indexOf(value.runner) >= 0
                ? value.runner : defaults.runner,
            useIdleFrame: value.useIdleFrame === undefined
                ? defaults.useIdleFrame : Boolean(value.useIdleFrame),
            idleThreshold: boundedNumber(
                value.idleThreshold, defaults.idleThreshold, 0, 25
            ),
            speedPercent: boundedNumber(
                value.speedPercent, defaults.speedPercent, 25, 200
            ),
            flipHorizontally: value.flipHorizontally === undefined
                ? defaults.flipHorizontally : Boolean(value.flipHorizontally),
            reverseSpeed: value.reverseSpeed === undefined
                ? defaults.reverseSpeed : Boolean(value.reverseSpeed),
            showCpuUsage: value.showCpuUsage === undefined
                ? defaults.showCpuUsage : Boolean(value.showCpuUsage),
            showCpuTemperature: value.showCpuTemperature === undefined
                ? defaults.showCpuTemperature
                : Boolean(value.showCpuTemperature),
            temperatureUnit: value.temperatureUnit === "fahrenheit"
                ? "fahrenheit" : defaults.temperatureUnit
        };
    }

    if (type === "codex") {
        return {
            showText: value.showText === undefined
                ? defaults.showText : Boolean(value.showText)
        };
    }

    if (type === "claude") {
        return {
            showText: value.showText === undefined
                ? defaults.showText : Boolean(value.showText),
            contextWindow: boundedNumber(
                value.contextWindow === undefined
                    ? value.claudeContextWindow : value.contextWindow,
                defaults.contextWindow,
                10000,
                2000000
            )
        };
    }

    if (type === "gpu") {
        return {
            showText: value.showText === undefined
                ? defaults.showText : Boolean(value.showText),
            showGpuTemperature: value.showGpuTemperature === undefined
                ? defaults.showGpuTemperature
                : Boolean(value.showGpuTemperature),
            temperatureUnit: value.temperatureUnit === "fahrenheit"
                ? "fahrenheit" : defaults.temperatureUnit
        };
    }

    if (type === "memory" || type === "disk" || type === "vram") {
        return {
            showText: value.showText === undefined
                ? defaults.showText : Boolean(value.showText)
        };
    }

    return {};
}

function definition(type, settings) {
    return {
        type: type,
        settings: normalizedSettings(type, settings)
    };
}

function defaultComponents() {
    return [definition("runner", {})];
}

function normalize(value) {
    let source = value;
    if (typeof source === "string") {
        try {
            source = JSON.parse(source);
        } catch (error) {
            return defaultComponents();
        }
    }
    if (!Array.isArray(source)) {
        return defaultComponents();
    }

    const result = [];
    const seen = {};
    const hasLegacyCpu = source.some(function(item) {
        return item && String(item.type || "") === "cpu";
    });
    const hasLegacyTemperature = source.some(function(item) {
        return item && String(item.type || "") === "cpuTemperature";
    });
    const hasRunner = source.some(function(item) {
        return item && String(item.type || "") === "runner";
    });
    for (let index = 0; index < source.length; ++index) {
        const item = source[index];
        const type = item && String(item.type || "");
        if (type === "ai") {
            const settings = item.settings && typeof item.settings === "object"
                ? item.settings : {};
            const legacyDaily = Boolean(settings.showDaily);
            const showCodex = settings.showCodex === undefined
                ? true : Boolean(settings.showCodex) || legacyDaily;
            const showClaude = settings.showClaude === undefined
                ? true : Boolean(settings.showClaude) || legacyDaily;
            if (showCodex && !seen.codex) {
                seen.codex = true;
                result.push(definition("codex", {showText: true}));
            }
            if (showClaude && !seen.claude) {
                seen.claude = true;
                result.push(definition("claude", {
                    showText: true,
                    contextWindow: settings.claudeContextWindow
                }));
            }
            continue;
        }
        if (type === "cpu" || type === "cpuTemperature") {
            if (!hasRunner && !seen.runner) {
                seen.runner = true;
                result.push(definition("runner", {
                    showCpuUsage: hasLegacyCpu,
                    showCpuTemperature: hasLegacyTemperature
                }));
            }
            continue;
        }
        if (componentTypes.indexOf(type) < 0 || seen[type]) {
            continue;
        }
        seen[type] = true;
        if (type === "runner" && (hasLegacyCpu || hasLegacyTemperature)) {
            const settings = Object.assign({}, item.settings || {});
            if (hasLegacyCpu) {
                settings.showCpuUsage = true;
            }
            if (hasLegacyTemperature) {
                settings.showCpuTemperature = true;
            }
            result.push(definition(type, settings));
        } else {
            result.push(definition(type, item.settings));
        }
    }
    return result;
}

function serialize(value) {
    return JSON.stringify(normalize(value));
}

function find(value, type) {
    const components = normalize(value);
    for (let index = 0; index < components.length; ++index) {
        if (components[index].type === type) {
            return components[index];
        }
    }
    return null;
}

function migrateLegacy(configuration) {
    const result = [definition("runner", {
        runner: configuration.runner,
        useIdleFrame: configuration.useIdleFrame,
        idleThreshold: configuration.idleThreshold,
        speedPercent: configuration.speedPercent,
        flipHorizontally: configuration.flipHorizontally,
        reverseSpeed: configuration.reverseSpeed,
        showCpuUsage: configuration.showCpuUsage,
        showCpuTemperature: configuration.showCpuTemperature,
        temperatureUnit: "celsius"
    })];
    if (configuration.showMemoryUsage) {
        result.push(definition("memory", {}));
    }
    if (configuration.showDiskUsage) {
        result.push(definition("disk", {}));
    }
    if (configuration.showNetworkRate) {
        result.push(definition("network", {}));
    }
    if (configuration.showCodexTokenUsage
            || configuration.showClaudeTokenUsage
            || configuration.showDailyTokenUsage) {
        if (configuration.showCodexTokenUsage
                || configuration.showDailyTokenUsage) {
            result.push(definition("codex", {showText: true}));
        }
        if (configuration.showClaudeTokenUsage
                || configuration.showDailyTokenUsage) {
            result.push(definition("claude", {
                showText: true,
                contextWindow: configuration.claudeContextWindow
            }));
        }
    }
    return result;
}
