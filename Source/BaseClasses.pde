// Interface for Things that can be interacted with 
interface Interactable {
    void onGrab(Human human);          // Called when Thing is grabbed
    boolean isGrabbable();             // Returns if Thing can be grabbed
    void onRelease(Human human);       // Called when Thing is released
    void onInteract(Human human);      // Called when SHIFT is pressed when Thing held
}

// Interface for Things that receive key presses
interface KeyEvents {
    void keyDown(char key, int keyCode);
    void keyUp(char key, int keyCode);
}

// Interface for saveable Things
interface Saveable {
    HashMap<String, Object> save();
    void load(HashMap<String, Object> data);
}

// Base class for all game Things
abstract class Thing implements Saveable {
    int id = 0;
    PVector position, velocity, acceleration; // Physics properties
    boolean held, grabbable, rested;
    boolean show = true; // Default is true
    boolean hasPhysics = true; 
    float elasticity = 0, friction = 0.98f;
    int sceneIn = 0; // Scene this Thing belongs to
    float groundHeightOffset = 0;
    float checkTouchRadius = 0;
    boolean checkTouchY = false;
    boolean checkTouchWide = false;
    boolean drawBehindHumans = false;
    boolean drawInBackground = false;
    boolean drawInForeground = false;
    boolean updateInBackground = false;
    float lastReleasedMs = 0;

    Thing() {
        position = new PVector(width / 2, gameManager.window.getGroundHeightAt(width/2));
        velocity = new PVector();
        acceleration = new PVector();
        held = rested = false;
        grabbable = true;
    }

    // Abstract methods - must be implemented by subclasses
    abstract void display();
    
    // Initialize with default position
    void initialize() {
        position.set(width / 2, gameManager.window.getGroundHeightAt(width/2));
        velocity.set(0, 0);
        acceleration.set(0, 0);
    }

    // Initialize with specific position
    void initialize(float startX, float startY) {
        position.set(startX, startY);
        velocity.set(0, 0);
        acceleration.set(0, 0);
    }

    // Update Thing physics
    void update() {
        if (hasPhysics && !this.held && !this.rested) {
            acceleration.y = Constants.Physics.GRAVITY;
            velocity.add(acceleration);
            velocity.limit(Constants.Physics.MAX_VELOCITY);
            position.add(velocity);
        }
    }

    // Check and handle screen boundaries
    void checkEdges() {
        if (!hasPhysics) return;
        
        position.x = constrain(position.x, width * Constants.Physics.LEFT_BOUNDARY, width * Constants.Physics.RIGHT_BOUNDARY);
        
        // Get dynamic ground height at current X position
        float groundY = height * gameManager.window.getGroundHeightAt(position.x);
        float effectiveGroundY = groundY - groundHeightOffset;
        
        position.y = constrain(position.y, height * Constants.Physics.CEILING_HEIGHT, effectiveGroundY);

        // Handle ground collision with bounce
        if (position.y >= effectiveGroundY && abs(velocity.y) > 0.1) {
            velocity.y *= -elasticity;
        } else if (position.y >= effectiveGroundY) {
            velocity.y = 0;
        }

        // Apply friction
        if (friction < 1 && abs(velocity.x) > 0.2) {
            velocity.x *= friction;
        } else {
            velocity.x = 0;
        }
    }
    
    // Check collision with another Thing (default empty implementation)
    void onTouch(Thing other, float distance) {}

    void checkTouch(Thing other) {
        if (checkTouchRadius <= 0) return;
        if (other.held || this.held || other.rested || this.rested || !this.show || !other.show || !(other.sceneIn == this.sceneIn)) return;
        
        float dist;
        if (checkTouchY) {
            dist = PVector.dist(position, other.position);  // Full 2D distance
        } else {
            dist = abs(position.x - other.position.x);      // X-only distance
        }
        
        if (dist < checkTouchRadius) {
            this.onTouch(other, dist);
        }
    }
    
    // Executes this if updateInBackground is true and Thing not in current scene
    void backgroundUpdate() {}
    
    HashMap<String, Object> save() {
        HashMap<String, Object> data = new HashMap<String, Object>();
        
        data.put("id", this.id); 
        
        // Position
        data.put("position.x", this.position.x);
        data.put("position.y", this.position.y);
        
        // Velocity
        if (this.velocity != null) {
            data.put("velocity.x", this.velocity.x);
            data.put("velocity.y", this.velocity.y);
        }
        
        // Acceleration
        if (this.acceleration != null) {
            data.put("acceleration.x", this.acceleration.x);
            data.put("acceleration.y", this.acceleration.y);
        }
        
        // Boolean flags
        data.put("held", this.held);
        data.put("grabbable", this.grabbable);
        data.put("rested", this.rested);
        data.put("show", this.show);
        data.put("hasPhysics", this.hasPhysics);
        data.put("checkTouchY", this.checkTouchY);
        data.put("checkTouchWide", this.checkTouchWide);
        data.put("drawBehindHumans", this.drawBehindHumans);
        data.put("drawInBackground", this.drawInBackground);
        data.put("drawInForeground", this.drawInForeground);
        data.put("updateInBackground", this.updateInBackground);
        
        // Numeric values
        data.put("elasticity", this.elasticity);
        data.put("friction", this.friction);
        data.put("sceneIn", this.sceneIn);
        data.put("groundHeightOffset", this.groundHeightOffset);
        data.put("checkTouchRadius", this.checkTouchRadius);
        
        return data;
    }
    
