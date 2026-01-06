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
    
    // Frame parameters (in physical units, height = 1)
    float padding = 0.03; // Physical padding (same on all sides)
    float cornerRadius = 0.06; // Physical corner radius
    float innerCornerRadius = 0.03; // Physical inner corner radius
    
    // Convert UV to centered coordinates (-0.5 to 0.5)
    vec2 centered = vUv - 0.5;
    
    // Convert to physical coordinates (height = 1, width = aspectRatio)
    vec2 physical = centered;
    physical.x *= vAspectRatio;
    
    // Physical halfSize of the card
    vec2 outerHalfSize = vec2(0.5 * vAspectRatio, 0.5);
    vec2 innerHalfSize = vec2(0.5 * vAspectRatio - padding, 0.5 - padding);
    
    // Calculate SDF in physical space (radius is now uniform)
    float outerDist = roundedBoxSDF(physical, outerHalfSize, cornerRadius);
    float innerDist = roundedBoxSDF(physical, innerHalfSize, innerCornerRadius);
    
    // Discard pixels outside the outer frame
    if(outerDist > 0.0) discard;
    
    // Get UV coordinates for this image from the uniform array
    float xStart = vTextureCoords.x;
    float xEnd = vTextureCoords.y;
    float yStart = vTextureCoords.z;
    float yEnd = vTextureCoords.w;

    // Remap UV for the image area (account for padding in UV space)
    float paddingX = padding / vAspectRatio; // Convert physical padding to UV space
    float paddingY = padding;
    vec2 imageUV = vec2(
        (vUv.x - paddingX) / (1.0 - 2.0 * paddingX),
        (vUv.y - paddingY) / (1.0 - 2.0 * paddingY)
    );
    
    // Image now fits card exactly (no cover crop needed)
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