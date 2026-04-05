# 'Person' - Processing Game Framework v4

## **Overview**
A modular, object-oriented 2D game framework built in Processing. This project provides a solid foundation for creating interactive games with physics, inventory systems, UI elements, character interactions, and full game state persistence with save functionality.

## **Features**

### **Core Systems**
- **Game Manager** - Central manager of things and humans, UI, scenes, and constants
- **Physics Engine** - Gravity, collision detection, velocity, and friction
- **Scene Management** - Multiple scenes with day/night transitions
- **Input System** - Customizable input boxes for text/password entry
- **Inventory & Economy** - Money system, purchasable items, hunger mechanics
- **Character Controller** - Human character with movement, jumping, grabbing
- **Image Manager** - Asynchronous background loading of images with progress tracking
- **Save/Load System** - Full game state persistence with JSON serialization (v4.1.0+)

### **Interactive Things**
- **CashBags** - Password-protected money containers with InputBox integration
- **Lunchboxes** - Edible food items with price and hunger restoration. It is also the base class for any food items.
- **Furniture** - Chairs, cupboards, pantries with storage capabilities
- **Doors** - Scene transition portals
- **Drone** - Flyable drone with battery management
- **Clothing** - Swappable shirts with color customization

### **UI Elements**
- **UIElement System** - Object-oriented UI with z-index layering and animations
- **InputBox** - Reusable text input with password masking
- **MessageBox** - Draggable message queue with auto-fade
- **StatBar** - Progress bars with labels and percentages
- **Custom Cursor** - Blue circular cursor design
- **Loading Screen** - Animated splash screen with progress bar and rotating tips

## **Project Structure (in `/Source`)**

### **Core framework**

#### **Main.pde**
- Entry point with `setup()` and `draw()` functions
- Creates GameManager instance via user-defined `createGameManager()`
- Sets window title and starts the game

#### **KeyHandlers.pde**
- Key input handling and event system
- `KeyManager` class tracks key states

#### **GameManager.pde**
- **`GameManager`** - Central class containing:
  - Global variables and physics constants
  - Collections of all things, humans, and input boxes
  - Main update loop
  - References to ThingManager, UIManager, SceneManager, KeyManager, ImageManager, and SaveManager systems
- **`Other Managers`** - Manages different systems, all controlled by `GameManager`

#### **BaseClasses.pde**
- **`Thing`** - Abstract base class for all game things (implements `Saveable`)
- **`Human`** - Basic human with drawing and movement logic
- **`Interactable`** - Interface for interactive things
- **`KeyEvents`** - Interface for things that respond to keyboard input
- **`Saveable`** - Interface for things that can be saved/loaded
- **`InputBox`** - Text input UI with password support and callbacks

### **Manager Architecture**

The framework uses a clean separation of concerns with dedicated managers:

#### **ThingManager (v4.5.0+)**
Manages all game objects and characters:
- `things` - ArrayList of all game objects (extends Thing)
- `mainHumans` - ArrayList of all player/NPC characters
- `trackedHuman` - Currently followed human for camera/scene tracking
- `updateThings()` - Updates physics, collisions, and rendering order
- `handleKeyPress()/handleKeyRelease()` - Routes keyboard input to game objects

#### **UIManager (v4.5.0+)**
Manages all user interface elements:
- `elements` - ArrayList of all UI components (extends UIElement)
- Automatic z-index sorting for proper layering
- Z-index manipulation methods: `bringToFront()`, `sendToBack()`, `bringForward()`, `sendBackward()`
- Hit testing: `getTopAt(x, y)` returns topmost UI element at position
- Bulk operations: `hideAll()`, `showAll()`, `setEnabledAll()`
- Key event routing with priority (UI gets keys before game objects)

#### **Other Managers**
- **SaveManager** - Handles JSON serialization and game state persistence
- **ImageManager** - Manages asynchronous asset loading and caching
- **KeyManager** - Tracks keyboard state for all input sources
- **LoadingManager** - Manages game loading screen

### **GameManager - The Orchestrator**