    void load(HashMap<String, Object> data) {
        // Position
        if (data.containsKey("position.x") && data.containsKey("position.y")) {
            if (this.position == null) {
                this.position = new PVector();
            }
            this.position.x = ((Number) data.get("position.x")).floatValue();
            this.position.y = ((Number) data.get("position.y")).floatValue();
        }
        
        // Velocity
        if (data.containsKey("velocity.x") && data.containsKey("velocity.y")) {
            if (this.velocity == null) {
                this.velocity = new PVector();
            }
            this.velocity.x = ((Number) data.get("velocity.x")).floatValue();
            this.velocity.y = ((Number) data.get("velocity.y")).floatValue();
        }
        
        // Acceleration
        if (data.containsKey("acceleration.x") && data.containsKey("acceleration.y")) {
            if (this.acceleration == null) {
                this.acceleration = new PVector();
            }
            this.acceleration.x = ((Number) data.get("acceleration.x")).floatValue();
            this.acceleration.y = ((Number) data.get("acceleration.y")).floatValue();
        }
        
        // Boolean flags
        if (data.containsKey("held")) this.held = (boolean) data.get("held");
        if (data.containsKey("grabbable")) this.grabbable = (boolean) data.get("grabbable");
        if (data.containsKey("rested")) this.rested = (boolean) data.get("rested");
        if (data.containsKey("show")) this.show = (boolean) data.get("show");
        if (data.containsKey("hasPhysics")) this.hasPhysics = (boolean) data.get("hasPhysics");
        if (data.containsKey("checkTouchY")) this.checkTouchY = (boolean) data.get("checkTouchY");
        if (data.containsKey("checkTouchWide")) this.checkTouchWide = (boolean) data.get("checkTouchWide");
        if (data.containsKey("drawBehindHumans")) this.drawBehindHumans = (boolean) data.get("drawBehindHumans");
        if (data.containsKey("drawInBackground")) this.drawInBackground = (boolean) data.get("drawInBackground");
        if (data.containsKey("drawInForeground")) this.drawInForeground = (boolean) data.get("drawInForeground");
        if (data.containsKey("updateInBackground")) this.updateInBackground = (boolean) data.get("updateInBackground");
        
        // Numeric values
        if (data.containsKey("elasticity")) this.elasticity = ((Number) data.get("elasticity")).floatValue();
        if (data.containsKey("friction")) this.friction = ((Number) data.get("friction")).floatValue();
        if (data.containsKey("sceneIn")) this.sceneIn = ((Number) data.get("sceneIn")).intValue();
        if (data.containsKey("groundHeightOffset")) this.groundHeightOffset = ((Number) data.get("groundHeightOffset")).floatValue();
        if (data.containsKey("checkTouchRadius")) this.checkTouchRadius = ((Number) data.get("checkTouchRadius")).floatValue();
    }
    
    ArrayList<Thing> getClosestThings(ArrayList<Thing> things, float radius) {
        ArrayList<Thing> nearby = new ArrayList<Thing>();
        for (Thing thing : things) {
            if (thing != null && thing != this && thing.show && thing.sceneIn == this.sceneIn) {
                float dist = PVector.dist(this.position, thing.position);
                if (dist <= radius) {
                    nearby.add(thing);
                }
            }
        }
        nearby.sort((a, b) -> {
            float distA = abs(this.position.x - a.position.x);
            float distB = abs(this.position.x - b.position.x);
            return Float.compare(distA, distB);
        });
        return nearby;
    }

    ArrayList<Thing> getClosestThings(ArrayList<Thing> things, float radius, boolean checkY) {
        ArrayList<Thing> nearby = new ArrayList<Thing>();
        for (Thing thing : things) {
            if (thing != null && thing != this && thing.show && thing.sceneIn == this.sceneIn) {
                float dist = checkY ? 
                    PVector.dist(thing.position, this.position) : 
                    abs(thing.position.x - this.position.x);
                if (dist <= radius) {
                    nearby.add(thing);
                }
            }
        }
        nearby.sort((a, b) -> {
            float distA = abs(this.position.x - a.position.x);
            float distB = abs(this.position.x - b.position.x);
            return Float.compare(distA, distB);
        });
        return nearby;
    }

    // Check if Thing is in current scene
    boolean inScene() {
        return this.sceneIn == gameManager.window.scene;
    }
    void hide() {
        this.sceneIn = gameManager.window.trashScene;
        this.show = false;
    }
    void show() {
        this.sceneIn = gameManager.window.scene;
        this.show = true;
    }
}

// Basic Human character class
class Human extends Thing {
    // Basic attributes
    String name;
    color hairColor, shirtColor, pantColor, shoeColor;
    float grabms;
    boolean grabbed;
    Thing grabThing;
    
    float grabRange;

    float lastShiftPress = 0;
    float shiftCooldown = 300; // 300ms cooldown between SHIFT actions
    boolean shiftPressed = false;
    float mouseDragX = width/2;

    // Controls
    boolean hasControls = true;
    int leftKey = LEFT;
    int rightKey = RIGHT;
    int upKey = UP;
    int downKey = DOWN;
    int shiftKey = SHIFT;
    boolean mouseControls = true;

    float trackedIndicatorHeight = 50; // Height above head to draw tracked indicator

