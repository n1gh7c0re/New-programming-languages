// word_count.d
import std.stdio;
import std.file;
import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.parallelism;
import std.string;
import std.range;
import std.format;

// Tokenize entire text into words (keeps letters and digits, supports Unicode letters)
string[] tokenize(string s) {
    // Replace any run of non-letter/non-digit characters with a single space
    auto cleaned = replaceAll(s, regex("[^\\p{L}\\p{N}]+"), " ");
    auto parts = cleaned.split();
    string[] res;
    foreach (p; parts) {
        auto w = p.toLower();
        if (w.length > 0)
            res ~= w;
    }
    return res;
}

// Top-level worker (no captures) that counts words in a slice
size_t[string] countSlice(string[] slice) {
    size_t[string] local;
    foreach (w; slice) {
        if (w.length == 0) continue;
        local[w] += 1;
    }
    return local;
}

struct Pair { string word; size_t count; }

void main() {
    // Read config.json (simple robust approach)
    size_t threads = 4;
    try {
        auto cfgText = cast(string) read("config.json");
        import std.regex : matchFirst;
        auto m = matchFirst(cfgText, regex("\"threads\"\\s*:\\s*(\\d+)"));
        if (m.hit) threads = to!size_t(m.captures[1]);
        if (threads < 1) threads = 1;
    } catch (Exception e) {
        writeln("Warning: cannot read config.json - using default threads=4. (", e.msg, ")");
    }

    // Read input text
    string text;
    try {
        text = cast(string) read("input.txt");
    } catch (Exception e) {
        writeln("Error: cannot read input.txt - ", e.msg);
        return;
    }

    // Tokenize whole text into words (prevents boundary-splitting)
    auto words = tokenize(text);
    size_t n = words.length;
    if (n == 0) {
        writeln("No words found in input.txt");
        auto f0 = File("word_counts.csv", "w");
        f0.writeln("word,count");
        f0.close();
        return;
    }

    // Partition the words array into slices for threads
    size_t chunkSize = (n + threads - 1) / threads;
    import std.range : iota;
    string[][] slices;
    slices.length = threads;
    foreach (i; 0 .. threads) {
        size_t start = i * chunkSize;
        size_t end = start + chunkSize;
        if (start >= n) slices[i] = [];
        else {
            if (end > n) end = n;
            slices[i] = words[start .. end];
        }
    }

    // Parallel count using top-level function
    auto partials = taskPool.map!countSlice(slices).array;

    // Merge partial maps
    size_t[string] merged;
    foreach (m; partials) {
        foreach (k, v; m) merged[k] += v;
    }

    // Convert to array of pairs and sort by count desc then word asc
    Pair[] pairs;
    pairs.reserve(merged.length);
    foreach (k, v; merged) pairs ~= Pair(k, v);
    import std.algorithm.sorting : sort;
    pairs.sort!((a, b) {
        if (a.count != b.count) return a.count > b.count;
        return a.word < b.word;
    });

    // Write CSV
    auto f = File("word_counts.csv", "w");
    f.writeln("word,count");
    foreach (p; pairs) {
        auto w = p.word.replace(",", "\\,");
        f.writeln(format("%s,%s", w, p.count));
    }
    f.close();

    writeln("Done. Unique words: ", pairs.length, ". Wrote word_counts.csv");
}
