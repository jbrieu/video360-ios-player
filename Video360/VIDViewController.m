//
//  VIDViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 08/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDViewController.h"

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

typedef struct {
    float Position[3];
    float Normal[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {0, 0, 1}, {1, 0, 0, 1}, {1, 1}},
    {{1, 1, 0},  {0, 0, 1},{0, 1, 0, 1},{1, 0} },
    {{-1, 1, 0},  {0, 0, 1},{0, 0, 1, 1},{0, 0}},
    {{-1, -1, 0},  {0, 0, 1},{0, 0, 0, 1},{0, 1}}
};


const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIBUT_COLOR,
    ATTRIBUT_TEXCOORD,
    NUM_ATTRIBUTES
};



@interface VIDViewController ()
{
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    //    float _rotation;
    
    GLuint _vertexArray;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _textureBuffer;
    
    CGPoint _startPoint;
    CGFloat _dx;
    CGFloat _dy;
    
    AVPlayerItemVideoOutput* _videoOutput;
    AVPlayer* _player;
    AVPlayerItem* _playerItem;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
	CVOpenGLESTextureCacheRef _videoTextureCache;
    const GLfloat *_preferredConversion;
    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation VIDViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    _startPoint = CGPointMake(0.0f, 0.0f);
    
    // Set the default conversion to BT.709, which is the standard for HDTV.
    _preferredConversion = kColorConversion709;
    
    [self setupGL];
    
    [self setupVideoPlayback];
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}

#pragma mark video methods
#warning TODO : porter sur iOS5

-(void)setupVideoPlayback
{
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        
        NSError* error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
        if (status == AVKeyValueStatusLoaded)
        {
            NSDictionary* settings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]};
            _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
            _playerItem = [AVPlayerItem playerItemWithAsset:asset];
            [_playerItem addOutput:_videoOutput];
            _player = [AVPlayer playerWithPlayerItem:_playerItem];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_player play];
            });
            
        }
        else
        {
            NSLog(@"%@ Failed to load the tracks.", self);
        }
    }];
}


#pragma mark touch events
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    _startPoint = [touch locationInView:self.view];
    
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    _dx = point.y - _startPoint.y;
    _dy = point.x - _startPoint.x;
    _startPoint = point;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    glUseProgram(_program);

    
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Vertex
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    // Index
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    // Position
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    // Color
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    // Normals
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Normal));
    
    // Texture
    glActiveTexture(GL_TEXTURE0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glGenBuffers(1, &_textureBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _textureBuffer);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_DYNAMIC_DRAW);
    
    // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
	if (!_videoTextureCache) {
		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
		if (err != noErr) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
			return;
		}
	}
    
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);    
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, 0.0f, 0.0f, 1.0f, 0.0f);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _startPoint.x/100, 0.0f, 1.0f, 0.0f);
    _dx = _dy = 0;
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    //    _rotation += self.timeSinceLastUpdate * 0.5f;
    
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if(_chromaTexture)
    {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    
	// Periodic texture cache flush every frame
	CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:[_playerItem currentTime] itemTimeForDisplay:nil];
    
    CVReturn err;
	if (pixelBuffer != NULL) {
		int frameWidth = CVPixelBufferGetWidth(pixelBuffer);
		int frameHeight = CVPixelBufferGetHeight(pixelBuffer);
		
		if (!_videoTextureCache) {
			NSLog(@"No video texture cache");
			return;
		}
		
		[self cleanUpTextures];
		
		
		/*
		 Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
		 */
		CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
		
		if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
			_preferredConversion = kColorConversion601;
		}
		else {
			_preferredConversion = kColorConversion709;
		}
		
        
        glActiveTexture(GL_TEXTURE0);
		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
														   _videoTextureCache,
														   pixelBuffer,
														   NULL,
														   GL_TEXTURE_2D,
														   GL_RED_EXT,
														   frameWidth,
														   frameHeight,
														   GL_RED_EXT,
														   GL_UNSIGNED_BYTE,
														   0,
														   &_lumaTexture);
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
		
		glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// UV-plane.
		glActiveTexture(GL_TEXTURE1);
		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
														   _videoTextureCache,
														   pixelBuffer,
														   NULL,
														   GL_TEXTURE_2D,
														   GL_RG_EXT,
														   frameWidth / 2,
														   frameHeight / 2,
														   GL_RG_EXT,
														   GL_UNSIGNED_BYTE,
														   1,
														   &_chromaTexture);
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
		
		glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        CFRelease(pixelBuffer);
    }
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    
    
    glUseProgram(_program);
    
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);

    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}
#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribColor, "color");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
	uniforms[UNIFORM_Y] = glGetUniformLocation(_program, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(_program, "SamplerUV");
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(_program, "colorConversionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


@end
