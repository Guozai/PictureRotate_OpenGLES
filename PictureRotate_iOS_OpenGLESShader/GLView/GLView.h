//
//  GLView.h
//  OpenGLES04
//
//  Created by Yiping Guo on 17/2/20.
//  Copyright © 2020 Yiping Guo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLView : UIView
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint _framebuffer;
    GLuint _renderbuffer;
    
    CGSize _oldSize;
    GLuint programHandle;
}

@end
