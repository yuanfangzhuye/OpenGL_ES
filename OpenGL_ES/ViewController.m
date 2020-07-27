//
//  ViewController.m
//  OpenGL_ES
//
//  Created by tlab on 2020/7/27.
//  Copyright © 2020 yuanfangzhuye. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    EAGLContext *context;
    GLKBaseEffect *effect;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupConfig];
    [self setupVertexDatas];
    [self setupTexture];
}

- (void)setupConfig {
    
    //1.初始化上下文&设置当前上下文
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Create Context Failed");
    }
    
    //设置当前上下文
    [EAGLContext setCurrentContext:context];
    
    //2.获取GLKView & 设置context
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    
    //3.配置视图创建的渲染缓存区
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    //4.设置背景颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
}

- (void)setupVertexDatas {
    
    //1.设置顶点数组(顶点坐标,纹理坐标)
    GLfloat vertexData[] = {
        0.5f, 0.5f, 0.0f,    1.0f, 1.0f,
        -0.5f, 0.5f, 0.0f,    0.0f, 1.0f,
        -0.5f, -0.5f, 0.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, 0.0f,    1.0f, 1.0f,
        -0.5f, -0.5f, 0.0f,    0.0f, 0.0f,
        0.5f, -0.5f, 0.0f,    1.0f, 0.0f
    };
    
    /**
     顶点数组:                                      开发者可以选择设定函数指针，在调用绘制方法的时候，直接由内存传入顶点数据，也就是说这部分数据之前是存储在内存当中的，被称为顶点数组
     
     顶点缓存区: 性能更高的做法是，提前分配一块显存，将顶点数据预先传入到显存当中。这部分的显存，就被称为顶点缓冲区
     */
    
    //2.开辟顶点缓存区
    //(1).创建顶点缓存区标识符ID
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    
    //(2).绑定顶点缓存区.(明确作用)
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    
    //(3).将顶点数组的数据copy到顶点缓存区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    //顶点坐标数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    //纹理坐标数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 5, (GLfloat *)NULL + 3);
}

- (void)setupTexture {
    
    //1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timg" ofType:@"png"];
    
    //2.设置纹理参数(纹理坐标原点是左下角，但是图片显示原点应该是左上角)
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //3.使用苹果GLKit 提供GLKBaseEffect 完成着色器工作(顶点/片元)
    effect = [[GLKBaseEffect alloc] init];
    effect.texture2d0.enabled = GL_TRUE;
    effect.texture2d0.name = textureInfo.name;
}

#pragma mark ------ GLKViewDelegate

/**
 GLKView对象使其OpenGL ES上下文成为当前上下文，并将其framebuffer绑定为OpenGL ES呈现命令的目标。然后，委托方法应该绘制视图的内容。
 */

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //1.清空缓存
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.设置投影
    /**
     透视投影矩阵。由于平截头体可视范围的问题，我们需要将顶点向后移2.0单位
     */
    [self setSquarePerspective];
    
    //3.准备绘制
    [effect prepareToDraw];
    
    //4.开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

- (void)setSquarePerspective {
    
    CGFloat aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 1.0f, 200.0f);
    effect.transform.projectionMatrix = projectMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.0);
    effect.transform.modelviewMatrix = modelViewMatrix;
}


@end
