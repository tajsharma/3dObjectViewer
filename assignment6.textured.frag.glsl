#version 300 es

#define MAX_LIGHTS 16

// Fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default. It means "medium precision".
precision mediump float;

uniform bool u_show_normals;

// struct definitions
struct AmbientLight {
    vec3 color;
    float intensity;
};

struct DirectionalLight {
    vec3 direction;
    vec3 color;
    float intensity;
};

struct PointLight {
    vec3 position;
    vec3 color;
    float intensity;
};

struct Material {
    vec3 kA;
    vec3 kD;
    vec3 kS;
    float shininess;
    sampler2D map_kD;
    sampler2D map_nS;
    sampler2D map_norm;
};

// lights and materials
uniform AmbientLight u_lights_ambient[MAX_LIGHTS];
uniform DirectionalLight u_lights_directional[MAX_LIGHTS];
uniform PointLight u_lights_point[MAX_LIGHTS];

uniform Material u_material;

// camera position in world space
uniform vec3 u_eye;

// with webgl 2, we now have to define an out that will be the color of the fragment
out vec4 o_fragColor;

// received from vertex stage
// TODO: Create variables to receive from the vertex stage
in vec3 v_pos;
in vec2 text_coord;
in vec3 v_normal;
in mat3 TBN;

// Shades an ambient light and returns this light's contribution
vec3 shadeAmbientLight(Material material, AmbientLight light) {
    // TODO: Implement this
    // TODO: Include the material's map_kD to scale kA and to provide texture even in unlit areas
    // NOTE: We could use a separate map_kA for this, but most of the time we just want the same texture in unlit areas
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    vec3 result = light.color * light.intensity * material.kA * texture(material.map_kD, text_coord).rgb;
    return result;
}

// Shades a directional light and returns its contribution
vec3 shadeDirectionalLight(Material material, DirectionalLight light, vec3 normal, vec3 eye, vec3 vertex_position) {
    
    // TODO: Implement this
    // TODO: Use the material's map_kD and map_nS to scale kD and shininess
    // HINT: The darker pixels in the roughness map (map_nS) are the less shiny it should be
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    vec3 normalized = normalize(normal);
    vec3 lightN = normalize(light.direction);
    vec3 reflection = reflect(lightN, normalized);
    vec3 nEye = normalize(vertex_position - eye);
    vec3 sKD = texture(material.map_kD, text_coord).rgb;
    vec3 sNS = texture(material.map_nS, text_coord).rgb;

    float specCoef = pow(max(dot(nEye, reflection), 0.0), material.shininess);
    float lambertCoef = max(dot(normalized, -lightN), 0.0);
    vec3 result = vec3(0);
    result += lambertCoef * light.color * light.intensity* material.kD* sKD;

    result += pow(max(dot(reflection, nEye),0.0),material.shininess * sNS.r) * light.color * light.intensity * material.kS ;

    return result;
}

// Shades a point light and returns its contribution
vec3 shadePointLight(Material material, PointLight light, vec3 normal, vec3 eye, vec3 vertex_position) {

    // TODO: Implement this
    // TODO: Use the material's map_kD and map_nS to scale kD and shininess
    // HINT: The darker pixels in the roughness map (map_nS) are the less shiny it should be
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    vec3 directionLight = vertex_position - light.position;
    vec3 normalized = normalize(normal);
    vec3 lightD = normalize(directionLight);
    vec3 V = normalize(vertex_position - eye);
    vec3 reflection = reflect(lightD, normalized);
    float distBetween = length(directionLight);
    vec3 sKD = texture(material.map_kD, text_coord).rgb;
    vec3 sNS = texture(material.map_nS, text_coord).rgb;

    float lCoef = max(dot(lightD, normalized), 0.0);

    // Return total contribution from diffuse and specular
    vec3 result = vec3(0);
    result += lCoef * light.color * light.intensity * material.kD * sKD;
    result += pow(max(dot(reflection, V),0.0),material.shininess * sNS.r) * light.color * light.intensity * material.kS ;

    return result;
}

void main() {

    // TODO: Calculate the normal from the normal map and tbn matrix to get the world normal
    vec3 normal = vec3(0,0,0);
    normal = texture(u_material.map_norm, text_coord).rgb;
    normal = normal * 2.0 - 1.0;
    normal = normalize(TBN* normal);

    // if we only want to visualize the normals, no further computations are needed
    // !do not change this code!
    if (u_show_normals == true) {
        o_fragColor = vec4(normal, 1.0);
        return;
    }

    // we start at 0.0 contribution for this vertex
    vec3 light_contribution = vec3(0.0);
    vec3 result = vec3(0);
    vec3 directionC = vec3(0);
    vec3 pointC = vec3(0);
    vec3 ambientC = vec3(0);

    // iterate over all possible lights and add their contribution
    for(int i = 0; i < MAX_LIGHTS; i++) {
        ambientC = ambientC + shadeAmbientLight(u_material, u_lights_ambient[i]);
        directionC = directionC + shadeDirectionalLight(u_material, u_lights_directional[i],v_normal,u_eye, v_pos );
        pointC = pointC + shadePointLight(u_material, u_lights_point[i], v_normal, u_eye, v_pos);
    }

    light_contribution = ambientC + directionC + pointC;

    o_fragColor = vec4(light_contribution, 1.0);
}