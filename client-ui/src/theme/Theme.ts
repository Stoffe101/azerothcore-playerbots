export type Color = readonly [number, number, number, number];

export const theme = {
    spacing: { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 },
    control: { sm: 28, md: 36, lg: 44 },
    colors: {
        background: [0.008, 0.013, 0.020, 0.992] as Color,
        scrim: [0.0, 0.0, 0.0, 0.62] as Color,
        surface: [0.020, 0.030, 0.043, 1] as Color,
        surfaceRaised: [0.034, 0.049, 0.068, 1] as Color,
        surfaceHover: [0.050, 0.074, 0.102, 1] as Color,
        border: [0.070, 0.100, 0.138, 1] as Color,
        borderStrong: [0.130, 0.195, 0.270, 1] as Color,
        text: [0.94, 0.96, 0.99, 1] as Color,
        muted: [0.58, 0.65, 0.74, 1] as Color,
        primary: [0.22, 0.62, 1.00, 1] as Color,
        success: [0.20, 0.82, 0.45, 1] as Color,
        warning: [0.95, 0.67, 0.20, 1] as Color,
        error: [0.93, 0.28, 0.31, 1] as Color,
        tank: [0.20, 0.58, 0.98, 1] as Color,
        healer: [0.18, 0.78, 0.42, 1] as Color,
        dps: [0.91, 0.31, 0.30, 1] as Color,
        chrome: [0.52, 0.36, 0.14, 1] as Color,
        chromeBright: [0.93, 0.68, 0.24, 1] as Color,
        surfaceDeep: [0.010, 0.018, 0.030, 1] as Color,
        surfaceBlue: [0.018, 0.055, 0.095, 1] as Color,
        highlight: [0.42, 0.75, 1.00, 1] as Color,
        shadow: [0.0, 0.0, 0.0, 0.72] as Color
    }
} as const;
