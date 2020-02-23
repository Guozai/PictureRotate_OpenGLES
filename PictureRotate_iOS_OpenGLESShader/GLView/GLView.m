//
//  GLView.m
//  OpenGLES04
//
//  Created by Yiping Guo on 17/2/20.
//  Copyright © 2020 Yiping Guo. All rights reserved.
//

#import "GLView.h"
@import OpenGLES;
#import "GLESUtils.h"

typedef struct
{
    float position[3];
    float texCoordinates[2];
} CustomVertex;

enum
{
    ATTRIBUTE_POSITION = 0,
    ATTRIBUTE_TEXTURE_COORDINATES,
    NUM_ATTRIBUTES
};
GLint glViewAttributes[NUM_ATTRIBUTES];

@implementation GLView

#pragma mark - Life Cycle
- (void)dealloc {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }

    _context = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    if (CGSizeEqualToSize(_oldSize, CGSizeZero) || !CGSizeEqualToSize(_oldSize, size)) {
        [self setup];
        _oldSize = size;
    }
    
    [self render];
}

#pragma mark - Override
// 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Setup
- (void)setup {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    NSError *error;
    NSAssert1([self checkFramebuffer:&error], @"%@",error.userInfo[@"ErrorMessage"]);
    
    [self loadShaders];
    [self setupVBOs];
    [GLESUtils loadTexture:@"for_test"];
}

- (void)setupLayer {
    // 用于显示的layer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    
    //  CALayer默认是透明的，而透明的层对性能负荷很大。所以将其关闭。
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    if (!_context) {
        // 创建GL环境上下文
        // EAGLContext 管理所有通过 OpenGL 进行 Draw 的信息.
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
}

- (void)setupRenderBuffer {
    // 释放旧的 renderbuffer
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    // 生成renderbuffer ( renderbuffer = 用于展示的窗口 )
    glGenRenderbuffers(1, &_renderbuffer);
    // 绑定renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    // 释放旧的 framebuffer
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    // 生成 framebuffer ( framebuffer = 画布 )
    glGenFramebuffers(1, &_framebuffer);
    // 绑定 fraembuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // framebuffer 不对绘制的内容做存储, 所以这一步是将 framebuffer 绑定到 renderbuffer ( 绘制的结果就存在 renderbuffer )
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderbuffer);
}

#pragma mark - Private
- (BOOL)checkFramebuffer:(NSError *__autoreleasing *)error {
    // 检查 framebuffer 是否创建成功
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSString *errorMessage = nil;
    BOOL result = NO;
    
    switch (status)
    {
        case GL_FRAMEBUFFER_UNSUPPORTED:
            errorMessage = @"framebuffer不支持该格式";
            result = NO;
            break;
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"framebuffer 创建成功");
            result = YES;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            errorMessage = @"Framebuffer不完整 缺失组件";
            result = NO;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            errorMessage = @"Framebuffer 不完整, 附加图片必须要指定大小";
            result = NO;
            break;
        default:
            // 一般是超出GL纹理的最大限制
            errorMessage = @"未知错误 error !!!!";
            result = NO;
            break;
    }
    
    NSLog(@"%@",errorMessage ? errorMessage : @"");
    *error = errorMessage ? [NSError errorWithDomain:@"com.colin.error"
                                                code:status
                                            userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
    
    return result;
}

- (void)loadShaders {
    // Compile shaders
    GLuint vertexShader = [GLESUtils compileShader:@"shader.vert" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [GLESUtils compileShader:@"shader.frag" withType:GL_FRAGMENT_SHADER];
    
    programHandle = [GLESUtils loadShader:vertexShader withFragmentShader:fragmentShader];
    if (programHandle == 0) {
        NSLog(@" >> Error: Failed to load shaders .");
        return;
    }
    
    glUseProgram(programHandle);
    
    // Get attributes from shader
    glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(programHandle, "position");
    glViewAttributes[ATTRIBUTE_TEXTURE_COORDINATES] = glGetAttribLocation(programHandle, "texCoordinates");
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_TEXTURE_COORDINATES]);
}

- (void)setupVBOs {
    static const CustomVertex vertices[] =
    {
        { .position = {  0.5f, -0.5f, -1.0f }, .texCoordinates = { 1.0f, 0.0f } },
        { .position = { -0.5f,  0.5f, -1.0f }, .texCoordinates = { 0.0f, 1.0f } },
        { .position = { -0.5f, -0.5f, -1.0f }, .texCoordinates = { 0.0f, 0.0f } },
        { .position = {  0.5f,  0.5f, -1.0f }, .texCoordinates = { 1.0f, 1.0f } },
        { .position = { -0.5f,  0.5f, -1.0f }, .texCoordinates = { 0.0f, 1.0f } },
        { .position = {  0.5f, -0.5f, -1.0f }, .texCoordinates = { 1.0f, 0.0f } }
    };
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
}

- (void)render {
    // 因为 GL 的所有 API 都是基于最后一次绑定的对象作为作用对象。有很多错误是因为没有绑定或者绑定了错误的对象导致得到了错误的结果。
    // 所以每次在修改 GL 对象时，先绑定一次要修改的对象。
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glClearColor(0, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; // 获取视图放大倍数，可以把scale设置为1试试
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION], 3, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), NULL);
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_TEXTURE_COORDINATES], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(NULL + sizeof(float) * 3));
    
    // 获取shader里面的变量，这里记得要在glLinkProgram后面
    GLuint rotate = glGetUniformLocation(programHandle, "rotateMatrix");
    
    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    // z轴旋转矩阵
    GLfloat zRotation[16] =
    {
        c, -s, 0, 0.2,
        s, c, 0, 0,
        0, 0, 1.0, 0,
        0.0, 0, 0, 1.0
    };
    
    // 设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 做完所有绘制操作后，最终呈现到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
