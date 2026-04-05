// Game Human class - extends BasicHuman with additional game mechanics 
class GameHuman extends Human {
    // Basic attributes
    String firstName, lastName;
    float speed;
    Boolean sleeping, jumping;
    Chair standingOnChair = null;

    // Hunger and money attributes
    Boolean hasHungerAndMoney = true;
    float hunger;
    float money; // Money amount
    float maxHunger = 100;
    int lastHungerUpdate; // Timer for hunger increase
    float velocityHungerUsed = 500; // Inversely proportional to hunger increase speed
    int hungerIncreaseRate = 60; // Frames between hunger increase (1 second at 60fps)
    float hungerIncreaseAmount = 0.25; // How much hunger increases each time
    boolean isDead = false;

    float bobOffset = 0;
    float bobSpeed = 0.08;  // How fast to bob
    float bobAmount = 3;    // How many pixels to bob
    boolean wasMoving = false;

    float chairHeightOffset = groundHeightOffset + 100;

    StatBar hungerBar;

    GameHuman(String firstName, String lastName, color hairColor,
        color shirtColor, color pantColor, color shoeColor, float speed, float money, float posX, int sceneIn) {
        // Call parent constructor with name
        super(firstName, hairColor, shirtColor, pantColor, shoeColor, posX, sceneIn);
        
        this.updateInBackground = true;
        
        // Set additional properties
        this.firstName = firstName;
        this.lastName = lastName == null || lastName.isEmpty() ? "" : lastName;
        this.speed = (speed > 0 ? speed : 2);
        
        // Initialize hunger and money
        this.hunger = 0;
        this.money = money;
        this.lastHungerUpdate = (int)(frameCount/(frameRate/60));
        this.sleeping = false;
        this.jumping = false;
        this.standingOnChair = null;

        hungerBar = new StatBar("Hunger", 0, 0, 100, 12);
        hungerBar.setColors(getHungerBarColor(), color(100), color(50), color(0))
                 .setShowPercentage(true)
                 .setShowLabel(true)
                 .hideInstant();
        hungerBar.setZIndex(10); // Above game objects but below UI

        gameManager.uiManager.add(hungerBar);

    }

    // Update hunger over time
    void updateHunger() {
        if (!hasHungerAndMoney) { this.trackedIndicatorHeight = 216; return; };

        this.trackedIndicatorHeight = 216 + 36;

        // Increase hunger based on velocity (more movement = more hunger)
        hunger += abs(this.velocity.x / velocityHungerUsed);

        // Increase hunger at regular intervals
        if ((int)(frameCount/(frameRate/60)) - lastHungerUpdate >= hungerIncreaseRate) {
            hunger += hungerIncreaseAmount;
            lastHungerUpdate = (int)(frameCount/(frameRate/60));

            if (hunger >= maxHunger) {
                starve();
            }
        }
    }
    
    // Starve method when hunger hits maxHunger
    void starve() {
        gameManager.messageBox.showAlert(this.firstName + " starved!");
        this.isDead = true;
        this.show = false;
        this.hasPhysics = false;
        this.speed = 0;
        this.money = 0;
    }

    void respawn() {
        if (this.isDead) {
            this.isDead = false;
            this.show = true;
            this.hasPhysics = true;
            this.hunger = maxHunger / 2;
            this.speed = 2;
            gameManager.messageBox.showAlert(this.firstName + " respawned!");
        }
    }

    // Method to eat food
    void eatFood(Lunchbox food) {
        if (!hasHungerAndMoney) return;
        
        if (money >= food.price) {
            // Consume the food
            hunger -= food.energyValue;
            money -= food.price;

            // Make sure hunger doesn't go below 0
            if (hunger < 0) {
                hunger = 0;
            }

            // Hide the food
            food.consumed = true;
            food.hide();

            println(firstName + " ate a lunchbox! Hunger: " + nf(hunger, 0, 1) + ", Money: $" + nf(money, 0, 2));
        } else {
            println("Not enough money! Need $" + food.price + ", but only have $" + nf(money, 0, 2));
        }
    }

    // Enhanced grabClosest method with SHIFT priority for Cupboard
    void grabClosest(ArrayList<Thing> things) {
        this.release();  // Release current thing
        
        // FIRST PRIORITY: Cupboard when SHIFT is pressed
        if (gameManager.keyManager.isKeyPressed(shiftKey)) {
            // Find all cupboards in range
            ArrayList<Thing> cupboardsInRange = this.getClosestThings(things, grabRange);
            
            // Try each cupboard until one can be grabbed
            for (Thing cupboard : cupboardsInRange) {
                if (cupboard instanceof Cupboard && this.grab(cupboard)) {
                    return;  // Successfully grabbed a cupboard!
                }
            }
        }
        
        // SECOND PRIORITY: Find other potential things in range with default function
        super.grabClosest(things);
        
    }

