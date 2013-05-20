//
//  Shader.fsh
//  test
//
//  Created by Jean-Baptiste Rieu on 20/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