    Human(String name, color hairColor,
        color shirtColor, color pantColor, color shoeColor, float posX, int sceneIn) {
        this.name = name;
        this.hairColor = hairColor;
        this.shirtColor = shirtColor;
        this.pantColor = pantColor;
        this.shoeColor = shoeColor;
        
        this.initialize();
        this.position = new PVector(posX, gameManager.window.getGroundHeightAt(posX) * 0.6);
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.grabbed = false;
        this.grabThing = null;
        this.grabms = 0;
        this.grabRange = 300f;
        this.grabbable = false;
        this.rested = false;
        this.friction = 1;
        this.sceneIn = sceneIn;
        this.groundHeightOffset = 214.144f;
        this.hasPhysics = true;
        this.show = true;
    }

    void grabClosest(ArrayList<Thing> things) {
        this.release();  // Release current thing
        
        // Find all things within range, sorted by distance
        ArrayList<Thing> inRange = this.getClosestThings(things, grabRange);
        
        // Try each Thing in order until one is successfully grabbed
        for (Thing thing : inRange) {
            if (this.grab(thing)) {  // grab() returns true if successful
                return;  // Found and grabbed something!
            }
        }
    }

    void setGrabThing(Thing thing) {
      this.grabbed = true;
      this.grabThing = thing;
      grabThing.position.set(this.position.x, this.position.y + 135);
      grabThing.velocity.set(this.velocity);
      grabThing.held = true;
    }

    // Draw human's head
    void drawHead() {
        stroke(0);
        strokeWeight(2);
        fill(248, 235, 195);
    
        // Head drawing logic
        if (velocity.x == 0) {
            quad(position.x - 35, position.y - 59, position.x + 35, position.y - 59,
                position.x + 30, position.y + 10, position.x - 30, position.y + 10);
            noFill();
            arc(position.x + 13.25, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 14, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 15, position.y - 33, position.x - 13, position.y - 33);
                line(position.x + 12.25, position.y - 33, position.x + 14.25, position.y - 33);
            } else {
                line(position.x - 14, position.y - 36, position.x - 14, position.y - 30);
                line(position.x + 13.25, position.y - 36, position.x + 13.25, position.y - 30);
            }
    
            arc(position.x - 0.375, position.y - 10, 25, 10, radians(0), radians(180), OPEN);
            strokeWeight(2);
            fill(hairColor);
            rect(position.x - 37, position.y - 66, 74, 10);
    
        } else if (velocity.x < 0) {
            // Left movement head
            quad(position.x - 35, position.y - 59, position.x + 32, position.y - 59,
                position.x + 30, position.y + 10, position.x - 30, position.y + 10);
            noFill();
            arc(position.x + 8.25, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 19, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 22, position.y - 33, position.x - 17, position.y - 33);
                line(position.x + 4.25, position.y - 33, position.x + 10.25, position.y - 33);
            } else {
                line(position.x - 18, position.y - 36, position.x - 18, position.y - 30);
                line(position.x + 9.25, position.y - 36, position.x + 9.25, position.y - 30);
            }
    
