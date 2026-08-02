import pya

# Load layout
layout = pya.Layout()
layout.read(gds_path)

# Create an independent LayoutView (no GUI required)
view = pya.LayoutView()
view.show_layout(layout, True)

# Load layer properties
view.load_layer_props(lyp_path)
view.set_config("background-color", "#000000")

# Hide fill and top metal layers to show logic routing
for i in view.each_layer():
    name = i.name.lower() if i.name else ""
    if "met4" in name or "met5" in name or "via4" in name or "via3" in name or "fill" in name or "areaid" in name or "prbnd" in name:
        i.visible = False

view.max_hier()
view.zoom_fit()
view.save_image(png_path, 3840, 2160)
print("Saved " + png_path)

