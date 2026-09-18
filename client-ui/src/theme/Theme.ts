export type Color = readonly [number, number, number, number];

export const theme = {
    spacing: { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 },
    control: { sm: 28, md: 36, lg: 44 },
    colors: {
        background: [0.018, 0.024, 0.034, 0.98] as Color,
        surface: [0.032, 0.044, 0.060, 1] as Color,
        surfaceRaised: [0.047, 0.063, 0.084, 1] as Color,
        surfaceHover: [0.065, 0.086, 0.112, 1] as Color,
        border: [0.12, 0.16, 0.21, 1] as Color,
        borderStrong: [0.22, 0.30, 0.39, 1] as Color,
        text: [0.94, 0.96, 0.99, 1] as Color,
        muted: [0.62, 0.68, 0.76, 1] as Color,
        primary: [0.20, 0.57, 0.96, 1] as Color,
        success: [0.20, 0.82, 0.45, 1] as Color,
        warning: [0.95, 0.67, 0.20, 1] as Color,
        error: [0.93, 0.28, 0.31, 1] as Color,
        tank: [0.20, 0.58, 0.98, 1] as Color,
        healer: [0.18, 0.78, 0.42, 1] as Color,
        dps: [0.91, 0.31, 0.30, 1] as Color
    }
} as const;