```java
class GameManager {
    ThingManager thingManager;  // Game objects
    UIManager uiManager;        // UI components
    SaveManager saveManager;    // Persistence
    ImageManager imageManager;  // Assets
    KeyManager keyManager;      // Input
    SceneManager sceneManager;              // Display & scenes
}
```

### **Examples**

#### **Classes (GameHuman.pde and GameThings.pde)**
- **`GameHuman`** - Game player character with hunger/money systems and background updates
- **`ImageHuman`** - Human that uses an image from ImageManager for appearance
- **`Ball` and `BouncyBall`** - Physics objects with collision and throw mechanics
- **`Shirt`** - Wearable clothing item with color swapping
- **`Chair`** - Sit-able furniture with thing stacking
- **`Door`** - Scene transition thing
- **`Cupboard`/`PreFilledCupboard`** - Storage containers with item management
- **`Drone`** - Controllable flying device with battery and recharging
- **`Lunchbox`** - Consumable food items with price and hunger restoration
- **`CashBag`** - Password-protected money bags with cooldown system

#### **Debug.pde**
- **`Debug`** - Debugging HUD with tracked human info

## **Example Gameplay Mechanics**

### **Character Controls**
- **Arrow Keys/Mouse** - Move left/right
- **Up Arrow/Middle Click** - Jump
- **Down Arrow/Space/Right Click** - Grab/release things
- **SHIFT Key** - Special interactions (eat food, stand on chair, throw balls, etc.)
- **S Key** - Save game (creates `saves/gameSave.json`)

### **Thing Interactions**

1. **Eat Food**: Grab a lunchbox, press SHIFT
2. **Unlock CashBag**: Interact with bag, enter password in InputBox
3. **Change Shirt**: Grab shirt, press SHIFT to swap colors
4. **Fly Drone**: Use WASD keys when drone is selected, press R to recharge
5. **Enter Door**: Grab door to change scenes
6. **Open Pantry**: Interact with PreFilledCupboard to access stored food
7. **Stack Things**: Drop items near chairs to place them
8. **Throw Balls**: Grab a ball and press SHIFT to throw

### **Hunger System**
- Hunger increases over time and with movement
- Eat lunchboxes to reduce hunger (costs money)
- Game over when hunger reaches 100%
- Background updates keep hunger progressing even when character is off-screen

### **Money System**
- Starting money: $200
- Earn money by unlocking CashBags with correct passwords
- Spend money on food to reduce hunger

### **Password Puzzles**
- Three CashBags with different passwords:
  - $50 bag: "1234" (First 4 numbers!)
  - $100 bag: "Hello" (A common English greeting!)
  - $200 bag: "P@55$ec6re" (You shall never guess it.)

## **Technical Highlights**

### **Object-Oriented Design**
- Clean inheritance hierarchy (`Thing` -> specific things)
- Interface-based interactions (`Interactable`, `KeyEvents`, `Saveable`)
- Encapsulated game state management with GameManager
- Composition over inheritance where appropriate

### **Save/Load System (v4.1.0+)**
- **Automatic ID assignment**: Every thing gets a sequential ID based on creation order in `GameInit.pde`
- **Saveable interface**: Things implement `save()` and `load()` methods to serialize their state
- **JSON serialization**: Human-readable save files in the `saves/` folder
- **Reference resolution**: Things store IDs of referenced things (e.g., `grabThingID`, `restedThingID`) for proper relationship restoration
- **Transient state handling**: Temporary variables like grab cooldowns are reset on load
- **Press 'S' to save** - Creates `gameSave.json` in the `saves/` directory
- **Automatic saving** - Optional with configurable auto-save interval
- **Automatic loading** - Game state restores from save file at startup if one exists

### **Input Box System**
- Reusable `InputBox` class with password masking
- Callback-based submission/cancellation using Runnable interfaces
- Global input box management to prevent conflicts
- Visual feedback with blinking cursor and text clipping

### **Physics Implementation**
- Velocity/acceleration-based movement with configurable gravity
- Elastic collisions and friction per thing
- Screen boundary constraints with configurable bounds
- Background updates for persistent things