            arc(position.x - 3.375, position.y - 10, 25, 10, radians(0), radians(180), OPEN);
            fill(hairColor);
            rect(position.x - 37, position.y - 66, 74, 10);
    
        } else {
            // Right movement head
            quad(position.x - 32, position.y - 59, position.x + 35, position.y - 59,
                position.x + 30, position.y + 10, position.x - 30, position.y + 10);
            noFill();
            arc(position.x + 19.75, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 9, position.y - 40.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 12, position.y - 33, position.x - 11, position.y - 33);
                line(position.x + 16.25, position.y - 33, position.x + 17.75, position.y - 33);
            } else {
                line(position.x - 10, position.y - 36, position.x - 10, position.y - 30);
                line(position.x + 18.75, position.y - 36, position.x + 18.75, position.y - 30);
            }
    
            arc(position.x + 4.625, position.y - 10, 25, 10, radians(0), radians(180), OPEN);
            strokeWeight(2);
            fill(hairColor);
            rect(position.x - 37, position.y - 66, 74, 10);
        }
    }
    
    // Draw human's body
    void drawBody() {
        strokeWeight(2);
        fill(248, 235, 195);
        rect(position.x - 13, position.y + 11, 25, 10);
    
        if (velocity.x == 0) {
            if (grabbed) {
                fill(shirtColor);
                rect(position.x - 35, position.y + 22, 70, 100);
                fill(248, 235, 195);
                quad(position.x - 55, position.y + 27, position.x - 35, position.y + 24,
                    position.x - 30, position.y + 115, position.x - 51, position.y + 108);
                quad(position.x + 55, position.y + 27, position.x + 35, position.y + 24,
                    position.x + 30, position.y + 115, position.x + 52, position.y + 108);
            } else {
                quad(position.x - 52, position.y + 27, position.x - 30, position.y + 24,
                    position.x - 50, position.y + 115, position.x - 68, position.y + 108);
                quad(position.x + 52, position.y + 27, position.x + 30, position.y + 24,
                    position.x + 50, position.y + 115, position.x + 69, position.y + 108);
                fill(shirtColor);
                rect(position.x - 35, position.y + 22, 70, 100);
            }
        } else if (velocity.x < 0) {
            quad(position.x - 48, position.y + 24, position.x + 14.5, position.y + 21,
                position.x - 105, position.y + 72, position.x - 114, position.y + 55);
            quad(position.x + 53, position.y + 27, position.x + 35, position.y + 24,
                position.x + 23, position.y + 115, position.x + 54, position.y + 108);
            fill(shirtColor);
            rect(position.x - 35, position.y + 22, 70, 100);
        } else {
            quad(position.x - 53, position.y + 27, position.x - 23, position.y + 24,
                position.x - 23, position.y + 115, position.x - 53, position.y + 108);
            quad(position.x + 52, position.y + 24, position.x + 7, position.y + 24,
                position.x + 105, position.y + 72, position.x + 115, position.y + 55);
            fill(shirtColor);
            rect(position.x - 35, position.y + 22, 70, 100);
        }
    
        fill(pantColor);
        rect(position.x - 33, position.y + 122, 30, 80);
        rect(position.x + 3, position.y + 122, 30, 80);
    
        fill(shoeColor);
        rect(position.x - 45, position.y + 202, 42, 12);
        rect(position.x + 3, position.y + 202, 42, 12);
    }

    // Draw name above human
    void drawName() {
        fill(brightness(gameManager.window.scenes.getAs(sceneIn, Integer.class, color(255))) < 128 ? 255 : 0);
        textSize(24);
        text(name, position.x - 17 - name.length() * 2.5, position.y - 74);
    }
    
    // Display the human - REQUIRED by abstract class Thing
    void display() {
        drawName();
        drawHead();
        drawBody();
    }

    // Grab a Thing
    Boolean grab(Thing thing) {
        if (thing == null || thing.sceneIn != this.sceneIn || thing.held || !thing.show) return false;
        if (thing instanceof Interactable) {
            Interactable interactable = (Interactable) thing;
            if (interactable.isGrabbable()) {
                this.setGrabThing(thing);
                interactable.onGrab(this);
                return true;
            } else {
                interactable.onGrab(this);
                return true;
            }
        } else if (thing.grabbable) {
            this.setGrabThing(thing);
            return true;
        } else if (!thing.grabbable) { return false; }
        return false;
    }

    // Release currently grabbed Thing
    void release() {
        this.grabbed = false;
        if (grabThing != null) {
            grabThing.held = false;
            grabThing.rested = false;

            grabThing.lastReleasedMs = millis();

            // Call onRelease if the Thing is Interactable
            if (grabThing instanceof Interactable) {
                ((Interactable) grabThing).onRelease(this);
            }
            
            grabThing = null; // make grabThing null again
        }
    }

    void leftKeyDown() {
        this.acceleration.x = -3f;
    }
    void rightKeyDown() {
        this.acceleration.x = 3f;
    }
    void upKeyDown() {
        if (this.rested || this.position.y >= height*gameManager.window.getGroundHeightAt(position.x) - groundHeightOffset) {
            this.velocity.y = -50;
            this.rested = false;
        }
    }
    void downKeyDown() {
        if (millis() - this.grabms >= 500) {
            this.grabms = millis();
            if (this.grabbed) {
                this.release();
            } else {
                this.grabClosest(gameManager.things);
            }
        }
    }
    void shiftKeyDown() {
        if (grabbed && grabThing instanceof Interactable) {
            // Check if enough time has passed since last SHIFT press
            if (millis() - lastShiftPress >= shiftCooldown) {
                lastShiftPress = millis(); // Record the time  
                ((Interactable) grabThing).onInteract(this);
            }
        }
    }

    void mouseLeftDown() {
        if (mouseX >= mouseDragX) {
            rightKeyDown();
        } else {
            leftKeyDown();
        }
    }
    
    void mouseCenterDown() {
        this.shiftKeyDown();
    }

    void mouseRightDown() {
        this.downKeyDown();
    }
    void noKeyDown() {
        this.velocity.x = 0;
        this.acceleration.x = 0;
        this.mouseDragX = mouseX;
    }

    // Enhanced controls method with chair, jumping, and SHIFT interactions
    void controls() {
        if (this.hasControls) {
            // Handle key functions
            if (gameManager.keyManager.isKeyPressed(shiftKey)) {
                this.shiftKeyDown();
            }
            if (gameManager.keyManager.isKeyPressed(upKey)) {
                this.upKeyDown();
            } else if (gameManager.keyManager.isKeyPressed(downKey)) {
                this.downKeyDown();
            } 
            if (gameManager.keyManager.isKeyPressed(rightKey)) {
                this.rightKeyDown();
            } else if (gameManager.keyManager.isKeyPressed(leftKey)) {
                this.leftKeyDown();
            } else if (this.mouseControls && mousePressed){
                if (mouseButton == CENTER) {
                    this.mouseCenterDown();
                } else if (mouseButton == LEFT) {
                    this.mouseLeftDown();
                } else if (mouseButton == RIGHT) {
                    this.mouseRightDown();
                }
            } else {
                this.noKeyDown();
            }
        }
    }

    void setControls(int left, int right, int up, int down, int shift, boolean mouse) {
      this.leftKey = left;
      this.rightKey = right;
      this.upKey = up;
      this.downKey = down;
      this.shiftKey = shift;
      this.mouseControls = mouse;
    }

    void checkEdges() {
        if (this.position.x >= width * Constants.Physics.RIGHT_BOUNDARY) {
            this.position.x = width * 0.94;
        } else if (this.position.x < width * Constants.Physics.LEFT_BOUNDARY) {
            this.position.x = width * 0.09;
        }
        float groundY = height * gameManager.window.getGroundHeightAt(position.x);
        if (this.position.y >= groundY - groundHeightOffset) {
            this.position.y = groundY - groundHeightOffset;
        }
        if (this.position.y <= height * Constants.Physics.CEILING_HEIGHT) {
            this.position.y = height * Constants.Physics.CEILING_HEIGHT;
        }
    }

    void checkThings() {      
        // Update grabbed thing position
        if (this.grabbed && grabThing != null) {
            grabThing.position.set(this.position.x, this.position.y + 135);
            grabThing.held = true;
        }
    }

    @Override
    HashMap<String, Object> save() {
        HashMap<String, Object> data = super.save();
        
        // Basic attributes
        data.put("name", this.name);
        data.put("hairColor", this.hairColor);
        data.put("shirtColor", this.shirtColor);
        data.put("pantColor", this.pantColor);
        data.put("shoeColor", this.shoeColor);
        
        // State
        data.put("grabbed", this.grabbed);
        data.put("grabRange", this.grabRange);
        data.put("shiftCooldown", this.shiftCooldown);
        
        // Control settings
        data.put("hasControls", this.hasControls);
        data.put("leftKey", this.leftKey);
        data.put("rightKey", this.rightKey);
        data.put("upKey", this.upKey);
        data.put("downKey", this.downKey);
        data.put("shiftKey", this.shiftKey);
        data.put("mouseControls", this.mouseControls);
        
        data.put("trackedIndicatorHeight", this.trackedIndicatorHeight);
        
        // Save reference to grabbed thing by ID (if any)
        if (this.grabThing != null && this.grabThing instanceof Saveable) {
            data.put("grabThingID", this.grabThing.id);
        }
        
        return data;
    }

    @Override
    void load(HashMap<String, Object> data) {
        super.load(data);
        
        // Basic attributes
        if (data.containsKey("name")) this.name = (String) data.get("name");
        if (data.containsKey("hairColor")) this.hairColor = ((Number) data.get("hairColor")).intValue();
        if (data.containsKey("shirtColor")) this.shirtColor = ((Number) data.get("shirtColor")).intValue();
        if (data.containsKey("pantColor")) this.pantColor = ((Number) data.get("pantColor")).intValue();
        if (data.containsKey("shoeColor")) this.shoeColor = ((Number) data.get("shoeColor")).intValue();
        
        // State
        if (data.containsKey("grabbed")) this.grabbed = (boolean) data.get("grabbed");
        if (data.containsKey("grabRange")) this.grabRange = ((Number) data.get("grabRange")).floatValue();
        if (data.containsKey("shiftCooldown")) this.shiftCooldown = ((Number) data.get("shiftCooldown")).floatValue();
        
        // Control settings
        if (data.containsKey("hasControls")) this.hasControls = (boolean) data.get("hasControls");
        if (data.containsKey("leftKey")) this.leftKey = ((Number) data.get("leftKey")).intValue();
        if (data.containsKey("rightKey")) this.rightKey = ((Number) data.get("rightKey")).intValue();
        if (data.containsKey("upKey")) this.upKey = ((Number) data.get("upKey")).intValue();
        if (data.containsKey("downKey")) this.downKey = ((Number) data.get("downKey")).intValue();
        if (data.containsKey("shiftKey")) this.shiftKey = ((Number) data.get("shiftKey")).intValue();
        if (data.containsKey("mouseControls")) this.mouseControls = (boolean) data.get("mouseControls");
        
        if (data.containsKey("trackedIndicatorHeight")) {
            this.trackedIndicatorHeight = ((Number) data.get("trackedIndicatorHeight")).floatValue();
        }
        
        if (data.containsKey("grabThingID")) {
            this.loadGrabThing(gameManager.things, (int) data.get("grabThingID"));
        }
    }
    
    void loadGrabThing(ArrayList<Thing> objects, int objId) {
        if (objId > 0) {
            for (Thing obj : objects) {
                if (obj instanceof Saveable && obj.id == objId) {
                    this.grabThing = obj;
                    break;
                }
            }
        }
    }


    // Main update loop for human
    void live() {
        this.update();
        this.display();
        this.controls();
        this.checkEdges();
        this.checkThings();
    }
}


