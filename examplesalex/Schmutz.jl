
using Plots

x = 1:10  # x-Koordinaten
y = 1:10  # y-Koordinaten
z = [rand() for _ in 1:10, _ in 1:10]  # z-Werte (zufällige Beispieldaten)
w = [rand(10) for _ in 1:10, _ in 1:10]  # w-Werte (zufällige Beispieldaten für die vierte Dimension)
display(heatmap(x=x, y=y, z=z, color=w, colorbar_title="W"))    