### **Scene Management**
- Mix of colors and images for backgrounds
- Seamless transitions via doors
- Object visibility based on current scene
- Ground rendering toggle per scene
- **Terrain system**: Ground keyframes with interpolation for hills, stairs, and holes

### **Image Management System**
- Central image storage
- Asynchronous loading in background thread
- Thread-safe progress tracking with volatile variables
- Automatic image conversion to PGraphics
- Centralized resource caching to prevent duplicate loads
- Images are queued during thing creation
- Background loading with real progress tracking
- Automatic placeholder generation for missing images
- Shared image resources across multiple instances

### **Customization**
- Add new scenes by extending color/image array
- Create new thing types by extending `Thing`
- Modify constants and physics properties
- Add more interactive items with `Interactable` interface
- Create your own game mechanics by extending existing classes
- Use ImageManager for efficient asset loading
- **Extend save/load** by overriding `save()` and `load()` in custom things

## **Code Philosophy**

- **Modular**: Each class handles its own logic in separate files
- **Extensible**: Easy to add new features by extending existing classes
- **Reusable**: Components like InputBox, ImageManager, and SaveManager can be used anywhere
- **Clean**: Separation of concerns between files and classes
- **Non-invasive**: Core files never need modification - extend instead!

## **Design Notes**

- **Color Scheme**: Day/night cycles with distinct palettes
- **UI**: Minimalist with contextual information
- **Feedback**: Visual and console feedback for all actions
- **Loading**: Smooth animated loading with real progress from ImageManager
- **Persistence**: Complete game state restoration including thing references

---

## Getting Started and GameInit.pde

- To start building your game with this framework, you only need to edit GameInit.pde and create your own files to contain your classes.

