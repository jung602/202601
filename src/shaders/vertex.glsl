varying vec2 vUv;

attribute vec3 aInitialPosition;
attribute float aMeshSpeed;
attribute vec4 aTextureCoords;
attribute float aLayerIndex;
attribute float aAspectRatio;


uniform float uTime;
uniform vec2 uMaxXdisplacement;
uniform vec2 uDrag;

uniform float uSpeedY;
uniform float uScrollY;


varying float vVisibility;
varying vec4 vTextureCoords;
varying float vAspectRatio;


//linear smoothstep
float remap(float value, float originMin, float originMax)
{
    return clamp((value - originMin) / (originMax - originMin),0.,1.);
}

void main()
{     
    // Scale card width based on image aspect ratio (height is fixed at 1)
    vec3 scaledPosition = position;
    scaledPosition.x *= aAspectRatio; // width = height * aspectRatio
    
    vec3 newPosition = scaledPosition + aInitialPosition;

    float maxX = uMaxXdisplacement.x;
    float maxY = uMaxXdisplacement.y;

    float maxYoffset = distance(aInitialPosition.y,maxY);
    float minYoffset = distance(aInitialPosition.y,-maxY);

    
    float maxXoffset = distance(aInitialPosition.x,maxX);
    float minXoffset = distance(aInitialPosition.x,-maxX);
    
    
    float xDisplacement = mod(minXoffset -uDrag.x + uTime * aMeshSpeed, maxXoffset+minXoffset) - minXoffset;
    float yDisplacement = mod(minYoffset -uDrag.y, maxYoffset+minYoffset) - minYoffset;

    // Layer-based visibility with zoom effect
    // All layers start at same Z range (-8 to -3) for consistent sizing
    // Scroll causes current layer to zoom in (move towards camera) and fade out
    // NO infinite scroll - stops at layer 4 (2025)
    
    int layerIdx = int(aLayerIndex);
    
    // Base Z position (already set in layer range -8 to -3)
    float baseZ = aInitialPosition.z;
    
    // Scroll parameters (no infinite loop)
    float layerDuration = 15.0; // Each layer is visible for this scroll range
    
    // Clamp scroll to valid range (0 to 75, where 60-75 is for 2026 page)
    float clampedScroll = clamp(uScrollY, 0.0, 75.0);
    
    // Calculate this layer's scroll range
    float layerScrollStart = float(layerIdx) * layerDuration;
    float layerScrollEnd = layerScrollStart + layerDuration;
    
    // Calculate scroll position relative to this layer
    float scrollWithinLayer = clampedScroll - layerScrollStart;
    
    // Zoom effect: as we scroll through this layer, it moves towards camera
    // At start of layer: Z stays at baseZ (normal size)
    // At end of layer: Z moves forward by ~12 units (zooms in, gets bigger)
    float zoomAmount = 12.0;
    float zoomProgress = clamp(scrollWithinLayer / layerDuration, 0.0, 1.0);
    float zOffset = zoomProgress * zoomAmount;
    
    newPosition.z = baseZ + zOffset;
    
    newPosition.x += xDisplacement; 
    newPosition.y += yDisplacement;

    // Calculate visibility
    float fadeZone = 4.0;
    
    // Check if we're in this layer's scroll range
    float distFromStart = clampedScroll - layerScrollStart;
    float distFromEnd = layerScrollEnd - clampedScroll;
    
    // Fade in at start of layer (from behind)
    float fadeIn = smoothstep(-fadeZone, fadeZone, distFromStart);
    // Fade out at end of layer (as it zooms past camera)
    float fadeOut = smoothstep(0.0, fadeZone, distFromEnd);
    
    vVisibility = fadeIn * fadeOut;

    vec4 modelPosition = modelMatrix * instanceMatrix * vec4(newPosition, 1.0);        

    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    gl_Position = projectedPosition;    

    vUv = uv;
    vTextureCoords = aTextureCoords;
    vAspectRatio = aAspectRatio;
}