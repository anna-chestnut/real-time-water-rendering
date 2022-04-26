#shader vertex
#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTex;

out vec2 TexCoord;
//out vec3 Normal_TS_in;

void main()
{
    //vs_out.color = aColor;
    //gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    TexCoord = aTex;
    //Normal_TS_in = vec3(0, 1, 0);
}


#shader tesscontrol
#version 410 core

layout(vertices = 4) out;

//uniform mat4 model;
//uniform mat4 view;

in vec2 TexCoord[];
//in vec3 Normal_TS_in[];
out vec2 TextureCoord[];
//out vec3 Normal_TE_in[];

void main()
{
    float num = 960.0;//480
    gl_TessLevelOuter[0] = num;
    gl_TessLevelOuter[1] = num;
    gl_TessLevelOuter[2] = num;
    gl_TessLevelOuter[3] = num;

    gl_TessLevelInner[0] = num*2;
    gl_TessLevelInner[1] = num*2;

    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    TextureCoord[gl_InvocationID] = TexCoord[gl_InvocationID];
    //Normal_TE_in[gl_InvocationID] = Normal_TS_in[gl_InvocationID];
}


#shader tessevaluation
#version 410 core
layout(quads, equal_spacing, ccw) in;

uniform sampler2D heightMap;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform unsigned int degree;

in vec2 TextureCoord[];
//in vec3 Normal_TE_in[];

//out float Height;
out vec3 tePosition;
out vec2 teTexCoord;
out vec3 Normal_FS_in;

vec4 interpolate(vec4 v0, vec4 v1, vec4 v2, vec4 v3) {

    vec4 a = mix(v0, v1, gl_TessCoord.x);
    vec4 b = mix(v3, v2, gl_TessCoord.x);
    return mix(a, b, gl_TessCoord.y);
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2)
{
    return vec3(gl_TessCoord.x) * v0 + vec3(gl_TessCoord.y) * v1 + vec3(gl_TessCoord.z) * v2;
}

void main()
{
    /*gl_Position = (gl_TessCoord.x * gl_in[0].gl_Position +
        gl_TessCoord.y * gl_in[1].gl_Position +
        gl_TessCoord.z * gl_in[2].gl_Position);*/
    //Normal_GS_in = interpolate3D(Normal_TE_in[0], Normal_TE_in[1], Normal_TE_in[2]);
    //Normal_GS_in = normalize(Normal_GS_in);

    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    vec2 t00 = TextureCoord[0];
    vec2 t01 = TextureCoord[1];
    vec2 t10 = TextureCoord[3];
    vec2 t11 = TextureCoord[2];

    vec2 t0 = (t01 - t00) * u + t00;
    vec2 t1 = (t11 - t10) * u + t10;
    teTexCoord = (t1 - t0) * v + t0;

    //vec3 normal = texture(heightMap, texCoord).rgb;
    //normal = normalize(normal * 2.0 - 1.0);

    float heightValue = 1;

    //heightColor = texture(heightMap, texCoord).rgb;
    vec2 offset1 = vec2(0.5, 0.1) * degree * 0.0005;//vec2(0.8, 0.4)
    vec2 offset2 = vec2(0.4, 0.7) * degree * 0.0005;//vec2(0.6, 1.1)
    
    float hight1 = texture(heightMap, teTexCoord + offset1).z * heightValue;
    float hight2 = texture(heightMap, teTexCoord + offset2).z * heightValue;
    float Height = hight1 + hight2;// hight1 + hight2;
    //Height = texture(heightMap, teTexCoord).y * 10.0;// * 64.0 - 16.0
    
    vec4 inter = interpolate(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position, gl_in[3].gl_Position);
    vec4 newPos = vec4(inter.x, inter.y + Height, inter.z, 1.0);

    vec3 texCoord_origin = vec3(0, Height, 0);

    vec2 teTexCoord_x = teTexCoord + vec2(0.001, 0);
    vec2 teTexCoord_y = teTexCoord + vec2(0, 0.001);

    hight1 = texture(heightMap, teTexCoord_x + offset1).z * heightValue;
    hight2 = texture(heightMap, teTexCoord_x + offset2).z * heightValue;
    float Height_x = hight1 + hight2;

    hight1 = texture(heightMap, teTexCoord_y + offset1).z * heightValue;
    hight2 = texture(heightMap, teTexCoord_y + offset2).z * heightValue;
    float Height_y = hight1 + hight2;
    
    vec3 texCoord_x = vec3(teTexCoord_x.x, texture(heightMap, teTexCoord_x + Height_x).z, 0);
    vec3 texCoord_y = vec3(0, texture(heightMap, teTexCoord_y + Height_y).z, teTexCoord_y.y);

    vec3 x_vector = texCoord_x - texCoord_origin;
    vec3 y_vector = texCoord_y - texCoord_origin;

   // //without animation
   //float h = texture(heightMap, teTexCoord).z * 2;
   // newPos = vec4(inter.x, inter.y + h, inter.z, 1.0);

   // float x_h = texture(heightMap, teTexCoord_x).z * 2;
   // float y_h = texture(heightMap, teTexCoord_y).z * 2;

   // x_vector = vec3(teTexCoord_x.x, texture(heightMap, teTexCoord_x + x_h).y - h, 0);
   // y_vector = vec3(0, texture(heightMap, teTexCoord_y + x_h).y - h, teTexCoord_y.y);

    Normal_FS_in = cross(y_vector, x_vector);// cross(x_vector, y_vector);
    Normal_FS_in = normalize(mat3(transpose(inverse(view * model))) * Normal_FS_in);
       
    gl_Position = projection * view * model * newPos;
    tePosition = vec3(model * newPos).xyz;
}


