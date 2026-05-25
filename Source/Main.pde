GameManager gameManager;

void setup() {
    fullScreen();
    pixelDensity(displayDensity()); 

    GameConfig gameConfig = new GameConfig();

    // Create and initialize game manager 
    gameManager = gameConfig.createGameManager();
    windowTitle(gameManager.programName + " v" + gameManager.version);
    gameManager.init();
}

void draw() {
    gameManager.update();
}