// ====== UI ELEMENTS ======

abstract class UIElement implements KeyEvents {
    PVector position;
    float boxWidth, boxHeight;
    boolean visible = true;
    boolean enabled = true;
    boolean hovered = false;
    boolean mousePressedOnThis = false;
    
    boolean awaitRegister = false;

    // Z-index for layering (higher = on top)
    int zIndex = 0;
    
    // Optional callbacks
    Runnable onClick;
    Runnable onHover;
    Runnable onRelease;
    
    // Animation
    float alpha = 255;
    float targetAlpha = 255;
    float animationSpeed = 0.1;
    
    UIElement() {
        this.position = new PVector(width / 2, height / 2);
        this.boxWidth = 100;
        this.boxHeight = 50;
        register();
    }
    
    UIElement(float x, float y, float w, float h) {
        this.position = new PVector(x, y);
        this.boxWidth = w;
        this.boxHeight = h;
        register();
    }
    
    void register() {
        if (gameManager == null || gameManager.uiElements == null) { this.awaitRegister = true; } else if (!gameManager.uiElements.contains(this)) {
            gameManager.uiElements.add(this);
            // Keep sorted by zIndex
            gameManager.uiElements.sort((a, b) -> Integer.compare(a.zIndex, b.zIndex));
            this.awaitRegister = false;
        }
    }
    
    void unregister() {
        gameManager.uiElements.remove(this);
    }
    
    // Core methods
    abstract void display();
    