//#shader geometry
//#version 330 core
//
//layout(triangles) in;
//layout(line_strip, max_vertices = 3) out;
//
////in vec3 tePosition[3];
////out vec3 gPosition;
//
//in vec2 teTexCoord[3];
//in vec3 Normal_GS_in[3];
//out vec2 gTexCoord;
//out vec3 Normal_FS_in;
//
//void main() {
//    //build_house(gl_in[0].gl_Position);
//
//    gl_Position = gl_in[0].gl_Position;
//    gTexCoord = teTexCoord[0];
//    //gPosition = tePosition[0];
//    Normal_FS_in = Normal_GS_in[0];
//    EmitVertex();
//
//    gl_Position = gl_in[1].gl_Position;
//    gTexCoord = teTexCoord[1];
//    Normal_FS_in = Normal_GS_in[1];
//    //gPosition = tePosition[1];
//    EmitVertex();
//
//    gl_Position = gl_in[2].gl_Position;
//    gTexCoord = teTexCoord[2];
//    Normal_FS_in = Normal_GS_in[2];
//    //gPosition = tePosition[2];
//    EmitVertex();
//
//    //gl_Position = gl_in[0].gl_Position;
//    //gTexCoord = teTexCoord[0];
//    //EmitVertex();
//
//    EndPrimitive();
//
//}


#shader fragment
#version 330 core
out vec4 FragColor;

//in float Height;
//in vec2 gTexCoord;
in vec2 teTexCoord;
in vec3 Normal_FS_in;
//in vec3 Normal_GS_in;
in vec3 tePosition;

uniform samplerCube skybox;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform sampler2D normalMap;

void main()
{
    vec3 normal = Normal_FS_in;//Normal_FS_in;

    vec3 col = vec3(0.137255, 0.419608, 0.556863);//rich blue vec3(0.35, 0.35, 0.67);//vec3(0.419608, 0.137255, 0.556863);
    vec3 viewDir = normalize(viewPos - tePosition);

    vec3 I = normalize(tePosition - viewPos);
    vec3 R = reflect(I, normal);
    float reflectiveFactor = dot(viewDir, normal);
    reflectiveFactor = pow(reflectiveFactor, 3);
    //FragColor = vec4(texture(skybox, R).rgb, 1.0);
    float ratio = 1.00 / 1.33;
    vec3 R_refract = refract(I, normal, ratio);

    col = mix(texture(skybox, R).rgb, vec3(0.137255, 0.419608, 0.556863), reflectiveFactor);//mix(texture(skybox, R).rgb, texture(skybox, R_refract).rgb, reflectiveFactor);


    vec3 ambient = col;

    //vec3 normal = texture(normalMap, teTexCoord).rgb;
    // transform normal vector to range [-1,1]
    //normal = normalize(normal * 2.0 - 1.0);  // this normal is in tangent space

     //Normal_FS_in;// vec3(0, 1, 0);

    // diffuse 
    vec3 lightDir = normalize(lightPos - tePosition);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * col;

    // specular
   
    vec3 reflectDir = reflect(-lightDir, normal);
    float specular = pow(max(dot(viewDir, reflectDir), 0.0), 64);

    vec3 result = (ambient);// + diffuse + specular

    FragColor = vec4(Normal_FS_in, 1.0);

    /*float h = (Height) / 10.0f;
    FragColor = vec4(h, 0.0, 0.0, 1.0);*/
}
