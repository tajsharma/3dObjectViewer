#version 300 es

// an attribute will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;
in vec3 a_tangent;
in vec2 a_texture_coord;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

out vec3 v_pos;
out vec2 text_coord;
out vec3 v_normal;
out mat3 TBN;
// output to fragment stage
// TODO: Create varyings to pass data to the fragment stage (position, texture coords, and more)

void main() {

    // transform a vertex from object space directly to screen space
    // the full chain of transformations is:
    // object space -{model}-> world space -{view}-> view space -{projection}-> clip space
    vec4 vertex_position_world = u_m * vec4(a_position, 1.0);
    text_coord = a_texture_coord;

    vec3 T = normalize(vec3(u_m * vec4(a_tangent, 0.0)));
    vec3 N = normalize(vec3(u_m * vec4(a_normal, 0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N,T);
    // TODO: Construct TBN matrix from normals, tangents and bitangents
    mat3 TBN = mat3(T,B,N);
    vec3 v_normal1 = normalize(transpose(inverse(mat3(u_m))) * a_normal);
    vec3 v_pos = vertex_position_world.xyz;
    v_normal = v_normal1.xyz;
    // TODO: Use the Gram-Schmidt process to re-orthogonalize tangents
    // NOTE: Different from the book, try to do all calculations in world space using the TBN to transform normals
    // HINT: Refer to https://learnopengl.com/Advanced-Lighting/Normal-Mapping for all above
    // TODO: Forward data to fragment stage
    gl_Position = u_p * u_v * vertex_position_world;

}