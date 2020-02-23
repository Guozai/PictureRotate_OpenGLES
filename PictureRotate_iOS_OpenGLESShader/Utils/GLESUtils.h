//
//  GLESUtils.h
//
//  Created by Yiping Guo on 19/2/20.
//  Copyright © 2020 Yiping Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
@import OpenGLES;

@interface GLESUtils : NSObject

// Create a shader object, load the shader source string, and compile the shader.
//
+(GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType;

//
///
/// Load a vertex and fragment shader, create a program object, link program.
/// Errors output to log.
/// vertexShader Vertex shader file handle.
/// fragmentShader Fragment shader file handle.
/// return A new program object linked with the vertex/fragment shader pair, 0 on failure
//
/// Sample call method code
//GLuint vertexShader = [GLESUtils compileShader:@"shader.vert" withType:GL_VERTEX_SHADER];
//GLuint fragmentShader = [GLESUtils compileShader:@"shader.frag" withType:GL_FRAGMENT_SHADER];
//
//programHandle = [GLESUtils loadShader:vertexShader withFragmentShader:fragmentShader];
//if (programHandle == 0) {
//    NSLog(@" >> Error: Failed to load shaders.");
//    return;
//}
//
//glUseProgram(programHandle);
//

+(GLuint)loadShader:(GLuint)vertexShader withFragmentShader:(GLuint)fragmentShader;

// Load texture
// png is the default texture file format]
//
// Sample call method code to load for_test.png
//[GLESUtils loadTexture:@"for_test"];
//
+(GLuint)loadTexture:(NSString *)fileName;

@end
