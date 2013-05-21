//
//  Shader.fsh
//  test
//
//  Created by Jean-Baptiste Rieu on 20/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

//varying lowp vec4 colorVarying;

uniform sampler2D s_texture;
varying mediump vec2 v_textureCoordinate;

void main()
{
    //gl_FragColor = colorVarying;
    gl_FragColor = texture2D(s_texture, v_textureCoordinate);
}
