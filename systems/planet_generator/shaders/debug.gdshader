shader_type spatial;
render_mode cull_disabled;
uniform float radius = 50.0;
uniform float min_height = 0.0;

// Variável para passar a altura do Vertex para o Fragment
varying float altura_atual;

void vertex() {
	// Calcula a altura real deste ponto
	altura_atual = length(VERTEX) - radius;
}

void fragment() {
	// Se a altura for quase zero (Mar), pinta de Azul
	if (altura_atual <= min_height + 0.5) {
		ALBEDO = vec3(0.0, 0.2, 0.8); // Azul
		ROUGHNESS = 0.2;
	} 
	// Senão (Continente), pinta de Branco
	else {
		ALBEDO = vec3(1.0, 1.0, 1.0); // Branco
		ROUGHNESS = 0.8;
	}
}