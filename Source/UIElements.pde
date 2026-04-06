abstract class UIElement {
    PVector position;
    float boxWidth, boxHeight;
    boolean visible = true;
    boolean enabled = true;
    boolean hovered = false;
    boolean mousePressedOnThis = false;

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
    }
    
    UIElement(float x, float y, float w, float h) {
        this.position = new PVector(x, y);
        this.boxWidth = w;
        this.boxHeight = h;
    }

    // Core methods
    abstract void display();
    
    void update() {
        if (!visible) { targetAlpha = 0; alpha = 0; }

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
            if (onClick != null) onClick.run();
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
    
    boolean contains(float x, float y) {
        return x >= position.x && 
               x <= position.x + boxWidth && 
               y >= position.y && 
               y <= position.y + boxHeight;
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

class Label extends UIElement {
    String text;
    color textColor;
    color backgroundColor;
    int textSize;
    int textAlignHorizontal; // LEFT, CENTER, RIGHT
    int textAlignVertical;   // TOP, CENTER, BOTTOM
    boolean hasBorder;
    color borderColor;
    float borderWeight;
    float cornerRadius;
    
    // Constructor with just text (auto positions)
    Label(String text, float x, float y) {
        this(text, x, y, 200, 40);
    }
    
    // Full constructor
    Label(String text, float x, float y, float w, float h) {
        super(x, y, w, h);
        this.text = text;
        this.textColor = color(255);
        this.backgroundColor = color(0, 0, 0, 0); // Transparent default
        this.textSize = 16;
        this.textAlignHorizontal = CENTER;
        this.textAlignVertical = CENTER;
        this.hasBorder = false;
        this.borderColor = color(255);
        this.borderWeight = 1;
        this.cornerRadius = 5;
    }
    
    void display() {
        pushStyle();
        
        // Draw background
        if (alpha(backgroundColor) > 0) {
            fill(backgroundColor);
            noStroke();
            rect(position.x, position.y, boxWidth, boxHeight, cornerRadius);
        }
        
        // Draw border
        if (hasBorder) {
            noFill();
            stroke(borderColor);
            strokeWeight(borderWeight);
            rect(position.x, position.y, boxWidth, boxHeight, cornerRadius);
        }
        
        // Draw text
        fill(textColor);
        textSize(textSize);
        textAlign(textAlignHorizontal, textAlignVertical);
        
        float textX = position.x;
        float textY = position.y;
        
        if (textAlignHorizontal == CENTER) textX += boxWidth / 2;
        else if (textAlignHorizontal == RIGHT) textX += boxWidth;
        
        if (textAlignVertical == CENTER) textY += boxHeight / 2;
        else if (textAlignVertical == BOTTOM) textY += boxHeight;
        
        text(text, textX, textY);
        
        popStyle();
    }
    
    // Fluent setters (chainable)
    Label setText(String newText) {
        this.text = newText;
        return this;
    }
    
    Label setTextColor(color c) {
        this.textColor = c;
        return this;
    }
    
    Label setBackground(color c) {
        this.backgroundColor = c;
        return this;
    }
    
    Label setTextSize(int size) {
        this.textSize = size;
        return this;
    }
    
    Label setAlignment(int horizontal, int vertical) {
        this.textAlignHorizontal = horizontal;
        this.textAlignVertical = vertical;
        return this;
    }
    
    Label setBorder(color c, float weight) {
        this.hasBorder = true;
        this.borderColor = c;
        this.borderWeight = weight;
        return this;
    }
    
    Label setCornerRadius(float r) {
        this.cornerRadius = r;
        return this;
    }
}

class Button extends UIElement {
    String text;
    color normalColor;
    color hoverColor;
    color pressColor;
    color currentColor;
    color textColor;
    int textSize;
    float cornerRadius;
    boolean isPressed;
    
    // Optional icon
    String icon;
    boolean iconOnLeft;
    
    Button(String text, float x, float y, float w, float h) {
        super(x, y, w, h);
        this.text = text;
        this.normalColor = color(70, 130, 200); // Steel blue
        this.hoverColor = color(100, 160, 230);
        this.pressColor = color(50, 100, 150);
        this.currentColor = normalColor;
        this.textColor = color(255);
        this.textSize = 16;
        this.cornerRadius = 8;
        this.isPressed = false;
        this.icon = "";
        this.iconOnLeft = true;
        
        this.onClick = () -> {
            println("Button clicked: " + text);
        };
    }
    
    void update() {
        if (!enabled) return;
        
        // Update hover state
        boolean wasHovered = hovered;
        hovered = isMouseOver();
        
        // Handle click state
        if (hovered && mousePressed && !mousePressedOnThis) {
            mousePressedOnThis = true;
            currentColor = pressColor;
            isPressed = true;
        } else if (mousePressedOnThis && !mousePressed) {
            // Mouse released - trigger click if still hovering
            if (hovered && onClick != null) {
                onClick.run();
            }
            mousePressedOnThis = false;
            isPressed = false;
            currentColor = hovered ? hoverColor : normalColor;
        } else if (hovered && !mousePressed && !isPressed) {
            currentColor = hoverColor;
        } else if (!hovered && !isPressed) {
            currentColor = normalColor;
        }
        
        // Handle hover callback
        if (hovered && !wasHovered && onHover != null) {
            onHover.run();
        }
        
        // Display
        if (visible) {
            display();
        }
    }
    
    void display() {
        pushStyle();
        
        // Draw button background
        fill(currentColor);
        stroke(0);
        strokeWeight(1.5);
        rect(position.x, position.y, boxWidth, boxHeight, cornerRadius);
        
        // Draw inner shadow effect when pressed
        if (isPressed) {
            fill(0, 0, 0, 30);
            noStroke();
            rect(position.x + 2, position.y + 2, boxWidth - 4, boxHeight - 4, cornerRadius - 2);
        }
        
        // Draw text with icon
        fill(textColor);
        textSize(textSize);
        textAlign(CENTER, CENTER);
        
        String displayText = text;
        if (!icon.isEmpty()) {
            if (iconOnLeft) {
                displayText = icon + " " + text;
            } else {
                displayText = text + " " + icon;
            }
        }
        
        float textX = position.x + boxWidth / 2;
        float textY = position.y + boxHeight / 2;
        
        // Slight push when pressed
        if (isPressed) {
            textX += 1;
            textY += 1;
        }
        
        text(displayText, textX, textY);
        
        popStyle();
    }
    
    // Fluent setters
    Button setColors(color normal, color hover, color press) {
        this.normalColor = normal;
        this.hoverColor = hover;
        this.pressColor = press;
        this.currentColor = normal;
        return this;
    }

    Button setText(String newText) {
        this.text = newText;
        return this;
    }

    Button setTextColor(color c) {
        this.textColor = c;
        return this;
    }
    
    Button setTextSize(int size) {
        this.textSize = size;
        return this;
    }
    
    Button setIcon(String iconChar, boolean onLeft) {
        this.icon = iconChar;
        this.iconOnLeft = onLeft;
        return this;
    }
    
    Button setCornerRadius(float r) {
        this.cornerRadius = r;
        return this;
    }
    
    // Manually trigger click (for keyboard shortcuts)
    void click() {
        if (onClick != null) {
            onClick.run();
        }
    }
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
        this.onClick = () -> { fadeAlpha = 255; fading = false; };
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
