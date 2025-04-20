set datafile separator ","
set title "Benchmark: Bun vs Node.js"
set xlabel "Runtime"
set ylabel "Requests per Second"
set grid
set xtics rotate by -45
set style data histograms
set style fill solid
set boxwidth 0.5

# Correct terminal for PNG output on macOS
set terminal pngcairo size 1000,600 enhanced font 'Menlo,12'

# Output to PNG file
set output "benchmark-results.png"

# Skip header row in CSV and plot requests per second (column 3) vs runtime (column 1)
plot "benchmark-results.csv" using 3:xtic(1) title "Requests/sec", \
     "benchmark-results.csv" using 2:xtic(1) title "Boot Time (ms)", \
     "benchmark-results.csv" using 4:xtic(1) title "Transfer/sec"