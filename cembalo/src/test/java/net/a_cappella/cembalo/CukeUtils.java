package net.a_cappella.cembalo;

public class CukeUtils {
    public static double parseDoubleNaN(String str) {
        if (str == null) return Double.NaN;
        if (str.trim().isEmpty()) return Double.NaN;
        if ("NaN".equalsIgnoreCase(str)) return Double.NaN;
        if ("Inf".equalsIgnoreCase(str)) return Double.POSITIVE_INFINITY;
        if ("-Inf".equalsIgnoreCase(str)) return Double.NEGATIVE_INFINITY;
        return Double.parseDouble(str);
    }
    public static double parseDouble(String str) {
        if (str == null) return 0.0;
        if (str.trim().isEmpty()) return 0.0;
        return Double.parseDouble(str);
    }
}
