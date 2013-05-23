//
//  Shader.vsh
//  
//
//  Created by Jean-Baptiste Rieu on 20/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord;

varying vec2 v_textureCoordinate;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    v_textureCoordinate = texCoord;
    gl_Position = modelViewProjectionMatrix * position;
}