1. Import all files into Processing (download their IDE on [their website](https://processing.org)), either by cloning this repository or downloading the individual files (in `/Source`): `BaseClasses.pde` (base classes), `GameHuman.pde` (Human extensions), `GameThings.pde` (sample thing classes), `GameManager.pde` (core systems), `KeyHandlers.pde` (input), `Main.pde` (main setup/draw), and `GameInit.pde` (your game configuration).
2. You can edit, rename, or remove the example GameInit.pde and GameThings.pde/GameHuman.pde files. (You are recommended to use them as templates.)
3. In your **`GameInit.pde`,** implement the following functions:

### **`GameManager createGameManager()`**

Creates and returns the main GameManager instance. Called at the very start of the program to define the global gameManager instance.

You return a GameManager object here (default is `return new GameManager("myName", "myVersion")`). This is useful if you extend GameManager to create your own custom manager (e.g. NetworkingGameManager).

You can configure the GameManager before returning it:
- Change the program name and version
- Modify physics constants (GRAVITY, MAX_VELOCITY, etc.)
- Adjust gameplay settings (GRAB_RANGE, GROUND_HEIGHT, etc.)
- Enable/disable save system (`gm.useSaveSystem = false`)

You may also put any code that needs to execute at program startup here:
- Initialize libraries (Minim, Network, etc.)
- Load configuration files
- Parse command line arguments
- Setup logging

Returns: GameManager - Any class that extends GameManager

Example:
```java
GameManager createGameManager() {
    GameManager gm = new GameManager("My Game", "2.0");
    gm.startupMessage = "Welcome to my game!";
    return gm;
}
```

### **`Boolean initLoadingScreen(LoadingManager loader)`**

Configures the optional loading/splash screen. Called during GameManager initialization.

To disable the splash screen entirely, just `return false`.

You can customize the loading screen by modifying loader properties:
- loadingMessages: String[] of messages to display during each loading stage
- loadingTips: String[] of tips that rotate during loading
- backgroundColor1/backgroundColor2: Colors for animated background (lerpColor)
- progressBarColor: Color of the progress bar
- framesPerStage: How many frames each loading stage takes

The loading screen automatically integrates with ImageManager to show real progress during image loading.

Parameters:
    loader - LoadingManager instance to configure

Returns: boolean - true to enable loading screen, false to disable

Example:
```java
Boolean initLoadingScreen(LoadingManager loader) {
    String[] tips = {
        "Press DOWN to grab objects",
        "SHIFT interacts with held objects",
        "Find cash bags with hidden passwords!",
        "Press S to save your game"
    };
    loader.loadingTips = tips;
    loader.progressBarColor = color(255, 200, 100);
    return true;
}
```

### **`void createScenes(SceneManager sceneManager)`**

Sets up all game scenes, backgrounds, and ground height properties.

You must define:
- The scenes themselves (colors or images)
- Whether each scene has ground
- The starting scene
- The trash scene (where deleted things go)
- Cursor color

sceneManager.addScenes() takes two parallel arrays:
- First array: Object[] containing colors (Integer) or image paths (String) - both can coexist
- Second array: Boolean[] indicating whether each scene has ground

You can freely mix solid colors and images. For images:
- Store them in the 'data' folder
- Use just the filename (e.g., "beach.png")
- ImageManager automatically loads them in the background

You can also change the ground height across the scene like a terrain. Use `sceneManager.addGroundKeyframe(int scene, float xPosition, float height)`.
- int scene sets which scene to add the keyframe.
- float xPosition sets the x position of the keyframe (vertex).
- float height sets the height of that vertex, in a normalized value between 0 and 1, multipled by the screen height (height).
- If you want to have a uniform ground height, set sceneManager.defaultGroundHeight.

Additional window properties you can set:
- groundColor: Color of the ground
- frameSpeed: Game speed (1.0 = 60fps, 0.5 = 30fps)
- cursorSize: Size of the custom cursor
- scenes.setLoop(true/false): Whether scene indices wrap around
- scenes.setDefaultReturnValue(): Fallback color for invalid scenes

Parameters:
    sceneManager - SceneManager instance to configure

Example:
```java
void createScenes(SceneManager sceneManager) {
    sceneManager.addScenes(
        new Object[]{color(90,210,255), "beach.png", color(18,19,65)},
        new Boolean[]{true, false, true}
    );
    
    sceneManager.addGroundKeyframe(2, 0, 0.8);    // Start at 80%
    sceneManager.addGroundKeyframe(2, 200, 0.8);  // Still 80%, slope starts
    sceneManager.addGroundKeyframe(2, 750, 0.5);  // Top of the hill
    sceneManager.addGroundKeyframe(2, 1000, 0.8); // Back to 80% at end of the hill
    
    sceneManager.scene = 0;
    sceneManager.trashScene = 999;
    sceneManager.cursorColor = color(0, 120, 255);
    sceneManager.scenes.setLoop(true);
}
```

### **`void createHumans(ArrayList<Human> humans)`**

Creates all player characters and NPCs (if you have them) in the game.

You create Human objects and add them to the ArrayList passed in. This ArrayList becomes the mainHumans list in the ThingManager of GameManager that the game updates (live()).

Base Human constructor:
    `Human(String name, color hairColor, color shirtColor, color pantColor, color shoeColor, float posX, int sceneIn)`

Extended humans available (examples):
- GameHuman: Adds hunger/money systems and background updates
- ImageHuman: Uses an image from ImageManager for appearance

To make the game track the scene of the human, use `setTrackedHuman(Human human)`.

Parameters:
    humans - ArrayList to add Human objects to

Example:
```java
void createHumans(ArrayList<Human> humans) {
    GameHuman player = new GameHuman(
        "Isaac", "Tan", "boy", 10,
        color(0), color(0,0,255), color(50), color(0),
        2.5, 200.0, width * 0.68, 0
    );
    humans.add(player);
    setTrackedHuman(player);
    
    ImageHuman npc = new ImageHuman("Joe", "person.png", width * 0.3, 0);
    npc.hasControls = false;
    humans.add(npc);
}
```

### **`void createThings(ArrayList<Thing> things)`**

Creates all interactive things, furniture, items, and physics things.

You create Thing objects and add them to the ArrayList passed in. This becomes the global things list in ThingManager that the game updates, displays, and checks for collisions.

**Important for save/load**: Things receive sequential IDs based on the order they're added here. The first thing gets ID 1, second gets ID 2, etc. This ensures consistent ID assignment across save/load cycles.

Things that use images (BouncyBall, ImageHuman, etc.) automatically queue them with ImageManager when constructed. No additional steps needed.

Parameters:
    things - ArrayList to add Thing objects to

Example:
```java
void createThings(ArrayList<Thing> things) {
    color wood = color(200,100,0);
    
    things.add(new Door(width*0.9, width*0.1, wood, 0, 1));  // ID: 1
    things.add(new Chair(wood, 700, 0));                      // ID: 2
    things.add(new BouncyBall("football.png", 70, 200, 0.85, 0)); // ID: 3
    things.add(new CashBag(color(50,200,50), 400, 0, 50, "1234", "Hint")); // ID: 4
    things.add(new Lunchbox("Pizza", color(255,100,50), 300, 0, 15, 25)); // ID: 5
}
```

### **`void loop()`**

Executes every frame (60 times per second at default speed).

Put any code here that needs to run continuously during the game:
- Custom game logic
- Spawning new things
- Checking win/loss conditions
- Debug output

Example:
```java
void loop() {
    if (frameCount % 300 == 0) {  // Every 5 seconds
        println("Time passes...");
    }
    myThing.customUpdate();
}
```

---

That's the end of your GameInit.pde. But what if you want to extend your game by making your own Things?

## **Creating Custom Thing Classes**

Create your own .pde file and extend existing classes. The framework supports full save/load functionality for custom Things - you just need to override the `save()` and `load()` methods to include your custom properties.

### **Basic Custom Thing Template**

```java
class MyNewThing extends Thing implements Interactable, KeyEvents {
    // Your custom properties
    int myCustomProperty;
    int myDefaultProperty = 0;
    Thing targetThing = null;
    
    // Constructor
    MyNewThing(float posX, int sceneIn, int customProperty) {
        super(); // Call Thing constructor
        this.initialize(posX, height * 0.5); // Initialize with position
        // this.initialize(); // Or initialize with default position
        this.sceneIn = sceneIn;
        this.grabbable = true;
        this.myCustomProperty = customProperty;
        
        // Optional: Configure collision detection
        this.checkTouchRadius = 70; // Enable onTouch() at this distance
        this.checkTouchY = true;     // Use full 2D distance check
        this.checkTouchWide = false; // If true, enables distance checking of any radius, and if false, maximum distance is 200px.
        
        // Optional: Rendering layers
        this.drawInBackground = true;  // Draw behind other Things
        this.drawInForeground = false; // Draw in front
        this.drawBehindHumans = false; // Draw relative to humans
        
        // Optional: Background updates
        this.updateInBackground = true; // Update even when not in scene
    }
    
    // Required display method
    void display() {
        // Your drawing code here
    }
    
    // Optional: Collision detection
    void onTouch(Thing other, float distance) {
    }
    
    // ===== SAVE/LOAD METHODS =====
    // Override these to persist your custom properties
    
    @Override
    HashMap<String, Object> save() {
        // ALWAYS call super.save() first to save base class properties
        // (id, position, velocity, flags, etc.)
        HashMap<String, Object> data = super.save();
        
        // Add your custom properties to the HashMap
        data.put("myCustomProperty", this.myCustomProperty);
        data.put("myDefaultProperty", this.myDefaultProperty);
        
        // Save references to other Things by their ID
        // (instead of saving the entire Thing)
        // if (this.targetThing != null) {
        //     data.put("targetThingID", this.targetThing.id);
        // }
        
        return data;
    }
    
    @Override
    void load(HashMap<String, Object> data) {
        // ALWAYS call super.load() first to restore base class properties
        super.load(data);
        
        // Restore your custom properties
        if (data.containsKey("myCustomProperty")) {
            this.myCustomProperty = ((Number) data.get("myCustomProperty")).intValue();
        }
        if (data.containsKey("myDefaultProperty")) {
            this.myDefaultProperty = (Number) data.get("myDefaultProperty");
        }

        if (data.containsKey("targetThingID")) {
            this.loadThings(gameManager.thingManager.things, (int) data.get("targetThingID"));
        }
    }
    
    void loadThings(ArrayList<Thing> things, int thingId) {
        if (thingId > 0) {
            for (Thing thing : things) {
                if (thing instanceof Saveable && thing.id == thingId) {
                    this.targetThing = thing;
                    break;
                }
            }
        }
    }
    
    // ===== INTERACTABLE INTERFACE METHODS =====
    // (optional - only if you want the thing to be interactive)
    
    @Override
    void onGrab(Human human) {
        // Called when human grabs this Thing
        gameManager.messageBox.showEvent("Thing grabbed!");
    }
    
    @Override
    void onInteract(Human human) {
        // Called when human presses SHIFT while holding this Thing
        gameManager.messageBox.showEvent("Thing interacted with!");
    }
    
    @Override
    boolean isGrabbable() {
        // Can return dynamic state (e.g., not grabbable when empty)
        return this.grabbable && !this.held && ammo > 0;
    }
    
    @Override
    void onRelease(Human human) {
        // Called when human releases the Thing
    }
    
    // ===== KEYEVENTS INTERFACE METHODS =====
    // (optional - only if thing responds to keyboard)
    
    @Override
    void keyDown(char key, int keyCode) {
        if (key == 'F') {
            // Special action when F is pressed
        }
    }
    
    @Override
    void keyUp(char key, int keyCode) {
        // Handle key release
    }
}
```

### **Important Save/Load Principles**

1. **Always call `super.save()` and `super.load()` first** - This ensures base class properties (position, velocity, flags, ID) are properly handled.

2. **Save references as IDs, not Things** - When your Thing references another Thing (like a target or owner), save its ID:
   ```java
   if (targetThing != null) {
       data.put("targetID", targetThing.id);
   }
   ```
   
3. **Transient variables** - Don't save temporary state like timers or cooldowns. Reset them in `load()` if needed:
   ```java
   @Override
   void load(HashMap<String, Object> data) {
       super.load(data);
       // Reset transient state
       this.lastFiredTime = 0;
       this.cooldownActive = false;
   }
   ```

4. **ID assignment is automatic** - Things receive sequential IDs based on creation order in `createThings()`. No manual ID assignment needed!

---
## More on core game systems

### **ImageManager Integration**

The ImageManager handles all image loading automatically:

- **Automatic queuing**: Things queue images in their constructors via `addImage()`
- **Background loading**: `startLoading()` begins the asynchronous load
- **Progress tracking**: `getProgress()` returns 0.0-1.0 for loading screens
- **Automatic placeholders**: Missing images show magenta/cyan checkerboard with "?"
- **Thread-safe**: Volatile variables ensure safe cross-thread communication

Images are loaded once and shared across all instances using the same path.

The ImageManager works automatically in the background:
- Things queue images via addImage() in their constructors
- Images load asynchronously during the loading screen
- getImage() returns the loaded PGraphics or a placeholder if not ready
- Progress is tracked and displayed on the loading screen

You don't need to interact with ImageManager directly unless creating custom image-based Things.
To add an image to ImageManager, the default is to load the image in the constructor of the Thing's class (see the example `BouncyBall` class) by executing `gameManager.imageManager.addImage("Unique_ID_for_Image_Usually_Same_As_Filename", "filename.png", width, height)`, and to get the image in `PGraphics` form by calling `gameManager.imageManager.getImage("Unique_ID_for_Image")`. If you need to load images at game time, they aren't automatically loaded after an `addImage()` call. You have to call `gameManager.imageManager.startLoading()` to load all new images.

**Note: do not call `startLoading()` after every `addImage`! Instead, add all images to the ImageManager queue first, then call `startLoading()` to load all of them at once.**

---

### **Save/Load System (v4.1.0+)**

The framework includes a comprehensive save/load system that persists the entire game state to JSON files.

#### **How It Works**
- **Automatic ID assignment**: Every Thing gets a unique sequential ID based on creation order in `GameInit.pde`
- **Saveable interface**: Things implement `save()` and `load()` methods to serialize their state
- **JSON serialization**: Human-readable save files in the `saves/` folder
- **Transient state handling**: Temporary variables like grab cooldowns are reset on load

#### **Built-in Save/Load**
- Press **'S'** to save the game (creates `gameSave.json` in the `saves/` folder)
- Game can auto-save if you configure the `autoSave` boolean and `autoSaveInterval` int in gameManager.
- Loading happens automatically at startup (if a save file exists)
- All Things and humans restore their exact state including:
  - Positions and velocities
  - Physics properties (elasticity, friction)
  - Game state (hunger, money, unlocked status)
  - Thing references (grabbed Things, chair occupancy)
  - Container contents (cupboard shelves)
  - Scene membership and visibility flags

#### **The Saveable Interface**
```java
interface Saveable {
    HashMap<String, Object> save();
    void load(HashMap<String, Object> data);
}
```

Any class implementing `Saveable` can be persisted. The `Thing` base class already implements this, so all your Things inherit save/load functionality.

#### **ID Assignment**
IDs are assigned sequentially based on creation order:
- First Thing in `createThings()` gets ID 1
- Second Thing gets ID 2, etc.
- Humans in `createHumans()` get IDs after all Things

This ensures consistent ID assignment across save/load cycles without any manual configuration.

---

### **UI System (v4.4.0+)**

The framework includes a comprehensive, object-oriented UI system with automatic layering, animations, and input handling.

#### **Core UI Features**
- **Z-index layering** - UI elements automatically sorted by depth
- **Smooth animations** - Fade in/out with configurable speed
- **Event detection** - Automatic states and callbacks
- **Fluent API** - Chain methods for clean configuration
- **Global management** - All UI elements managed in `gameManager.uiManager`

#### **Built-in UI Components**

##### **InputBox**
Modal text input with password masking and validation:
```java
InputBox input = new InputBox(x, y, width, height, "Title", "Hint");
input.setPasswordMode(true)
     .setMaxLength(20)
     .setColors(bgColor, borderColor, textColor, hintColor);
input.show();
```

##### **MessageBox**
Draggable message queue with auto-fading:
```java
MessageBox msgBox = new MessageBox(x, y, width, height);
msgBox.showEvent("Player picked up an item!");
msgBox.showAlert("Danger! Low health!");
msgBox.showMessage("Quest completed!");
```

##### **StatBar**
Progress bar with label and percentage:
```java
StatBar healthBar = new StatBar("Health", x, y, width, height);
healthBar.setColors(barColor, bgColor, borderColor, labelColor)
         .setShowPercentage(true)
         .setValue(currentHealth, maxHealth);
```

#### **Creating Custom UI Elements**

Extend `UIElement` and implement `display()` and optional callbacks. Don't forget to add your UI element to the UIManager with `gameManager.uiManager.add(UIElement yourUIElement)`!

```java
class MyButton extends UIElement {
    String label;
    color bgColor, textColor;
    
    MyButton(float x, float y, float w, float h, String label) {
        super(x, y, w, h);
        this.label = label;
        this.bgColor = color(100);
        this.textColor = color(255);
        
        // Optional: Add click handler
        this.onClick = () -> {
            println("Button clicked!");
        };
    }
    
    @Override
    void display() {
        fill(hovered ? brightness(bgColor) : bgColor);
        rect(position.x, position.y, boxWidth, boxHeight);
        
        fill(textColor);
        textAlign(CENTER, CENTER);
        text(label, position.x + boxWidth/2, position.y + boxHeight/2);
    }
}
```

## **Examples Provided**

1. **GameInit.pde** - Complete game setup with scenes, characters, and Things
2. **GameThings.pde** - Various thing types demonstrating different features including save/load
3. **GameHuman.pde** - Extended human with hunger/money and background updates

**Need a specific example?**
- Simple physics object: See `Ball` class
- Image-based object: See `BouncyBall` or `ImageHuman`
- Interactive furniture: See `Chair` class
- Scene transition: See `Door` class
- Password input: See `CashBag` class
- Storage system: See `PreFilledCupboard` class
- Background updates: See `GameHuman` or `Door`
- Asynchronous loading: See `ImageManager` and `LoadingManager`
- Save/load implementation: See any class extending `Thing`

