GameManager gameManager;

void setup() {
    fullScreen();
    pixelDensity(displayDensity()); 

    GameConfig gameConfig = getGameConfig();

    // Create and initialize game manager 
    gameManager = gameConfig.createGameManager();
    windowTitle(gameConfig.programName + " v" + gameConfig.programVersion);
    gameManager.init();
}

void draw() {
    gameManager.update();
}
