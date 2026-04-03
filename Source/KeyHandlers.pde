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


// KeyHandlers.pde
void keyPressed() {
    gameManager.keyManager.setKeyPressed(keyCode, true);
    gameManager.handleKeyPress(key, keyCode);
}

void keyReleased() {
    gameManager.keyManager.setKeyPressed(keyCode, false);
    gameManager.handleKeyRelease(key, keyCode);
}
