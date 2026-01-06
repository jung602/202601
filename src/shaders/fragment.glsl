varying vec2 vUv;
varying float vVisibility;
varying vec4 vTextureCoords;
varying float vAspectRatio;

uniform sampler2D uAtlas;
uniform sampler2D uBlurryAtlas;

// Signed distance function for rounded rectangle
float roundedBoxSDF(vec2 center, vec2 halfSize, float radius) {
    vec2 q = abs(center) - halfSize + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void main()
{            
    // Discard if not visible (prevents ghost frames)
    if(vVisibility < 0.01) discard;
    
    // Frame parameters
    float padding = 0.03; // 8px equivalent padding ratio
    float cornerRadius = 0.06; // Rounded corner radius
    float innerCornerRadius = 0.03; // Inner rounded corner radius
    
    // Convert UV to centered coordinates (-0.5 to 0.5)
    vec2 centered = vUv - 0.5;
    
    // Outer frame bounds (full card)
    float outerDist = roundedBoxSDF(centered, vec2(0.5, 0.5), cornerRadius);
    
    // Inner image bounds (with padding)
    float innerDist = roundedBoxSDF(centered, vec2(0.5 - padding, 0.5 - padding), innerCornerRadius);
    
    // Discard pixels outside the outer frame
    if(outerDist > 0.0) discard;
    
    // Get UV coordinates for this image from the uniform array
    float xStart = vTextureCoords.x;
    float xEnd = vTextureCoords.y;
    float yStart = vTextureCoords.z;
    float yEnd = vTextureCoords.w;

    // Remap UV for the image area (account for padding)
    vec2 imageUV = (vUv - padding) / (1.0 - 2.0 * padding);
    
    // Apply cover effect: scale UV to fill card while maintaining aspect ratio
    float cardAspect = 1.0 / 1.69; // card width/height ratio
    float imageAspect = vAspectRatio;
    
    if (imageAspect > cardAspect) {
        // Image is wider than card: scale to fit height, crop width
        float scale = cardAspect / imageAspect;
        imageUV.x = (imageUV.x - 0.5) * scale + 0.5;
    } else {
        // Image is taller than card: scale to fit width, crop height
        float scale = imageAspect / cardAspect;
        imageUV.y = (imageUV.y - 0.5) * scale + 0.5;
    }
    
    imageUV = clamp(imageUV, 0.0, 1.0);
    
    vec2 atlasUV = vec2(
        mix(xStart, xEnd, imageUV.x),
        mix(yStart, yEnd, 1.0 - imageUV.y)
    );     

    vec4 blurryTexel = texture2D(uBlurryAtlas, atlasUV);
    vec4 imageTexel = texture2D(uAtlas, atlasUV);

    // Determine if we're in the frame area or image area
    bool isFrame = innerDist > 0.0;
    
    // Color: frame uses blurry background, image area uses actual image
    vec4 color;
    if(isFrame) {
        // Frame area: use blurry background with slight darkening
        color = blurryTexel * 0.8;
        color.a = 1.0;
    } else {
        // Image area
        color = imageTexel;
    }

    color.a *= vVisibility;

    color.r = min(color.r, 1.);
    color.g = min(color.g, 1.);
    color.b = min(color.b, 1.);

    gl_FragColor = color;
}