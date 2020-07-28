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
    
    //1.OpenGL ES 相关初始化
    [self setupConfig];
    
    //2.加载顶点/纹理坐标数据
    [self setupVertexDatas];
    
    //3.加载纹理数据(使用GLBaseEffect)
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
    /**
     1⃣️drawableColorFormat：颜色缓存区格式
     OpenGL ES 有一个缓存区，它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个像素的颜色格式。
     
     GLKViewDrawableColorFormatRGBA8888 = 0,
     默认.缓存区的每个像素的最小组成部分（RGBA）使用8个bit，（所以每个像素4个字节，4*8个bit）
     
     GLKViewDrawableColorFormatRGB565,
     如果你的APP允许更小范围的颜色，即可设置这个。会让你的APP消耗更小的资源（内存和处理时间）
     
     2⃣️drawableDepthFormat: 深度缓存区格式
     
     GLKViewDrawableDepthFormatNone = 0,意味着完全没有深度缓冲区
     GLKViewDrawableDepthFormat16,
     GLKViewDrawableDepthFormat24,
     如果你要使用这个属性（一般用于3D游戏），你应该选择GLKViewDrawableDepthFormat16
     或GLKViewDrawableDepthFormat24。这里的差别是使用GLKViewDrawableDepthFormat16
     将消耗更少的资源
     */
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
    //参数1：目标
    //参数2：坐标数据的大小
    //参数3：坐标数据
    //参数4：用途
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    //3. 打开读取通道
    /**
     ⚠️
     在iOS中，出于性能考虑，所有顶点着色器的属性（Attribute）变量通道都是默认关闭的，这就意味着顶点数据在着色器端（服务端）是不可用的，即使你已经使用 glBufferData 方法，将顶点数据从内存拷贝到顶点缓存区中（GPU显存中）。所以，必须由 glEnableVertexAttribArray 方法打开通道，指定访问属性，才能让顶点着色器能够访问到从 CPU 复制到 GPU 的数据。
     
     数据在 GPU 端是否可见，即着色器能否读取到数据，由是否启用了对应的属性决定，这就是 glEnableVertexAttribArray 的功能，允许顶点着色器读取 GPU（服务器端）数据。
     */
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    //4. 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
    /**
     参数1：传递顶点坐标的类型有五种类型：position[顶点]、normal[法线]、color[颜色]、texCoord0[纹理一]、texCoord1[纹理二]，这里用的是顶点类型
     参数2：每次读取数量（如 position 是由3个（x,y,z）组成，而颜色是4个（r,g,b,a），纹理则是2个）
     参数3：指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT
     参数4：指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
     参数5：步长，取完一次数据需要跨越多少步长去读取下一个数据，如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
     参数6：指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
     */
    // 上传顶点数据到显存（设置合适的方式从 buffer 里面读取数据）
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    //纹理坐标数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 5, (GLfloat *)NULL + 3);
}

- (void)setupTexture {
    
    //1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timg" ofType:@"png"];
    
    /**
    ⚠️注意：
    iOS 的坐标计算是从左上角 [0, 0] 开始，到右下角 [1, 1]。但是在文里中的原点不是左上角，而是左下角 [0, 0]，右上角[1, 1]。所以如果想要正确的加载图片，需要设置纹理的原点为左下角。否则得到的图片将会是一张倒立的图片。
    */
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
