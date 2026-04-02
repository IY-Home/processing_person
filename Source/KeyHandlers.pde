class KeyManager {
    int KEY_COUNT = 256;
    boolean[] keys = new boolean[KEY_COUNT];
    
    void setKeyPressed(int keyCode, boolean pressed) {
        if (keyCode >= 0 && keyCode < KEY_COUNT) {
            keys[keyCode] = pressed;
        }
    }
    
    boolean isKeyPressed(int keyCode) {
        if (keyCode >= 0 && keyCode < KEY_COUNT) {
            return keys[keyCode];
        }
        return false;
    }
    
    void resetAllKeys() {
        Arrays.fill(keys, false);
    }
}


// Handle key presses 
void keyPressed() {
    gameManager.keyManager.setKeyPressed(keyCode, true);
    
    if (gameManager.useSaveSystem && (key == 's' || key == 'S')) { 
      gameManager.saveGame(); 
      gameManager.messageBox.showEvent("Game saved!");
    }
    
    // First, let UI elements handle keys
    boolean handledByUi = false;
    for (int i = gameManager.uiElements.size() - 1; i >= 0; i--) {
        UIElement box = gameManager.uiElements.get(i);
        if (box.enabled && box.visible) {
            ((KeyEvents)box).keyDown(key, keyCode);
            handledByUi = true;
        }
    }
    
    // If not handled by UI elements, process game keys
    if (!handledByUi) {
        // Existing drone controls
        for (Thing thing: gameManager.things) {
            if (thing instanceof KeyEvents) {
                ((KeyEvents) thing).keyDown(key, keyCode);
            }
        }
    }
}
// Handle key releases
void keyReleased() {
    gameManager.keyManager.setKeyPressed(keyCode, false);

    // First, let UI elements handle keys
    boolean handledByUi = false;
    for (int i = gameManager.uiElements.size() - 1; i >= 0; i--) {
        UIElement box = gameManager.uiElements.get(i);
        if (box.enabled && box.visible) {
            ((KeyEvents)box).keyUp(key, keyCode);
            handledByUi = true;
        }
    }
    
    if (!handledByUi) {
        for (Thing thing: gameManager.things) {
            if (thing instanceof KeyEvents) {
                ((KeyEvents) thing).keyUp(key, keyCode);
            }
        }
    }
}
