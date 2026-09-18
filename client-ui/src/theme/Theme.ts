export type Color = readonly [number, number, number, number];

export const theme = {
    spacing: { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 },
    control: { sm: 28, md: 36, lg: 44 },
    colors: {
        background: [0.012, 0.018, 0.026, 0.985] as Color,
        scrim: [0.0, 0.0, 0.0, 0.62] as Color,
        surface: [0.025, 0.035, 0.048, 1] as Color,
        surfaceRaised: [0.038, 0.052, 0.071, 1] as Color,
        surfaceHover: [0.055, 0.075, 0.100, 1] as Color,
        border: [0.075, 0.105, 0.145, 1] as Color,
        borderStrong: [0.145, 0.205, 0.275, 1] as Color,
        text: [0.94, 0.96, 0.99, 1] as Color,
        muted: [0.58, 0.65, 0.74, 1] as Color,
        primary: [0.20, 0.57, 0.96, 1] as Color,
        success: [0.20, 0.82, 0.45, 1] as Color,
        warning: [0.95, 0.67, 0.20, 1] as Color,
        error: [0.93, 0.28, 0.31, 1] as Color,
        tank: [0.20, 0.58, 0.98, 1] as Color,
        healer: [0.18, 0.78, 0.42, 1] as Color,
        dps: [0.91, 0.31, 0.30, 1] as Color
    }
} as const;
