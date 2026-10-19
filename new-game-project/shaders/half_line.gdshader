shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    float aa = max(fwidth(UV.y), 0.005);

    float mask = smoothstep(
        0.48 - aa * 0.5,
        0.48 + aa * 0.5,
        UV.y
    );

    COLOR.a *= mask;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
