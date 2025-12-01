shader_type spatial;
render_mode cull_disabled; // Resolve o problema de ver "através" do planeta

// ==============================================================================
// CONFIGURAÇÕES GERAIS
// ==============================================================================
group_uniforms Planet_Settings;
uniform float sea_level = 50.0; // AJUSTE ISSO IGUAL AO RAIO DO SEU PLANETA!
uniform float beach_size = 2.0; // Tamanho da faixa de areia
uniform float snow_height = 80.0; // Altura onde a neve eterna começa (Pico da montanha)
uniform float uv_scale = 0.05; // Controla o Zoom da textura (0.05 = texturas grandes)
// ==============================================================================
// CORES DOS BIOMAS (Baseado na sua imagem)
// ==============================================================================
group_uniforms Water_Beach;
uniform vec3 color_water : source_color = vec3(0.0, 0.2, 0.8); // Água / Mar
uniform vec3 color_beach : source_color = vec3(0.76, 0.70, 0.50); // Praia / Costa

group_uniforms Hot_Biomes;
uniform vec3 color_desert  : source_color = vec3(0.85, 0.75, 0.50); // Deserto (Areia seca)
uniform vec3 color_savanna : source_color = vec3(0.60, 0.65, 0.20); // Savana (Grama amarelada)

group_uniforms Temperate_Biomes;
uniform vec3 color_forest  : source_color = vec3(0.15, 0.50, 0.15); // Floresta Temp. (Verde padrão)
uniform sampler2D tex_forest : source_color;


group_uniforms Cold_Biomes;
uniform vec3 color_taiga   : source_color = vec3(0.10, 0.30, 0.20); // Taiga (Verde escuro/Pinheiros)
uniform vec3 color_tundra  : source_color = vec3(0.40, 0.45, 0.35); // Tundra (Vegetação morta/Marrom)

group_uniforms High_Biomes;
uniform vec3 color_alpine  : source_color = vec3(0.40, 0.40, 0.40); // Alpino (Rocha exposta)
uniform vec3 color_snow    : source_color = vec3(1.00, 1.00, 1.00); // Neve Eterna

// Variável para passar a altura do Vertex para o Fragment
varying float altura_real;
varying vec3 pos_mundo;





void vertex() {
	// Calcula a distância do centro (0,0,0) até o vértice
	altura_real = length(VERTEX);
	pos_mundo = VERTEX;
}

// FUNÇÃO TRIPLANAR (Projeta a textura de 3 lados)
vec3 get_triplanar(sampler2D tex, vec3 pos, vec3 normal) {
	vec3 blend = abs(normal);
	blend /= blend.x + blend.y + blend.z; // Normaliza os pesos
	
	// Escala UV (Zoom)
	vec2 uv_x = pos.zy * uv_scale;
	vec2 uv_y = pos.xz * uv_scale;
	vec2 uv_z = pos.xy * uv_scale;
	
	// Amostra a textura
	vec3 col_x = texture(tex, uv_x).rgb;
	vec3 col_y = texture(tex, uv_y).rgb;
	vec3 col_z = texture(tex, uv_z).rgb;
	
	// Mistura
	return col_x * blend.x + col_y * blend.y + col_z * blend.z;
}

void fragment() {
	// Lê o valor que você pintou (0.0 a 1.0)
	float id = COLOR.r;

	vec3 final_color = vec3(0.0);
	float final_roughness = 0.9;

	// --- SELETOR DE 9 BIOMAS (Faixas de 10% / 0.1) ---

	// 0% (0.0) -> Água
	if (id < 0.05) {
		final_color = color_water;
		final_roughness = 0.2;
	}
	// 10% (0.1) -> Praia
	else if (id < 0.15) {
		final_color = color_beach;
		final_roughness = 0.8;
	}
	// 20% (0.2) -> Deserto
	else if (id < 0.25) {
		final_color = color_desert;
	}
	// 30% (0.3) -> Savana
	else if (id < 0.35) {
		final_color = color_savanna;
	}
	// 40% (0.4) -> Floresta
	else if (id < 0.45) {
		final_color = get_triplanar(tex_forest, pos_mundo, NORMAL); // 50%//color_forest;
	}
	// 50% (0.5) -> Taiga
	else if (id < 0.55) {
		final_color = color_taiga;
	}
	// 60% (0.6) -> Tundra
	else if (id < 0.65) {
		final_color = color_tundra;
	}
	// 70% (0.7) -> Alpino / Rocha
	else if (id < 0.75) {
		final_color = color_alpine;
	}
	// 80%+ (0.8) -> Neve
	else {
		final_color = color_snow;
	}

	// SAÍDA
	ALBEDO = final_color;
	ROUGHNESS = final_roughness;
	METALLIC = 0.0;
}


//void fragment() {
	//// LENDO OS DADOS DO SCRIPT GDScript
	//float temp = COLOR.r;  // Temperatura
	//float moist = COLOR.g; // Umidade
	//
	//vec3 final_color = vec3(0.0);
	//float final_roughness = 0.9;
	//float final_specular = 0.0;
//
	//// -----------------------------------------------------------------------
	//// ESTRUTURA IF / ELSE (Para corrigir o erro do return)
	//// -----------------------------------------------------------------------
	//
	//if (altura_real <= sea_level) {
		//// --- É MAR ---
		//final_color = color_water;
		//final_roughness = 0.2; // Água brilha
		//final_specular = 0.5;
	//}
	//else if (altura_real < sea_level + beach_size) {
		//// --- É PRAIA ---
		//final_color = color_beach;
		//final_roughness = 0.8;
	//}
	//else {
		//// --- É TERRA FIRME (Aqui entra a lógica dos Biomas) ---
		//
		//// 1. Definição Base (Diagrama de Whitaker)
		//if (temp < 0.2) {
			//// ZONA POLAR
			//if (moist > 0.5) final_color = color_snow;
			//else final_color = color_tundra;
		//}
		//else if (temp < 0.45) {
			//// ZONA BOREAL
			//if (moist < 0.3) final_color = color_alpine;
			//else if (moist < 0.6) final_color = color_tundra;
			//else final_color = color_taiga;
		//}
		//else if (temp < 0.75) {
			//// ZONA TEMPERADA
			//if (moist < 0.3) final_color = color_savanna;
			//else final_color = color_forest;
		//}
		//else {
			//// ZONA TROPICAL
			//if (moist < 0.3) final_color = color_desert;
			//else if (moist < 0.6) final_color = color_savanna;
			//else final_color = color_forest;
		//}
//
		//// 2. Regra do Pico da Montanha (Neve por altitude)
		//// Só aplicamos isso se já estamos na terra (dentro deste 'else')
		//float altitude_solo = altura_real - sea_level;
		//
		//if (altitude_solo > snow_height) {
			//final_color = color_snow;
		//}
		//else if (altitude_solo > snow_height - 10.0) {
			//final_color = color_alpine;
		//}
	//}
//
	//// --- SAÍDA FINAL (Só atribui no final) ---
	//ALBEDO = final_color;
	//ROUGHNESS = final_roughness;
	//SPECULAR = final_specular;
	//METALLIC = 0.0;
//}