    void standOnChair(Chair chair) {
        this.followThing(chair, 0, -chairHeightOffset);
        this.standingOnChair = chair;
        this.velocity.set(0, 0);
        this.jumping = false;
    }

    // Get off a chair
    void getOffChair() {
        if (standingOnChair != null) {
            this.unfollowThing();
            standingOnChair.occupied = false;
            standingOnChair.restedThing = null;
            this.position.y -= 20; // Move slightly up when getting off
            standingOnChair = null;
        }
    }

    // Draw money display
    void drawMoney() {
        if (!hasHungerAndMoney) return;
        
        fill(gameManager.sceneManager.scenes.getAs(sceneIn, Integer.class, color(255)) < -13500000 ? 255 : 0);
        textSize(18);
        textAlign(CENTER);
        text("$" + nf(money, 0, 2), position.x, position.y - 196);
        textAlign(LEFT); // Reset alignment
    }


    // Enhanced display method
    void display() {
        hungerBar.visible = true;

        // Check if we're stationary and not jumping
        boolean isStationary = (velocity.x == 0 && standingOnChair == null && grabThing == null);
        
        pushMatrix();
        
        if (isStationary) {
            // Bob up and down using sine wave
            bobOffset += bobSpeed;
            float bobY = sin(bobOffset) * bobAmount;
            translate(0, bobY);
        } else {
            // Reset bobbing when moving
            bobOffset = 0;
        }
        
        // Call parent display to draw the human
        super.display();
        
        popMatrix();
        
        // Draw money and hunger (these shouldn't bob)
        if (hasHungerAndMoney) {
            drawMoney();
            // Update and display hunger bar (position relative to human)
            if (hasHungerAndMoney) {
                // Update bar position to follow the human
                hungerBar.setPosition(position.x - 42, position.y - 228);
                
                // Update bar value
                hungerBar.setValue(100 - hunger, 100);
                
                // Update color based on hunger level
                hungerBar.barColor = getHungerBarColor();
            }
        }
    }
    
    color getHungerBarColor() {
        float hungerPercent = hunger / 100.0;
        if (hungerPercent < 0.3) return color(0, 255, 0);
        else if (hungerPercent < 0.7) return color(255, 255, 0);
        else return color(255, 0, 0);
    }

    @Override
    void leftKeyDown() {
        float groundAngle = gameManager.sceneManager.getGroundAngleAt(position.x);
        float baseSpeed = -speed / (frameRate/60);
        
        float steepness = abs(groundAngle);
        float maxSteepness = 0.7;
        
        float slopeEffect;
        if (groundAngle > 0) { 
            slopeEffect = 1.0 - 1.5 * pow(steepness / maxSteepness, 2);
        } else { 
            slopeEffect = 1.0 + 1.2 * pow(steepness / maxSteepness, 2);
        }
        
        slopeEffect = constrain(slopeEffect, 0.15, 4.0);
        this.acceleration.x = baseSpeed * slopeEffect;
    }

    @Override
    void rightKeyDown() {
        float groundAngle = gameManager.sceneManager.getGroundAngleAt(position.x);
        float baseSpeed = speed / (frameRate/60);
        
        float steepness = abs(groundAngle);
        float maxSteepness = 0.7;
        
        float slopeEffect;
        if (groundAngle > 0) {
            slopeEffect = 1.0 + 1.2 * pow(steepness / maxSteepness, 2);
        } else {
            slopeEffect = 1.0 - 1.5 * pow(steepness / maxSteepness, 2);
        }
        
        slopeEffect = constrain(slopeEffect, 0.15, 4.0);
        this.acceleration.x = baseSpeed * slopeEffect;
    }

    @Override
    void upKeyDown() {
        super.upKeyDown();
        // If standing on chair, get off when jumping
        if (standingOnChair != null) {
            this.getOffChair();
        }
    }

    // Check thing interactions
    void checkThings() {
        super.checkThings();
        // If standing on chair, maintain position
        if (standingOnChair != null) {
            this.velocity.set(0, 0);
        }
    }
    