    void update() {
        if (awaitRegister || !gameManager.uiElements.contains(this)) this.register();

        if (!enabled) return;

        // Smooth alpha transitions
        if (alpha != targetAlpha) {
            alpha = lerp(alpha, targetAlpha, animationSpeed);
            if (abs(alpha - targetAlpha) < 0.1) alpha = targetAlpha;
        }
        
        // Check hover state
        boolean wasHovered = hovered;
        hovered = isMouseOver();
        
        if (hovered && !wasHovered && onHover != null) {
            onHover.run();
        }
        
        // Handle click
        if (visible && enabled && hovered && mousePressed && !mousePressedOnThis) {
            mousePressedOnThis = true;
            onClick.run();
        }
        
        if (!mousePressed) {
            if (mousePressedOnThis && hovered && onRelease != null) {
                onRelease.run();
            }
            mousePressedOnThis = false;
        }
        
        // Display if visible
        if (visible) {
            push();
            if (alpha < 255) {
                tint(255, alpha);
            }
            display();
            if (alpha < 255) {
                noTint();
            }
            pop();
        }
    }
    
    void show() {
        visible = true;
        targetAlpha = 255;
    }
    
    void hide() {
        targetAlpha = 0;
        // Actually hide after animation completes
        if (alpha <= 0) {
            visible = false;
        }
    }
    
    void hideInstant() {
        visible = false;
        alpha = 0;
        targetAlpha = 0;
    }
    
    void toggle() {
        if (visible) hide();
        else show();
    }
    
    boolean isMouseOver() {
        return mouseX >= position.x && 
               mouseX <= position.x + boxWidth && 
               mouseY >= position.y && 
               mouseY <= position.y + boxHeight;
    }
    
    // Utility methods
    UIElement setPosition(float x, float y) {
        this.position.set(x, y);
        return this;
    }
    
    UIElement setSize(float w, float h) {
        this.boxWidth = w;
        this.boxHeight = h;
        return this;
    }
    
    UIElement setZIndex(int z) {
        this.zIndex = z;
        // Re-sort
        gameManager.uiElements.sort((a, b) -> Integer.compare(a.zIndex, b.zIndex));
        return this;
    }
    
    UIElement setAlpha(float a) {
        this.alpha = a;
        this.targetAlpha = a;
        return this;
    }
    
    UIElement fadeIn(float speed) {
        this.targetAlpha = 255;
        this.animationSpeed = speed;
        this.visible = true;
        return this;
    }
    
    UIElement fadeOut(float speed) {
        this.targetAlpha = 0;
        this.animationSpeed = speed;
        return this;
    }

    void keyDown(char key, int keyCode) {}
    void keyUp(char key, int keyCode) {}
}

class InputBox extends UIElement implements KeyEvents {
    String title;
    String hint;
    String currentText = "";
    boolean numericOnly = false;
    boolean passwordInput = false;
    int maxLength = 20;
    int blinkTimer = 0;
    boolean showCursor = true;
    
    Runnable onSubmit, onCancel;

    // For styling
    color bgColor = color(255);
    color borderColor = color(0);
    color textColor = color(0);
    color hintColor = color(100);
    float cornerRadius = 10;
    
    // Overlay background
    boolean showOverlay = true;
    color overlayColor = color(0, 150);
    
    InputBox(float x, float y, float w, float h, String title, String hint) {
        super(x, y, w, h);
        this.title = title;
        this.hint = hint;
        this.zIndex = 1000; // Input boxes should be on top
    }
    
    @Override
    void show() {
        super.show();
        this.currentText = "";
        this.blinkTimer = 0;
        this.showCursor = true;
    }
    
    @Override
    void hide() {
        super.hideInstant();
        currentText = "";
    }
    
    boolean isVisible() {
        return visible;
    }
    
    @Override
    void update() {
        if (!visible) return;
        
        // Blink cursor effect
        blinkTimer++;
        if (blinkTimer > 30) {
            blinkTimer = 0;
            showCursor = !showCursor;
        }
        
        super.update(); // This handles display
    }
    
    @Override
    void display() {
        if (!visible) return;
        
        push();
        
        // Draw semi-transparent overlay
        if (showOverlay) {
            fill(overlayColor);
            noStroke();
            rect(0, 0, width, height);
        }
        
        // Draw main box
        fill(bgColor);
        stroke(borderColor);
        strokeWeight(3);
        rect(position.x, position.y, boxWidth, boxHeight, cornerRadius);
        
        // Draw title
        fill(textColor);
        textSize(32);
        textAlign(CENTER);
        text(title, position.x + boxWidth/2, position.y + 50);
        
        // Draw input field background
        fill(240);
        noStroke();
        rect(position.x + 50, position.y + 80, boxWidth - 100, 50, cornerRadius/2);
        
        // Draw border around input field
        stroke(borderColor);
        strokeWeight(2);
        noFill();
        rect(position.x + 50, position.y + 80, boxWidth - 100, 50, cornerRadius/2);
        
        // Draw text
        fill(textColor);
        textSize(28);
        
        // Mask password with asterisks if needed
        String displayText = currentText;
        if (passwordInput) {
            displayText = "";
            for (int i = 0; i < currentText.length(); i++) {
                displayText += "*";
            }
        }
        
        // Add blinking cursor
        if (showCursor) {
            displayText += "|";
        }
        
        textAlign(LEFT);
        
        // Calculate available width for text
        float availableWidth = boxWidth - 120;
        float textX = position.x + 60;
        float textY = position.y + 112;
        
        // Check if text is too long and clip it
        if (textWidth(displayText) > availableWidth) {
            int charsToShow = displayText.length();
            while (charsToShow > 0 && textWidth(displayText.substring(0, charsToShow)) > availableWidth) {
                charsToShow--;
            }
            
            if (charsToShow <= 0) {
                displayText = "";
            } else if (charsToShow < displayText.length() - 1) {
                displayText = displayText.substring(0, charsToShow - 3) + "...";
            } else {
                displayText = displayText.substring(0, charsToShow);
            }
        }
        
        text(displayText, textX, textY);
        textAlign(CENTER);
                
        // Draw hint
        textSize(18);
        fill(hintColor);
        text(hint, position.x + boxWidth/2, position.y + boxHeight - 50);
        
        // Draw instructions
        textSize(14);
        text("Press ENTER to submit, DELETE when empty to cancel", 
             position.x + boxWidth/2, position.y + boxHeight - 20);
        
        textAlign(LEFT);
        pop();
    }
    
