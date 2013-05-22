//
//  Shader.vsh
//  test



//
//  Created by Jean-Baptiste Rieu on 20/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

attribute vec4 position;
attribute vec3 normal;
attribute vec4 color;
attribute vec2 texCoord;

varying vec2 v_textureCoordinate;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    vec4 diffuseColor = color;
    
    float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                 
    v_textureCoordinate = texCoord;
    gl_Position = modelViewProjectionMatrix * position;
}
