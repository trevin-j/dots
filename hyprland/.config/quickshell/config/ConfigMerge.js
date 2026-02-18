function isObject(value) {
    return value !== null && value !== undefined && typeof value === "object" && !Array.isArray(value);
}

function deepMerge(baseValue, overrideValue) {
    if (overrideValue === undefined) {
        return baseValue;
    }
    if (!isObject(baseValue) || !isObject(overrideValue)) {
        return overrideValue;
    }

    const result = {};
    const keys = Object.keys(baseValue).concat(Object.keys(overrideValue));
    for (const key of keys) {
        if (Object.prototype.hasOwnProperty.call(result, key)) {
            continue;
        }
        result[key] = deepMerge(baseValue[key], overrideValue[key]);
    }
    return result;
}

function mergeWithDefaults(defaults, overrides) {
    return deepMerge(defaults, overrides || ({}));
}
