
using Plots

x = 1:10  # x-Koordinaten
y = 1:10  # y-Koordinaten
z = [rand() for _ in 1:10, _ in 1:10]  # z-Werte (zufällige Beispieldaten)
w = [rand(10) for _ in 1:10, _ in 1:10]  # w-Werte (zufällige Beispieldaten für die vierte Dimension)
display(heatmap(x=x, y=y, z=z, color=w, colorbar_title="W"))    



# Beispielmatrix mit komplexen Zahlen
matrix = rand(ComplexF64, (5, 5, 128))  # Eine 5x5-Matrix, wobei jeder Eintrag ein Vektor der Länge 128 ist

# Vektor erstellen
vector = reshape(matrix, 128, 5*5)


# Beispielmatrix
matrix = [rand(ComplexF64, 5, 5) for _ in 1:128]



using Interact
using Plots

# Funktion, die verschiedene Plots erzeugt
function generate_plot(index)
    # Hier kannst du verschiedene Plots basierend auf dem Index erstellen
    if index == 1
        plot([1, 2, 3], [4, 5, 6], xlabel = "X", ylabel = "Y", title = "Plot 1")
    elseif index == 2
        plot([1, 2, 3], [7, 8, 9], xlabel = "X", ylabel = "Y", title = "Plot 2")
    elseif index == 3
        plot([1, 2, 3], [10, 11, 12], xlabel = "X", ylabel = "Y", title = "Plot 3")
    end
end

# Slider erstellen
@manipulate for i in 1:3
    generate_plot(i)
end



using Plots
using ImageMagick

# Funktion, die einen Plot für einen bestimmten Index erstellt
function create_plot(index)
    plot(rand(10), title = "Plot $index")
end

# Anzahl der Plots
num_plots = 128

# Array zum Speichern der Plots
frames = []

# Plots für jeden Index erstellen und zum Array hinzufügen
for i in 1:num_plots
    push!(frames, create_plot(i))
    println(typeof(frames))
end

# Gif erstellen und speichern
@time save("animation.gif", frames, fps = 10)