    void keyDown(char key, int keyCode) {
        if (!visible) return;
        
        if (keyCode == ENTER || keyCode == RETURN) {
            if (onSubmit != null) {
                onSubmit.run();
            }
            hide();
        } 
        else if (keyCode == BACKSPACE || keyCode == DELETE) {
            if (currentText.length() > 0) {
                currentText = currentText.substring(0, currentText.length() - 1);
            } else {
                if (onCancel != null) {
                    onCancel.run();
                }
                hide();
            }
        }
        else if (key >= ' ' && key <= '~') {
            if (numericOnly && !(key >= '0' && key <= '9')) {
                return;
            }
            
            if (currentText.length() < maxLength) {
                currentText += key;
            }
        }
    }
    
    // Styling methods
    InputBox setColors(color bg, color border, color text, color hintCol) {
        this.bgColor = bg;
        this.borderColor = border;
        this.textColor = text;
        this.hintColor = hintCol;
        return this;
    }
    
    InputBox setNumericOnly(boolean numeric) {
        this.numericOnly = numeric;
        return this;
    }
    
    InputBox setMaxLength(int length) {
        this.maxLength = length;
        return this;
    }
    
    InputBox setPasswordMode(boolean isPassword) {
        this.passwordInput = isPassword;
        return this;
    }
    
    InputBox setOverlay(color overlayColor, boolean show) {
        this.overlayColor = overlayColor;
        this.showOverlay = show;
        return this;
    }
    
    String getText() {
        return currentText;
    }
    
    void setText(String text) {
        this.currentText = text;
    }
}

class MessageBox extends UIElement {
    // Drag handle area (top bar)
    float handleHeight = 30;
    boolean draggable = true;
    boolean isDragging = false;
    PVector dragOffset;
    
    // Content
    ArrayList<String> messages = new ArrayList<String>();
    int maxMessages = 5;
    float messageDisplayTime = 3000;
    float messageStartTime = 0;
    
    // Styling
    color bgColor = color(0, 0, 0, 200);
    color textColor = color(255, 255, 255);
    color eventTextColor = color(200, 200, 255);
    color alertTextColor = color(255, 150, 150);
    color borderColor = color(0, 100, 200);
    color eventBorderColor = color(0, 100, 200);
    color alertBorderColor = color(255, 100, 100);
    color handleColor = color(80, 80, 80, 150);
    float cornerRadius = 15;
    float padding = 15;
    int textSizeVal = 16;
    
    // Animation for individual messages
    float fadeAlpha = 255;
    boolean fading = false;
    
    MessageBox(float x, float y, float w, float h) {
        super(x, y, w, h);
        this.zIndex = 900; // Below input boxes, above most UI
    }
    
    // Add a message to the queue
    void showMessage(String message) {
        messages.add(message);
        if (messages.size() > maxMessages) {
            messages.remove(0);
        }
        messageStartTime = millis();
        
        fadeAlpha = 255;
        fading = false;
        
        println("[MESSAGE]: " + message);
    }
    
    void showAlert(String message) {
        showMessage("[!] " + message);
        borderColor = alertBorderColor;
        textColor = alertTextColor;
    }
    
    void showEvent(String message) {
        showMessage("> " + message);
        borderColor = eventBorderColor;
        textColor = eventTextColor;
    }
    
    // Check if mouse is over the drag handle (top part)
    boolean isMouseOverHandle() {
        return mouseX >= position.x && 
               mouseX <= position.x + boxWidth && 
               mouseY >= position.y && 
               mouseY <= position.y + handleHeight;
    }
    
    @Override
    void update() {
        if (!visible) return;
        
        // Handle dragging
        if (draggable) {
            if (isMouseOverHandle() && mousePressed && !isDragging) {
                isDragging = true;
                dragOffset = new PVector(mouseX - position.x, mouseY - position.y);
            }
            
            if (isDragging && mousePressed) {
                position.x = mouseX - dragOffset.x;
                position.y = mouseY - dragOffset.y;
                // Constrain to screen
                position.x = constrain(position.x, 0, width - boxWidth);
                position.y = constrain(position.y, 0, height - boxHeight);
            }
            
            if (!mousePressed) {
                isDragging = false;
            }
        }
        
        // Auto-fade after display time
        if (!fading && millis() - messageStartTime > messageDisplayTime) {
            fading = true;
        }
        
        if (fading) {
            fadeAlpha = max(0, fadeAlpha - 3);
            if (fadeAlpha <= 0) {
                messages.clear();
                fading = false;
            }
        }
        
        // Reset border color after alert
        if (borderColor == alertBorderColor && millis() - messageStartTime > 1000) {
            borderColor = eventBorderColor;
        }
        
        // Update hover state for handle
        hovered = isMouseOver();
        
        super.update(); // Handles display
    }
    