    @Override
    HashMap<String, Object> save() {
        HashMap<String, Object> data = super.save();
        
        // Basic attributes
        data.put("firstName", this.firstName);
        data.put("lastName", this.lastName);
        data.put("speed", this.speed);
        data.put("sleeping", this.sleeping);
        data.put("jumping", this.jumping);
        
        // Hunger and money
        data.put("hasHungerAndMoney", this.hasHungerAndMoney);
        data.put("hunger", this.hunger);
        data.put("money", this.money);
        data.put("maxHunger", this.maxHunger);
        data.put("lastHungerUpdate", this.lastHungerUpdate);
        data.put("velocityHungerUsed", this.velocityHungerUsed);
        data.put("hungerIncreaseRate", this.hungerIncreaseRate);
        data.put("hungerIncreaseAmount", this.hungerIncreaseAmount);
        data.put("isDead", this.isDead);
        
        // Animation
        data.put("bobOffset", this.bobOffset);
        data.put("bobSpeed", this.bobSpeed);
        data.put("bobAmount", this.bobAmount);
        data.put("wasMoving", this.wasMoving);
        
        // Reference to chair (if any)
        if (this.standingOnChair != null) {
            data.put("standingOnChairID", this.standingOnChair.id);
        }
        
        return data;
    }
    
    @Override
    void load(HashMap<String, Object> data) {
        super.load(data);
        
        // Basic attributes
        if (data.containsKey("firstName")) this.firstName = (String) data.get("firstName");
        if (data.containsKey("lastName")) this.lastName = (String) data.get("lastName");
        if (data.containsKey("speed")) this.speed = ((Number) data.get("speed")).floatValue();
        if (data.containsKey("sleeping")) this.sleeping = (boolean) data.get("sleeping");
        if (data.containsKey("jumping")) this.jumping = (boolean) data.get("jumping");
        
        // Hunger and money
        if (data.containsKey("hasHungerAndMoney")) this.hasHungerAndMoney = (boolean) data.get("hasHungerAndMoney");
        if (data.containsKey("hunger")) this.hunger = ((Number) data.get("hunger")).floatValue();
        if (data.containsKey("money")) this.money = ((Number) data.get("money")).floatValue();
        if (data.containsKey("maxHunger")) this.maxHunger = ((Number) data.get("maxHunger")).floatValue();
        if (data.containsKey("lastHungerUpdate")) this.lastHungerUpdate = ((Number) data.get("lastHungerUpdate")).intValue();
        if (data.containsKey("velocityHungerUsed")) this.velocityHungerUsed = ((Number) data.get("velocityHungerUsed")).floatValue();
        if (data.containsKey("hungerIncreaseRate")) this.hungerIncreaseRate = ((Number) data.get("hungerIncreaseRate")).intValue();
        if (data.containsKey("hungerIncreaseAmount")) this.hungerIncreaseAmount = ((Number) data.get("hungerIncreaseAmount")).floatValue();
        if (data.containsKey("isDead")) this.isDead = (boolean) data.get("isDead");
        
        // Animation
        if (data.containsKey("bobOffset")) this.bobOffset = ((Number) data.get("bobOffset")).floatValue();
        if (data.containsKey("bobSpeed")) this.bobSpeed = ((Number) data.get("bobSpeed")).floatValue();
        if (data.containsKey("bobAmount")) this.bobAmount = ((Number) data.get("bobAmount")).floatValue();
        if (data.containsKey("wasMoving")) this.wasMoving = (boolean) data.get("wasMoving");
        
        // Load chair reference
        if (data.containsKey("standingOnChairID")) {
            this.loadStandingOnChair(gameManager.thingManager.things, ((Number) data.get("standingOnChairID")).intValue());
        }
    }
    
    void loadStandingOnChair(ArrayList<Thing> things, int chairId) {
        if (chairId > 0) {
            for (Thing thing : things) {
                if (thing instanceof Chair && thing.id == chairId) {
                    this.standingOnChair = (Chair) thing;
                    thing.followThing(this);
                    break;
                }
            }
        }
    }

    // Main update loop for human
    void live() {
        if (!isDead) {
            this.update();
            this.updateHunger();
            this.display();
            this.controls();
            this.checkEdges();
            this.checkThings();
        }
    }
    
    // Background update loop for human
    void backgroundUpdate() {
        this.update();
        this.updateHunger();
        hungerBar.visible = false;
        println(hungerBar.visible);
    }
}

class ImageHuman extends Human {
  String imagePath;
  ImageHuman(String name, String filename, float posX, int sceneIn) {
    super(name, color(255), color(255), color(255), color(255), posX, sceneIn);
    this.imagePath = filename;
    gameManager.imageManager.addImage(imagePath, imagePath, 360, 360);
  }
  void display() {
    PGraphics drawImage = gameManager.imageManager.getImage(imagePath);
    image(drawImage, this.position.x - (drawImage.width/2), this.position.y - 175);
  }
 
}
