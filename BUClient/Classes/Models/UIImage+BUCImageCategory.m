#import "UIImage+BUCImageCategory.h"
#import <ImageIO/ImageIO.h>
#import "BUCDataManager.h"


#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

@implementation UIImage (BUCImageCategory)

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

static int createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count], CFDictionaryRef options) {
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    for (int i = 0; i < count; ++i) {
        if ([dataManager cancelFlag]) {
            return i;
        }
        imagesOut[i] = CGImageSourceCreateThumbnailAtIndex(source, i, options);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
    
    return 0;
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage * const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f] = frame;
            f = f + 1;
        }
    }
    
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count]) {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

static UIImage *animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source, CFDictionaryRef options) {
    UIImage *output;
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count]; // in centiseconds
    int imageCount = createImagesAndDelays(source, count, images, delayCentiseconds, options);
    if (imageCount > 0) {
        releaseImages(imageCount, images);
        return nil;
    }
    
    int const totalDurationCentiseconds = sum(count, delayCentiseconds);
    NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
    
    if (frames) {
        NSTimeInterval duration = (NSTimeInterval)totalDurationCentiseconds / 100.0;
        if (frames.count <= 10 && duration / frames.count <= 0.01) {
            duration = duration * 8;
        }
        output = [UIImage animatedImageWithImages:frames duration:duration];
    }
    
    releaseImages(count, images);
    return output;
}

static int maxDimension(CFDictionaryRef properties, CGSize fitSize) {
    NSNumber *width;
    NSNumber *height;
    CGFloat scaledWidth;
    CGFloat scaledHeight;

    
    width = (NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    height = (NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    
    CGFloat targetRatio = fitSize.width / fitSize.height;
    CGFloat imageRatio = width.floatValue / height.floatValue;
    
    if (targetRatio > imageRatio) {
        scaledWidth = width.floatValue * fitSize.height / height.floatValue;
        scaledHeight = fitSize.height;
    } else {
        scaledWidth = fitSize.width;
        scaledHeight = height.floatValue * fitSize.width / width.floatValue;
    }
    
    return floorf(MAX(scaledWidth, scaledHeight));
}


+ (UIImage *)imageWithData:(NSData *)data size:(CGSize)size {
    UIImage *output;
    CGImageRef image = NULL;
    CGImageSourceRef source = NULL;
    CFDictionaryRef properties = NULL;
    NSString *type;
    NSMutableDictionary *options;
    
    source = CGImageSourceCreateWithData(toCF data, NULL);
    if (!source) {
        goto cleanup;
    }
    
    options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
               (id)kCFBooleanTrue, (id)kCGImageSourceShouldCache,
               nil];
    
    properties = CGImageSourceCopyPropertiesAtIndex(source, 0, toCF options);
    if (!properties) {
        goto cleanup;
    }
    
    if (size.width > 0) {
        [options setObject:[NSNumber numberWithInt:maxDimension(properties, size)] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
    }
    [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
    [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
    
    type = (NSString *)CGImageSourceGetType(source);
    if ([type isEqualToString:@"com.compuserve.gif"]) {
        output = animatedImageWithAnimatedGIFImageSource(source, toCF options);
    } else {
        image = CGImageSourceCreateThumbnailAtIndex(source, 0, toCF options);
        output = [UIImage imageWithCGImage:image];
    }
    
cleanup:
    if (source) {
        CFRelease(source);
    }
    if (properties) {
        CFRelease(properties);
    }
    if (image) {
        CFRelease(image);
    }
    
    return output;
}


+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end