    @Override
    void display() {
        if (!visible) return;
        
        pushStyle();
        
        // Draw drag handle if draggable
        if (draggable) {
            boolean handleHovered = isMouseOverHandle();
            fill(red(handleColor), green(handleColor), blue(handleColor), 
                 handleHovered ? 200 : 100);
            noStroke();
            rect(position.x, position.y, boxWidth, handleHeight, cornerRadius, cornerRadius, 0, 0);
            
            // Draw drag indicator (three lines)
            stroke(255, handleHovered ? 200 : 100);
            strokeWeight(2);
            float centerX = position.x + boxWidth/2;
            for (int i = -1; i <= 1; i++) {
                line(centerX + i*15, position.y + handleHeight/2 - 3, 
                     centerX + i*15, position.y + handleHeight/2 + 3);
            }
        }
        
        // Background
        float currentAlpha = fadeAlpha * 0.8 * (alpha / 255);
        fill(red(bgColor), green(bgColor), blue(bgColor), currentAlpha);
        stroke(red(borderColor), green(borderColor), blue(borderColor), currentAlpha);
        strokeWeight(3);
        
        // Adjust drawing based on whether we have a handle
        if (draggable) {
            rect(position.x, position.y + handleHeight, boxWidth, boxHeight - handleHeight, 
                 0, 0, cornerRadius, cornerRadius);
        } else {
            rect(position.x, position.y, boxWidth, boxHeight, cornerRadius);
        }
        
        // Combine messages
        String totalMessages = "";
        for (String message : messages) {
            if (message != null && !message.isEmpty()) {
                totalMessages += (message + "\n");
            }
        }      
        
        // Draw text (offset by handle if needed)
        float textY = position.y + padding + (draggable ? handleHeight : 0);
        
        fill(red(textColor), green(textColor), blue(textColor), fadeAlpha * (alpha / 255));
        textSize(textSizeVal + 4);
        textAlign(LEFT, TOP);
        text(totalMessages, position.x + padding, textY, 
             boxWidth - padding * 2, 
             boxHeight - padding * 2 - (draggable ? handleHeight : 0));
        
        popStyle();
        textAlign(LEFT);
    }
    
    void clear() {
        messages.clear();
    }
    
    // Toggle draggable
    MessageBox setDraggable(boolean canDrag) {
        this.draggable = canDrag;
        return this;
    }
    
    MessageBox setStyle(color bg, color border, color text, float radius) {
        this.bgColor = bg;
        this.borderColor = border;
        this.textColor = text;
        this.cornerRadius = radius;
        return this;
    }
    
    MessageBox setMaxMessages(int max) {
        this.maxMessages = max;
        return this;
    }
    
    MessageBox setDisplayTime(float ms) {
        this.messageDisplayTime = ms;
        return this;
    }
}

class StatBar extends UIElement {
    String label;
    float progress = 1.0; // 0.0 to 1.0
    float maxValue = 100;
    float currentValue = 100;
    
    // Styling
    color barColor = color(0, 255, 0);
    color backgroundColor = color(100);
    color borderColor = color(50);
    color labelColor = color(0);
    float borderRadius = 5;
    boolean showPercentage = true;
    boolean showLabel = true;
    
    StatBar(String label, float x, float y, float w, float h) {
        super(x, y, w, h);
        this.label = label;
    }
    
    void setValue(float current, float max) {
        this.currentValue = constrain(current, 0, max);
        this.maxValue = max;
        this.progress = this.currentValue / this.maxValue;
    }
    
    void setProgress(float value) {
        this.progress = constrain(value, 0, 1);
        this.currentValue = this.progress * this.maxValue;
    }
    
    @Override
    void display() {
        push();
        
        // Draw background
        fill(backgroundColor);
        stroke(borderColor);
        strokeWeight(1);
        rect(position.x, position.y, boxWidth, boxHeight, borderRadius);
        
        // Draw fill bar
        fill(barColor);
        noStroke();
        rect(position.x + 2, position.y + 2, (boxWidth - 4) * progress, boxHeight - 4, borderRadius - 1);
        
        // Draw label
        if (showLabel) {
            fill(labelColor);
            textSize(14);
            textAlign(CENTER);
            float labelX = position.x - (3 * label.length() + 9);
            float labelY = position.y + boxHeight/2 + (textAscent() - textDescent())/2;
            text(label, labelX, labelY);
        }
        
        // Draw percentage text
        if (showPercentage) {
            fill(labelColor);
            textSize(14);
            textAlign(CENTER);
            float labelX = position.x + boxWidth + (3 * label.length() + 6);
            float labelY = position.y + boxHeight/2 + (textAscent() - textDescent())/2;
            text(int(progress * 100) + "%", labelX, labelY);
        }
        
        pop();
    }
    
    // Fluent styling methods
    StatBar setColors(color bar, color bg, color border, color labelCol) {
        this.barColor = bar;
        this.backgroundColor = bg;
        this.borderColor = border;
        this.labelColor = labelCol;
        return this;
    }
    
    StatBar setShowPercentage(boolean show) {
        this.showPercentage = show;
        return this;
    }
    
    StatBar setShowLabel(boolean show) {
        this.showLabel = show;
        return this;
    }
}
