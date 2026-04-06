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
    boolean held = false, grabbable = true, show = true, hasPhysics = true;
    float elasticity = 0, friction = 0.98f;
    int sceneIn = 0; // Scene this Thing belongs to
    float groundHeightOffset = 0;
    float checkTouchRadius = 0;
    boolean checkTouchY = false, checkTouchWide = false;
    boolean drawBehindHumans = false;
    boolean drawInBackground = false;
    boolean drawInForeground = false;
    boolean updateInBackground = false;
    float lastReleasedMs = 0;

    boolean followingThing = false;
    Thing leader;
    PVector followingOffset;

    Thing() {
        position = new PVector(width / 2, gameManager.sceneManager.getGroundHeightAt(width/2));
        velocity = new PVector();
        acceleration = new PVector();
    }

    // Abstract methods - must be implemented by subclasses
    abstract void display();
    
    // Initialize with default position
    void initialize() {
        position.set(width / 2, gameManager.sceneManager.getGroundHeightAt(width/2));
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
        if (hasPhysics && !this.held && !this.followingThing) {
            acceleration.y = Constants.Physics.GRAVITY;
            velocity.add(acceleration);
            velocity.limit(Constants.Physics.MAX_VELOCITY);
            position.add(velocity);
        }
        checkEdges();
        checkFollow();
    }

    // Check and handle screen boundaries
    void checkEdges() {
        if (!hasPhysics) return;
        
        position.x = constrain(position.x, width * Constants.Physics.LEFT_BOUNDARY, width * Constants.Physics.RIGHT_BOUNDARY);
        
        // Get dynamic ground height at current X position
        float groundY = height * gameManager.sceneManager.getGroundHeightAt(position.x);
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
        if (other.held || this.held || !this.show || !other.show || !(other.sceneIn == this.sceneIn)) return;
        
        float dist;
        if (checkTouchY) {
            dist = PVector.dist(position, other.position);  // Full 2D distance
        } else {
            dist = abs(position.x - other.position.x);      // X-only distance
        }
        
        if (dist <= checkTouchRadius) {
            this.onTouch(other, dist);
        }
    }

    void checkFollow() {
        if (this.followingThing) {
            if (this.leader != null && this.followingOffset != null) {
                this.position.set(leader.position);
                this.position.add(followingOffset);
                this.velocity.set(0, 0);
            }
        }
    }

    void moveTo(float x, float y) { this.position.x = x; this.position.y = y; }
    void moveToX(float x) {this.position.x = x; }
    void moveToY(float y) {this.position.y = y; }
    void followThing(Thing leader) { this.leader = leader; this.followingThing = true; this.followingOffset = new PVector(0,0); }
    void followThing(Thing leader, float x, float y) { this.followThing(leader); this.followingOffset.set(x, y); }
    void unfollowThing() { this.leader = null; this.followingThing = false; this.followingOffset.set(0, 0); }

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
        return this.sceneIn == gameManager.sceneManager.scene;
    }
    void hide() {
        this.sceneIn = gameManager.sceneManager.trashScene;
        this.show = false;
    }
    void show() {
        this.sceneIn = gameManager.sceneManager.scene;
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

    float trackedIndicatorHeight = 216; // Height above body to draw tracked indicator

    Human(String name, color hairColor,
        color shirtColor, color pantColor, color shoeColor, float posX, int sceneIn) {
        this.name = name;
        this.hairColor = hairColor;
        this.shirtColor = shirtColor;
        this.pantColor = pantColor;
        this.shoeColor = shoeColor;
        
        this.initialize();
        this.position = new PVector(posX, gameManager.sceneManager.getGroundHeightAt(posX) * 0.6);
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.grabbed = false;
        this.grabThing = null;
        this.grabms = 0;
        this.grabRange = 300f;
        this.grabbable = false;
        this.friction = 1;
        this.sceneIn = sceneIn;
        this.groundHeightOffset = 72f;
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
      grabThing.followThing(this);
      grabThing.held = true;
    }

    // Draw human's head
    void drawHead() {
        stroke(0);
        strokeWeight(2);
        fill(248, 235, 195);
    
        // Head drawing logic
        if (velocity.x == 0) {
            quad(position.x - 35, position.y - 159, position.x + 35, position.y - 159,
                position.x + 30, position.y - 90, position.x - 30, position.y - 90);
            noFill();
            arc(position.x + 13.25, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 14, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 15, position.y - 133, position.x - 13, position.y - 133);
                line(position.x + 12.25, position.y - 133, position.x + 14.25, position.y - 133);
            } else {
                line(position.x - 14, position.y - 136, position.x - 14, position.y - 130);
                line(position.x + 13.25, position.y - 136, position.x + 13.25, position.y - 130);
            }
    
            arc(position.x - 0.375, position.y - 110, 25, 10, radians(0), radians(180), OPEN);
            strokeWeight(2);
            fill(hairColor);
            rect(position.x - 37, position.y - 166, 74, 10);
    
        } else if (velocity.x < 0) {
            // Left movement head
            quad(position.x - 35, position.y - 159, position.x + 32, position.y - 159,
                position.x + 30, position.y - 90, position.x - 30, position.y - 90);
            noFill();
            arc(position.x + 8.25, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 19, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 22, position.y - 133, position.x - 17, position.y - 133);
                line(position.x + 4.25, position.y - 133, position.x + 10.25, position.y - 133);
            } else {
                line(position.x - 18, position.y - 136, position.x - 18, position.y - 130);
                line(position.x + 9.25, position.y - 136, position.x + 9.25, position.y - 130);
            }
    
            arc(position.x - 3.375, position.y - 110, 25, 10, radians(0), radians(180), OPEN);
            fill(hairColor);
            rect(position.x - 37, position.y - 166, 74, 10);
    
        } else {
            // Right movement head
            quad(position.x - 32, position.y - 159, position.x + 35, position.y - 159,
                position.x + 30, position.y + -90, position.x - 30, position.y + -90);
            noFill();
            arc(position.x + 19.75, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
            arc(position.x - 9, position.y - 140.5, 20, 10, radians(180), radians(360), OPEN);
    
            strokeWeight(3);
            if (millis() % 4000 <= 200) {
                line(position.x - 12, position.y - 133, position.x - 11, position.y - 133);
                line(position.x + 16.25, position.y - 133, position.x + 17.75, position.y - 133);
            } else {
                line(position.x - 10, position.y - 136, position.x - 10, position.y - 130);
                line(position.x + 18.75, position.y - 136, position.x + 18.75, position.y - 130);
            }
    
            arc(position.x + 4.625, position.y - 110, 25, 10, radians(0), radians(180), OPEN);
            strokeWeight(2);
            fill(hairColor);
            rect(position.x - 37, position.y - 166, 74, 10);
        }
    }
    
    // Draw human's body
    void drawBody() {
        strokeWeight(2);
        fill(248, 235, 195);
        rect(position.x - 13, position.y - 89, 25, 10);
    
        if (velocity.x == 0) {
            if (grabbed) {
                fill(shirtColor);
                rect(position.x - 35, position.y + 22 - 100, 70, 100);
                fill(248, 235, 195);
                quad(position.x - 55, position.y + 27 - 100, position.x - 35, position.y + 24 - 100,
                    position.x - 30, position.y + 115 - 100, position.x - 51, position.y + 108 - 100);
                quad(position.x + 55, position.y + 27 - 100, position.x + 35, position.y + 24 - 100,
                    position.x + 30, position.y + 115 - 100, position.x + 52, position.y + 108 - 100);
            } else {
                quad(position.x - 52, position.y + 27 - 100, position.x - 30, position.y + 24 - 100,
                    position.x - 50, position.y + 115 - 100, position.x - 68, position.y + 108 - 100);
                quad(position.x + 52, position.y + 27 - 100, position.x + 30, position.y + 24 - 100,
                    position.x + 50, position.y + 115 - 100, position.x + 69, position.y + 108 - 100);
                fill(shirtColor);
                rect(position.x - 35, position.y + 22 - 100, 70, 100);
            }
        } else if (velocity.x < 0) {
            quad(position.x - 48, position.y + 24 - 100, position.x + 14.5, position.y + 21 - 100,
                position.x - 105, position.y + 72 - 100, position.x - 114, position.y + 55 - 100);
            quad(position.x + 53, position.y + 27 - 100, position.x + 35, position.y + 24 - 100,
                position.x + 23, position.y + 115 - 100, position.x + 54, position.y + 108 - 100);
            fill(shirtColor);
            rect(position.x - 35, position.y + 22 - 100, 70, 100);
        } else {
            quad(position.x - 53, position.y + 27 - 100, position.x - 23, position.y + 24 - 100,
                position.x - 23, position.y + 115 - 100, position.x - 53, position.y + 108 - 100);
            quad(position.x + 52, position.y + 24 - 100, position.x + 7, position.y + 24 - 100,
                position.x + 105, position.y + 72 - 100, position.x + 115, position.y + 55 - 100);
            fill(shirtColor);
            rect(position.x - 35, position.y + 22 - 100, 70, 100);
        }
    
        fill(pantColor);
        rect(position.x - 33, position.y + 122 - 100, 30, 80);
        rect(position.x + 3, position.y + 122 - 100, 30, 80);
    
        fill(shoeColor);
        rect(position.x - 45, position.y + 202 - 100, 42, 12);
        rect(position.x + 3, position.y + 202 - 100, 42, 12);
    }

    // Draw name above human
    void drawName() {
        fill(brightness(gameManager.sceneManager.scenes.getAs(sceneIn, Integer.class, color(255))) < 128 ? 255 : 0);
        textSize(24);
        text(name, position.x - 17 - name.length() * 2.5, position.y - 174);
    }
    
    // Display the human - REQUIRED by abstract class Thing
    void display() {
        drawName();
        drawHead();
        drawBody();
    }

    // Grab a Thing
    boolean grab(Thing thing) {
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
            grabThing.unfollowThing();
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
        if (this.position.y >= height*gameManager.sceneManager.getGroundHeightAt(position.x) - groundHeightOffset) {
            this.velocity.y = -50;
        }
    }
    void downKeyDown() {
        if (millis() - this.grabms >= 500) {
            this.grabms = millis();
            if (this.grabbed) {
                this.release();
            } else {
                this.grabClosest(gameManager.thingManager.things);
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
        if (mouseX > mouseDragX) {
            rightKeyDown();
        } else if (mouseX < mouseDragX) {
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
        
        float groundY = height * gameManager.sceneManager.getGroundHeightAt(position.x);
        float effectiveGroundY = groundY - groundHeightOffset;
        
        if (this.position.y > effectiveGroundY) {
            this.position.y = effectiveGroundY;
        }
        
        if (this.position.y <= height * Constants.Physics.CEILING_HEIGHT) {
            this.position.y = height * Constants.Physics.CEILING_HEIGHT;
            if (this.velocity.y < 0) this.velocity.y = 0;  // Stop upward momentum at ceiling
        }
    }

    void checkThings() {      
        // Update grabbed thing
        if (this.grabbed && grabThing != null) {
            grabThing.held = true;
        } else {
            this.grabbed = false;
            grabThing = null;
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
            this.loadGrabThing(gameManager.thingManager.things, (int) data.get("grabThingID"));
        }
    }
    
    void loadGrabThing(ArrayList<Thing> objects, int objId) {
        if (objId > 0) {
            for (Thing obj : objects) {
                if (obj instanceof Saveable && obj.id == objId) {
                    this.grabThing = obj;
                    grabThing.followThing(this);
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
        this.checkThings();
    }
}